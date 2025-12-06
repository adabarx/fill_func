-- detector.lua - Function detection using Tree-sitter
local M = {}

local function get_function_node_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return nil, "Tree-sitter parser not available for this filetype"
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  
  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil, "Could not find node at cursor"
  end

  -- Traverse up the tree to find a function node
  local function_node_types = {
    'function_declaration',
    'function_definition',
    'method_definition',
    'arrow_function',
    'function',
    'method',
    'function_item',
  }

  local current = node
  while current do
    if vim.tbl_contains(function_node_types, current:type()) then
      return current, nil
    end
    current = current:parent()
  end

  return nil, "Cursor is not inside a function"
end

function M.detect_function()
  local func_node, err = get_function_node_at_cursor()
  if not func_node then
    return nil, err
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = func_node:range()
  
  -- Get function text
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  local function_text = table.concat(lines, '\n')
  
  -- Get indent
  local indent = lines[1]:match('^(%s*)')
  
  -- Get context
  local config = require('fill_func.config').get()
  local context_lines = config.context_lines
  
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local context_start = math.max(0, start_row - context_lines)
  local context_end = math.min(total_lines, end_row + 1 + context_lines)
  
  local context_before = ''
  if context_start < start_row then
    local before_lines = vim.api.nvim_buf_get_lines(bufnr, context_start, start_row, false)
    context_before = table.concat(before_lines, '\n')
  end
  
  local context_after = ''
  if context_end > end_row + 1 then
    local after_lines = vim.api.nvim_buf_get_lines(bufnr, end_row + 1, context_end, false)
    context_after = table.concat(after_lines, '\n')
  end
  
  local filetype = vim.bo[bufnr].filetype
  
  return {
    start_line = start_row,
    end_line = end_row,
    indent = indent,
    function_text = function_text,
    context_before = context_before,
    context_after = context_after,
    language = filetype,
    bufnr = bufnr,
  }, nil
end

return M
