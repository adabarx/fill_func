local M = {}

--- Build the prompt sent to opencode
--- @param opts table { write_text, read_context, filepath, prompt }
--- @return string
local function build_prompt(opts)
  local parts = {}

  -- Read context
  table.insert(parts, 'CONTEXT (read-only reference):\n')
  table.insert(parts, opts.read_context)
  table.insert(parts, '\n')

  -- Write area
  table.insert(parts, string.format(
    'CODE TO MODIFY (from %s, lines %d-%d):\n',
    opts.filepath, opts.write_start, opts.write_end
  ))
  table.insert(parts, opts.write_text)
  table.insert(parts, '\n')

  -- Instruction
  table.insert(parts, 'INSTRUCTION:\n')
  table.insert(parts, opts.prompt)
  table.insert(parts, '\n')

  -- Output format
  table.insert(parts,
    'Return ONLY the replacement code for the "CODE TO MODIFY" section. '
    .. 'No explanations, no markdown fences, no extra text. '
    .. 'Just the raw code that should replace the marked section.'
  )

  return table.concat(parts, '\n')
end

--- Call opencode to generate code
--- @param opts table { write_text, write_start, write_end, read_context, filepath, prompt }
--- @param callback fun(result: string|nil, err: string|nil)
function M.generate(opts, callback)
  local cfg = require('fill_func.config').get()
  local cmd = cfg.opencode_path or 'opencode'

  if vim.fn.executable(cmd) ~= 1 then
    callback(nil, 'opencode not found in PATH')
    return
  end

  local prompt_text = build_prompt(opts)

  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart({ cmd, 'run', '--format', 'text', prompt_text }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_chunks, line)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(stderr_chunks, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          local err_msg = table.concat(stderr_chunks, '\n')
          if err_msg == '' then
            err_msg = 'opencode exited with code ' .. exit_code
          end
          callback(nil, err_msg)
          return
        end

        local text = table.concat(stdout_chunks, '\n')
        if not text or vim.trim(text) == '' then
          callback(nil, 'no output from opencode')
          return
        end

        callback(text, nil)
      end)
    end,
  })
end

return M
