-- opencode.lua - OpenCode CLI integration
local M = {}

function M.generate(func_info, instruction, callback)
  local config = require('fill_func.config').get()
  local opencode_cmd = config.opencode_path or 'opencode'

  -- Check if opencode is available
  if vim.fn.executable(opencode_cmd) ~= 1 then
    callback(nil, "opencode not found in PATH. Install it from https://opencode.ai or set config.opencode_path")
    return
  end

  -- Build the prompt with function context and instruction
  local prompt_text = string.format(
    "I have the following %s function:\n\n```%s\n%s\n```\n\n"
    .. "Instruction: %s\n\n"
    .. "Return ONLY the complete rewritten function with no explanation, no markdown fences, and no extra text. "
    .. "Just the raw function code.",
    func_info.language,
    func_info.language,
    func_info.function_text,
    instruction
  )

  -- Shell out to opencode run asynchronously
  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart({
    opencode_cmd, 'run',
    '--format', 'text',
    prompt_text,
  }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(stdout_chunks, line)
          end
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
          callback(nil, "OpenCode request failed: " .. err_msg)
          return
        end

        local text = table.concat(stdout_chunks, '\n')

        if not text or text == '' then
          callback(nil, "No output returned from OpenCode. Check your configuration with `opencode auth list`")
          return
        end

        -- Strip markdown code fences if the model included them despite instructions
        text = text:gsub('^%s*```[%w]*%s*\n', ''):gsub('\n%s*```%s*$', '')

        -- Debug: log what opencode returns
        vim.fn.writefile(vim.split(text, '\n'), '/tmp/opencode_response.txt')

        callback(text, nil)
      end)
    end,
  })
end

return M
