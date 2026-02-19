local M = {}

local defaults = {
  opencode_path = 'opencode',
  timeout = 30000,
}

local config = vim.deepcopy(defaults)

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', defaults, user_config or {})
end

function M.get()
  return config
end

return M
