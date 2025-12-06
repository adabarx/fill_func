# Quick Start Guide

## Installation (5 minutes)

### 1. Install with your plugin manager

**lazy.nvim:**
```lua
{
  'adabarx/fill_func',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('fill_func').setup()
  end,
}
```

**vim-plug:**
```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'adabarx/fill_func'
```
Then add to your config:
```lua
lua require('fill_func').setup()
```

**Built-in package manager:**
```bash
git clone https://github.com/adabarx/fill_func.git \
  ~/.local/share/nvim/site/pack/plugins/start/fill_func
```
Then add to your config:
```lua
require('fill_func').setup()
```

### 2. Ensure Tree-sitter parsers are installed

```vim
:TSInstall lua python javascript typescript
```

### 3. Verify GitHub Copilot is active

```vim
:LspInfo
```

You should see `copilot` in the list of active clients.

## First Use (2 minutes)

### Try Auto-Fill Mode

1. Open a new file: `nvim test.lua`

2. Type this stub:
```lua
function hello(name)
  -- greet the user by name
end
```

3. Move cursor inside the function

4. Press `<leader>cf`

5. Watch Copilot fill in your function! 🎉

### Try Interactive Mode

1. With cursor still in the function, press `<leader>cp`

2. Type: `add error handling for nil name`

3. Press Enter

4. Copilot modifies your function!

## Common Use Cases

### Creating a complex function
```lua
function process_payment(amount, card_number)
  -- validate card, charge amount, return success/failure with message
end
```
Press `<leader>cf` → Full implementation generated!

### Refactoring existing code
Put cursor in any function, press `<leader>cp`, type:
- "add type checking"
- "make it async" 
- "optimize for performance"
- "add detailed comments"

### Language-specific examples

**Python:**
```python
def binary_search(arr, target):
    # implement binary search with proper bounds checking
    pass
```

**JavaScript:**
```javascript
function throttle(func, limit) {
  // create a throttled version that limits execution rate
}
```

## Troubleshooting

**Nothing happens when I press the hotkey:**
- Check `:LspInfo` - Is Copilot running?
- Check `:checkhealth fill_func` (coming soon!)

**"No comment found":**
- Add a comment to your function stub, or
- Use interactive mode with `<leader>cp`

**Wrong language detected:**
- Ensure filetype is set: `:set filetype=python`
- Install Tree-sitter parser: `:TSInstall python`

## Next Steps

- Read the full [README.md](README.md)
- Check [examples/](examples/) for more samples
- Customize keybindings in your config
- Read `:help fill_func` for complete documentation

Happy coding! 🚀
