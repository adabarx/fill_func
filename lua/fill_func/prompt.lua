-- prompt.lua - Extract comment prompts and handle user input
local M = {}

local function get_language_patterns(language)
  local languages = require('fill_func.languages')
  return languages.get_patterns(language)
end

function M.extract_comment(function_text, language)
  local patterns = get_language_patterns(language)
  if not patterns then
    return nil
  end

  local lines = vim.split(function_text, '\n')
  local comments = {}
  
  for _, line in ipairs(lines) do
    local trimmed = line:match('^%s*(.-)%s*$')
    if patterns.single_line then
      local comment = trimmed:match(patterns.single_line)
      if comment then
        table.insert(comments, comment:match('^%s*(.-)%s*$'))
      end
    end
  end
  
  if #comments > 0 then
    return table.concat(comments, ' ')
  end
  
  return nil
end

function M.get_user_prompt(callback)
  vim.ui.input({
    prompt = 'Copilot Instruction: ',
    default = '',
  }, function(input)
    if input and input ~= '' then
      callback(input)
    else
      callback(nil)
    end
  end)
end

return M
