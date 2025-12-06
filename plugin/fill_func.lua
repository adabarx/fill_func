-- fill_func.lua - Plugin initialization
if vim.g.loaded_fill_func then
  return
end
vim.g.loaded_fill_func = 1

local fill_func = require('fill_func')

vim.api.nvim_create_user_command('FillFuncAuto', function()
  fill_func.auto_fill()
end, { desc = 'Fill function with Copilot using comment as prompt' })

vim.api.nvim_create_user_command('FillFuncPrompt', function()
  fill_func.interactive_fill()
end, { desc = 'Fill/edit function with Copilot using custom prompt' })

local config = require('fill_func.config')
local opts = config.get()

vim.keymap.set('n', opts.keymaps.auto_fill, '<cmd>FillFuncAuto<cr>', { desc = 'Copilot: Fill function' })
vim.keymap.set('n', opts.keymaps.interactive, '<cmd>FillFuncPrompt<cr>', { desc = 'Copilot: Prompt function' })
