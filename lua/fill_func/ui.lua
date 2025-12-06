-- ui.lua - UI feedback and progress indicators
local M = {}

local ns_id = vim.api.nvim_create_namespace('fill_func')
local current_extmark = nil

function M.show_progress(bufnr, line)
  local config = require('fill_func.config').get()
  
  if not config.show_progress then
    return
  end
  
  if config.progress_style == 'virtual_text' then
    current_extmark = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
      virt_text = { { '  Generating with Copilot...', 'Comment' } },
      virt_text_pos = 'eol',
    })
  elseif config.progress_style == 'floating' then
    local width = 30
    local height = 1
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local col = 0
    
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { ' Generating with Copilot...' })
    
    local opts = {
      relative = 'win',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
    }
    
    local win = vim.api.nvim_open_win(buf, false, opts)
    current_extmark = { type = 'float', win = win, buf = buf }
  end
end

function M.hide_progress()
  if not current_extmark then
    return
  end
  
  if type(current_extmark) == 'table' and current_extmark.type == 'float' then
    if vim.api.nvim_win_is_valid(current_extmark.win) then
      vim.api.nvim_win_close(current_extmark.win, true)
    end
    if vim.api.nvim_buf_is_valid(current_extmark.buf) then
      vim.api.nvim_buf_delete(current_extmark.buf, { force = true })
    end
  else
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  end
  
  current_extmark = nil
end

function M.show_error(message)
  vim.notify('Fill Func: ' .. message, vim.log.levels.ERROR)
end

function M.show_success(message)
  vim.notify('Fill Func: ' .. (message or 'Function filled successfully!'), vim.log.levels.INFO)
end

return M
