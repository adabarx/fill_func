-- init.lua - Main entry point
local M = {}

local detector = require('fill_func.detector')
local prompt = require('fill_func.prompt')
local copilot = require('fill_func.copilot')
local ui = require('fill_func.ui')
local config = require('fill_func.config')

function M.setup(user_config)
  config.setup(user_config)
end

local function replace_function(func_info, new_code)
  local bufnr = func_info.bufnr
  local start_line = func_info.start_line
  local end_line = func_info.end_line
  
  -- Get the original function lines
  local original_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  
  -- Find where the function body starts (after opening brace)
  local body_start = nil
  for i, line in ipairs(original_lines) do
    if line:match('{') then
      body_start = start_line + i
      break
    end
  end
  
  -- Find where the function body ends (before closing brace)
  local body_end = nil
  for i = #original_lines, 1, -1 do
    if original_lines[i]:match('}') then
      body_end = start_line + i - 2  -- -1 for 0-index, -1 to be before the brace
      break
    end
  end
  
  if not body_start or not body_end then
    -- Fallback: replace entire function if we can't find braces
    local lines = vim.split(new_code, '\n')
    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, lines)
    return
  end
  
  -- Extract body from completion (skip signature line and closing brace)
  local completion_lines = vim.split(new_code, '\n')
  local body_lines = {}
  local in_body = false
  
  for i, line in ipairs(completion_lines) do
    if line:match('{') then
      in_body = true
      -- Check if there's content after the opening brace on same line
      local after_brace = line:match('{%s*(.+)')
      if after_brace and after_brace ~= '' then
        table.insert(body_lines, '    ' .. after_brace)
      end
    elseif line:match('^%s*}%s*$') then
      break
    elseif in_body then
      table.insert(body_lines, line)
    end
  end
  
  -- If we couldn't extract body, try to use everything except first and last line
  if #body_lines == 0 then
    for i = 2, #completion_lines - 1 do
      table.insert(body_lines, completion_lines[i])
    end
  end
  
  -- Clean up empty lines
  while #body_lines > 0 and body_lines[1]:match('^%s*$') do
    table.remove(body_lines, 1)
  end
  while #body_lines > 0 and body_lines[#body_lines]:match('^%s*$') do
    table.remove(body_lines, #body_lines)
  end
  
  -- Replace only the function body
  vim.api.nvim_buf_set_lines(bufnr, body_start, body_end + 1, false, body_lines)
end

function M.auto_fill()
  local func_info, err = detector.detect_function()
  if not func_info then
    ui.show_error(err)
    return
  end
  
  -- Try to extract comment first, fall back to using signature + body
  local instruction = prompt.extract_comment(func_info.function_text, func_info.language)
  if not instruction then
    -- No comment found, use the function signature and body as context
    instruction = prompt.build_instruction_from_signature(func_info.function_text)
  end
  
  ui.show_progress(func_info.bufnr, func_info.start_line)
  
  copilot.generate(func_info, instruction, function(result, error)
    ui.hide_progress()
    
    if error then
      ui.show_error(error)
      return
    end
    
    replace_function(func_info, result)
    ui.show_success()
  end)
end

function M.interactive_fill()
  local func_info, err = detector.detect_function()
  if not func_info then
    ui.show_error(err)
    return
  end
  
  prompt.get_user_prompt(function(instruction)
    if not instruction then
      return
    end
    
    ui.show_progress(func_info.bufnr, func_info.start_line)
    
    copilot.generate(func_info, instruction, function(result, error)
      ui.hide_progress()
      
      if error then
        ui.show_error(error)
        return
      end
      
      replace_function(func_info, result)
      ui.show_success()
    end)
  end)
end

return M
