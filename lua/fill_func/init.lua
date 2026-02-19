local M = {}

local config = require('fill_func.config')
local context = require('fill_func.context')
local opencode = require('fill_func.opencode')
local ui = require('fill_func.ui')

function M.setup(user_config)
  config.setup(user_config)
end

--- Main entry point called by :Ff command
--- @param opts table { line1, line2, range, args }
function M.run(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Determine write area (the lines the agent is allowed to modify)
  local write_start, write_end
  if opts.range == 0 then
    -- No range given: default to current line
    local cursor = vim.api.nvim_win_get_cursor(0)
    write_start = cursor[1]
    write_end = cursor[1]
  else
    write_start = opts.line1
    write_end = opts.line2
  end

  local write_lines = vim.api.nvim_buf_get_lines(bufnr, write_start - 1, write_end, false)
  local write_text = table.concat(write_lines, '\n')

  -- Resolve read context from arguments
  local read_targets = opts.args or {}
  local read_context = context.resolve(bufnr, filepath, write_start, write_end, read_targets)

  -- Open prompt UI
  ui.open_prompt(function(prompt_text)
    if not prompt_text or prompt_text == '' then
      return
    end

    ui.show_progress(bufnr, write_start - 1)

    opencode.generate({
      write_text = write_text,
      write_start = write_start,
      write_end = write_end,
      read_context = read_context,
      filepath = filepath,
      prompt = prompt_text,
    }, function(result, err)
      ui.hide_progress()

      if err then
        vim.notify('ff: ' .. err, vim.log.levels.ERROR)
        return
      end

      -- Replace write area with result
      local new_lines = vim.split(result, '\n')

      -- Strip markdown fences if present
      if #new_lines > 0 and new_lines[1]:match('^```') then
        table.remove(new_lines, 1)
      end
      if #new_lines > 0 and new_lines[#new_lines]:match('^```%s*$') then
        table.remove(new_lines, #new_lines)
      end

      vim.api.nvim_buf_set_lines(bufnr, write_start - 1, write_end, false, new_lines)
      vim.notify('ff: done', vim.log.levels.INFO)
    end)
  end)
end

return M
