-- copilot.lua - Copilot API integration
local M = {}

local function find_copilot_client()
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients) do
    if client.name == 'copilot' then
      return client
    end
  end
  return nil
end

local function build_prompt(func_info, instruction)
  local parts = {}
  
  if func_info.context_before and func_info.context_before ~= '' then
    table.insert(parts, '// Context before:')
    table.insert(parts, func_info.context_before)
    table.insert(parts, '')
  end
  
  table.insert(parts, '// Function to modify/complete:')
  table.insert(parts, func_info.function_text)
  
  if func_info.context_after and func_info.context_after ~= '' then
    table.insert(parts, '')
    table.insert(parts, '// Context after:')
    table.insert(parts, func_info.context_after)
  end
  
  table.insert(parts, '')
  table.insert(parts, '// Instruction: ' .. instruction)
  table.insert(parts, '// Please provide ONLY the complete function implementation, no explanation.')
  
  return table.concat(parts, '\n')
end

function M.generate(func_info, instruction, callback)
  local client = find_copilot_client()
  
  if not client then
    callback(nil, "GitHub Copilot LSP client not found. Please ensure Copilot is installed and running.")
    return
  end

  local prompt_text = build_prompt(func_info, instruction)
  
  local params = {
    doc = {
      source = prompt_text,
      tabSize = vim.bo.tabstop,
      indentSize = vim.bo.shiftwidth,
      insertSpaces = vim.bo.expandtab,
      path = vim.api.nvim_buf_get_name(func_info.bufnr),
      uri = vim.uri_from_bufnr(func_info.bufnr),
      relativePath = vim.fn.expand('%:t'),
      languageId = func_info.language,
      position = { line = func_info.start_line, character = 0 },
    }
  }

  client.request('getCompletionsCycling', params, function(err, result)
    vim.schedule(function()
      if err then
        callback(nil, "Copilot request failed: " .. vim.inspect(err))
        return
      end
      
      if not result or not result.completions or #result.completions == 0 then
        callback(nil, "No completions returned from Copilot")
        return
      end
      
      local completion = result.completions[1].text or result.completions[1].displayText
      if not completion then
        callback(nil, "Invalid completion format")
        return
      end
      
      callback(completion, nil)
    end)
  end, func_info.bufnr)
end

return M
