-- languages/init.lua - Language registry
local M = {}

local language_modules = {
  lua = 'fill_func.languages.lua',
  python = 'fill_func.languages.python',
  javascript = 'fill_func.languages.javascript',
  typescript = 'fill_func.languages.javascript', -- same as JS
  javascriptreact = 'fill_func.languages.javascript',
  typescriptreact = 'fill_func.languages.javascript',
  go = 'fill_func.languages.go',
  rust = 'fill_func.languages.rust',
  c = 'fill_func.languages.c',
  cpp = 'fill_func.languages.c', -- same as C
}

function M.get_patterns(language)
  local module_name = language_modules[language]
  if not module_name then
    -- Default C-style comments
    return {
      single_line = '^//(.*)$',
    }
  end
  
  local ok, module = pcall(require, module_name)
  if not ok then
    return nil
  end
  
  return module.comment_patterns
end

return M
