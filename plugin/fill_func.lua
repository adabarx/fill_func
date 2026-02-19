if vim.g.loaded_fill_func then
  return
end
vim.g.loaded_fill_func = 1

local ff = require('fill_func')

-- :ff command with range support
-- Usage:
--   :%ff           whole file write, read = write area
--   :'<,'>ff       selection write, read = write area
--   :'<,'>ff %     selection write, read = current file
--   :'<,'>ff .     selection write, read = files in cwd
--   :'<,'>ff ..    selection write, read = files in parent dir
--   :'<,'>ff **    selection write, read = recursive from cwd
--   :'<,'>ff path  selection write, read = specific file or dir
--   :'<,'>ff % src/utils.lua   multiple read targets (space-separated)
vim.api.nvim_create_user_command('Ff', function(opts)
  ff.run({
    line1 = opts.line1,
    line2 = opts.line2,
    range = opts.range,
    args = opts.fargs,
  })
end, {
  range = true,
  nargs = '*',
  desc = 'Fill function: AI-assisted code modification with scoped read/write areas',
})

-- Allow :ff (lowercase) to work. Neovim requires user commands to start
-- with a capital letter, so we abbreviate ff -> Ff in command mode.
-- Only triggers when ff ends the current cmdline (i.e. it's at command position).
vim.cmd([[cnoreabbrev <expr> ff getcmdtype() == ':' && getcmdline() =~# '^\(.*,\)\?ff$' ? 'Ff' : 'ff']])
