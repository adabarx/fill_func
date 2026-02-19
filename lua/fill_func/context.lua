local M = {}

--- Gather file contents from a directory (non-recursive)
--- @param dir string
--- @return string[]
local function read_dir_files(dir)
  local entries = {}
  local handle = vim.loop.fs_scandir(dir)
  if not handle then
    return entries
  end
  while true do
    local name, typ = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if typ == 'file' then
      local path = dir .. '/' .. name
      table.insert(entries, path)
    end
  end
  return entries
end

--- Gather file paths recursively
--- @param dir string
--- @return string[]
local function read_dir_recursive(dir)
  local entries = {}
  local handle = vim.loop.fs_scandir(dir)
  if not handle then
    return entries
  end
  while true do
    local name, typ = vim.loop.fs_scandir_next(handle)
    if not name then break end
    local path = dir .. '/' .. name
    if typ == 'file' then
      table.insert(entries, path)
    elseif typ == 'directory' and name ~= '.git' and name ~= 'node_modules' then
      local sub = read_dir_recursive(path)
      for _, p in ipairs(sub) do
        table.insert(entries, p)
      end
    end
  end
  return entries
end

--- Read a file and return its contents as a string, or nil on failure
--- @param path string
--- @return string|nil
local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local content = f:read('*a')
  f:close()
  return content
end

--- Format a context block for a file
--- @param path string
--- @param content string
--- @param label string|nil optional label override
--- @return string
local function format_context(path, content, label)
  label = label or path
  return string.format('--- %s ---\n%s', label, content)
end

--- Resolve read context based on targets
--- @param bufnr number current buffer
--- @param filepath string current file path
--- @param write_start number 1-indexed start line of write area
--- @param write_end number 1-indexed end line of write area
--- @param targets string[] read area arguments from command
--- @return string the assembled read context
function M.resolve(bufnr, filepath, write_start, write_end, targets)
  local blocks = {}
  local cwd = vim.fn.getcwd()

  -- No arguments: read area = write area
  if #targets == 0 then
    local lines = vim.api.nvim_buf_get_lines(bufnr, write_start - 1, write_end, false)
    return table.concat(lines, '\n')
  end

  for _, target in ipairs(targets) do
    if target == '%' then
      -- Current file
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      table.insert(blocks, format_context(filepath, table.concat(lines, '\n')))

    elseif target == '#' then
      -- Alternate file (vim's # register)
      local alt = vim.fn.expand('#:p')
      if alt and alt ~= '' then
        local content = read_file(alt)
        if content then
          table.insert(blocks, format_context(alt, content))
        end
      end

    elseif target == '.' then
      -- All files in cwd (non-recursive)
      local files = read_dir_files(cwd)
      for _, path in ipairs(files) do
        local content = read_file(path)
        if content then
          table.insert(blocks, format_context(path, content))
        end
      end

    elseif target == '..' then
      -- All files in parent dir (non-recursive)
      local parent = vim.fn.fnamemodify(cwd, ':h')
      local files = read_dir_files(parent)
      for _, path in ipairs(files) do
        local content = read_file(path)
        if content then
          table.insert(blocks, format_context(path, content))
        end
      end

    elseif target == '**' then
      -- Recursive from cwd
      local files = read_dir_recursive(cwd)
      for _, path in ipairs(files) do
        local content = read_file(path)
        if content then
          table.insert(blocks, format_context(path, content))
        end
      end

    else
      -- Treat as a path (file or directory)
      -- Resolve relative to cwd
      local resolved = target
      if not vim.startswith(target, '/') then
        resolved = cwd .. '/' .. target
      end
      resolved = vim.fn.fnamemodify(resolved, ':p')

      local stat = vim.loop.fs_stat(resolved)
      if stat then
        if stat.type == 'file' then
          local content = read_file(resolved)
          if content then
            table.insert(blocks, format_context(resolved, content))
          end
        elseif stat.type == 'directory' then
          -- trailing / convention or directory path: read files in it
          local files = read_dir_files(resolved)
          for _, path in ipairs(files) do
            local content = read_file(path)
            if content then
              table.insert(blocks, format_context(path, content))
            end
          end
        end
      else
        -- Try as a glob pattern
        local matches = vim.fn.glob(resolved, false, true)
        for _, path in ipairs(matches) do
          local content = read_file(path)
          if content then
            table.insert(blocks, format_context(path, content))
          end
        end
      end
    end
  end

  if #blocks == 0 then
    -- Fallback: read area = write area
    local lines = vim.api.nvim_buf_get_lines(bufnr, write_start - 1, write_end, false)
    return table.concat(lines, '\n')
  end

  return table.concat(blocks, '\n\n')
end

return M
