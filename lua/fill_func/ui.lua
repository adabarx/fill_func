local M = {}

local ns_id = vim.api.nvim_create_namespace('fill_func')
local progress_extmark = nil

--- Open a floating prompt window for user input.
--- The user types their instruction, then presses Enter (in normal mode)
--- or <C-CR> to submit / Esc to cancel.
--- @param callback fun(text: string|nil)
function M.open_prompt(callback)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'ffprompt'

  local width = math.floor(vim.o.columns * 0.6)
  local height = 5
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' ff prompt ',
    title_pos = 'center',
  })

  -- Start in insert mode
  vim.cmd('startinsert')

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = vim.trim(table.concat(lines, '\n'))
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
    if text == '' then
      callback(nil)
    else
      callback(text)
    end
  end

  local function cancel()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
    callback(nil)
  end

  local kopts = { buffer = buf, noremap = true, silent = true }

  -- Submit: <CR> in normal mode, <C-CR> in insert mode
  vim.keymap.set('n', '<CR>', submit, kopts)
  vim.keymap.set('i', '<C-CR>', submit, kopts)

  -- Cancel: Esc in normal mode, <C-c> in insert mode
  vim.keymap.set('n', '<Esc>', cancel, kopts)
  vim.keymap.set('n', 'q', cancel, kopts)
end

--- Show a progress indicator as virtual text
--- @param bufnr number
--- @param line number 0-indexed line
function M.show_progress(bufnr, line)
  progress_extmark = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
    virt_text = { { '  generating...', 'Comment' } },
    virt_text_pos = 'eol',
  })
end

--- Remove the progress indicator
function M.hide_progress()
  if progress_extmark then
    pcall(vim.api.nvim_buf_clear_namespace, 0, ns_id, 0, -1)
    progress_extmark = nil
  end
end

return M
