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
  
  -- Clean up the new code (remove extra whitespace, ensure proper formatting)
  local lines = vim.split(new_code, '\n')
  
  -- Remove empty lines at start and end
  while #lines > 0 and lines[1]:match('^%s*$') do
    table.remove(lines, 1)
  end
  while #lines > 0 and lines[#lines]:match('^%s*$') do
    table.remove(lines, #lines)
  end
  
  -- Apply the original indent
  local indent = func_info.indent
  for i, line in ipairs(lines) do
    if i > 1 and not line:match('^%s*$') then
      -- Preserve relative indentation
      lines[i] = indent .. line
    end
  end
  
  -- Replace the function
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, lines)
end

function M.auto_fill()
  local func_info, err = detector.detect_function()
  if not func_info then
    ui.show_error(err)
    return
  end
  
  local instruction = prompt.extract_comment(func_info.function_text, func_info.language)
  if not instruction then
    ui.show_error("No comment found in function. Use <leader>cp for interactive mode.")
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
