-- config.lua - Configuration management
local M = {}

local defaults = {
  keymaps = {
    auto_fill = '<leader>cf',
    interactive = '<leader>cp',
    cancel = '<Esc>',
  },
  timeout = 30000, -- 30 seconds
  context_lines = 5, -- lines before/after function for context
  show_progress = true,
  progress_style = 'virtual_text', -- 'virtual_text' or 'floating'
}

local config = vim.deepcopy(defaults)

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', defaults, user_config or {})
end

function M.get()
  return config
end

return M
