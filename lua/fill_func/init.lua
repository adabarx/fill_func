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
  
  -- Use Tree-sitter to parse the completion and extract the function body
  local completion_lines = vim.split(new_code, '\n')
  
  -- Create a temporary buffer to parse the completion
  local temp_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, completion_lines)
  vim.bo[temp_buf].filetype = func_info.language
  
  -- Wait for treesitter to parse
  vim.wait(100)
  
  local parser = vim.treesitter.get_parser(temp_buf)
  if not parser then
    -- Fallback if no parser
    vim.api.nvim_buf_delete(temp_buf, { force = true })
    vim.api.nvim_buf_set_lines(bufnr, body_start, body_end + 1, false, completion_lines)
    return
  end
  
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- Find the function node (should be the root or near it)
  local function_node = nil
  for node in root:iter_children() do
    local node_type = node:type()
    if node_type:match('function') or node_type:match('method') then
      function_node = node
      break
    end
  end
  
  if not function_node then
    function_node = root:child(0)
  end
  
  -- Find the block/body node inside the function
  local body_node = nil
  for child in function_node:iter_children() do
    local child_type = child:type()
    if child_type == 'block' or child_type == 'body' or child_type:match('body') then
      body_node = child
      break
    end
  end
  
  local body_lines = {}
  if body_node then
    -- Extract lines from the body node (excluding the braces)
    local body_start_row, _, body_end_row, _ = body_node:range()
    for i = body_start_row, body_end_row do
      local line = completion_lines[i + 1]  -- +1 for 1-indexed
      if line then
        -- Skip lines that are just opening or closing braces
        if not line:match('^%s*{%s*$') and not line:match('^%s*}%s*$') then
          table.insert(body_lines, line)
        end
      end
    end
  else
    -- Fallback: just use all lines except first and last
    for i = 2, #completion_lines - 1 do
      table.insert(body_lines, completion_lines[i])
    end
  end
  
  -- Clean up temp buffer
  vim.api.nvim_buf_delete(temp_buf, { force = true })
  
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
