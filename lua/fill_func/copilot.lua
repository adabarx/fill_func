-- copilot.lua - Copilot API integration
local M = {}

function M.generate(func_info, instruction, callback)
  -- Check if copilot.lua is available
  local has_copilot, copilot_api = pcall(require, 'copilot.api')
  if not has_copilot then
    callback(nil, "copilot.lua not found. Please install zbirenbaum/copilot.lua")
    return
  end

  local has_client, copilot_client = pcall(require, 'copilot.client')
  if not has_client then
    callback(nil, "copilot.client not found")
    return
  end

  -- Get the copilot client
  local client = copilot_client.get()
  if not client then
    callback(nil, "Copilot client not running. Try :Copilot auth or :Copilot restart")
    return
  end

  -- Add instruction as a comment at cursor position
  local bufnr = func_info.bufnr
  local cursor_line = func_info.start_line + 1  -- Inside the function
  
  -- Temporarily insert the instruction as a comment
  local original_line = vim.api.nvim_buf_get_lines(bufnr, cursor_line, cursor_line + 1, false)[1] or ''
  local comment_line = '  // ' .. instruction
  vim.api.nvim_buf_set_lines(bufnr, cursor_line, cursor_line, false, { comment_line })
  
  -- Build params for copilot
  local copilot_util = require('copilot.util')
  local params = copilot_util.get_doc_params()
  
  -- Request completions
  copilot_api.get_completions(client, params, function(err, data)
    -- Remove the temporary comment line
    vim.schedule(function()
      pcall(vim.api.nvim_buf_set_lines, bufnr, cursor_line, cursor_line + 1, false, {})
    end)
    
    vim.schedule(function()
      if err then
        callback(nil, "Copilot request failed: " .. vim.inspect(err))
        return
      end
      
      if not data or not data.completions or #data.completions == 0 then
        callback(nil, "No completions returned from Copilot. Try being more specific or check :Copilot status")
        return
      end
      
      local completion = data.completions[1]
      local text = completion.text or completion.displayText
      
      if not text or text == '' then
        callback(nil, "Empty completion returned")
        return
      end
      
      callback(text, nil)
    end)
  end)
end

return M
