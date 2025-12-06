-- languages/javascript.lua - JavaScript/TypeScript comment patterns
local M = {}

M.comment_patterns = {
  single_line = '^//(.*)$',
  multi_line_start = '^/%*',
  multi_line_end = '%*/$',
}

return M
