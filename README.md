# Fill Func - Neovim Plugin

A Neovim plugin that intelligently fills function stubs using GitHub Copilot. Works with any language supported by Tree-sitter!

## Features

- **Auto-Fill Mode** (`<leader>cf`): Extracts comments from function stubs and uses them as prompts for Copilot
- **Interactive Mode** (`<leader>cp`): Prompts you for instructions to generate or modify any function
- **Multi-Language Support**: Works with Lua, Python, JavaScript, TypeScript, Go, Rust, C, C++, and more
- **Tree-sitter Integration**: Accurately detects functions in any language with Tree-sitter support
- **Async Operation**: Non-blocking UI while Copilot generates code
- **Context-Aware**: Sends surrounding code context to Copilot for better results

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'adabarx/fill_func',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('fill_func').setup({
      -- Optional: customize configuration
      keymaps = {
        auto_fill = '<leader>cf',
        interactive = '<leader>cp',
      },
      timeout = 30000,
      context_lines = 5,
      show_progress = true,
      progress_style = 'virtual_text', -- or 'floating'
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'adabarx/fill_func',
  requires = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('fill_func').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'adabarx/fill_func'
```

Then in your `init.vim` or `init.lua`:

```lua
lua << EOF
require('fill_func').setup()
EOF
```

Or in pure Vimscript in `init.vim`:

```vim
" After vim-plug loads plugins
lua require('fill_func').setup()
```

### Using Neovim's built-in package manager

```bash
# Clone into the pack directory
git clone https://github.com/adabarx/fill_func.git \
  ~/.local/share/nvim/site/pack/plugins/start/fill_func

# Also install nvim-treesitter
git clone https://github.com/nvim-treesitter/nvim-treesitter.git \
  ~/.local/share/nvim/site/pack/plugins/start/nvim-treesitter
```

Then in your `init.lua`:

```lua
require('fill_func').setup()
```

Or in `init.vim`:

```vim
lua require('fill_func').setup()
```

## Requirements

- Neovim >= 0.9.0
- `nvim-treesitter` plugin
- Tree-sitter parsers for your languages (`:TSInstall <language>`)
- GitHub Copilot (subscription + copilot.vim or copilot.lua)

## Usage

### Auto-Fill Mode

1. Write a function stub with a comment describing what it should do:

```lua
function fibonacci(n)
  -- calculate the nth fibonacci number recursively
end
```

2. Place cursor inside the function
3. Press `<leader>cf`
4. Copilot generates the implementation!

### Interactive Mode

1. Place cursor inside any function (stub or complete):

```python
def process_data(items):
    return [x * 2 for x in items]
```

2. Press `<leader>cp`
3. Enter your instruction: "add error handling for non-numeric items"
4. Copilot modifies the function!

## Configuration

Default configuration:

```lua
{
  keymaps = {
    auto_fill = '<leader>cf',    -- Auto-fill with comment
    interactive = '<leader>cp',   -- Interactive prompt
    cancel = '<Esc>',            -- Cancel operation
  },
  timeout = 30000,               -- Copilot timeout in ms
  context_lines = 5,             -- Lines of context before/after
  show_progress = true,          -- Show "Generating..." indicator
  progress_style = 'virtual_text', -- 'virtual_text' or 'floating'
}
```

## Commands

- `:FillFuncAuto` - Auto-fill function using comment as prompt
- `:FillFuncPrompt` - Interactive prompt for function generation/modification

## Supported Languages

Any language with Tree-sitter support! Built-in comment patterns for:

- Lua
- Python
- JavaScript/TypeScript
- Go
- Rust
- C/C++

More languages work automatically with default C-style comment detection.

## How It Works

1. **Function Detection**: Uses Tree-sitter to accurately identify function boundaries
2. **Context Extraction**: Grabs surrounding code for better Copilot understanding
3. **Prompt Building**: Combines function + context + instruction
4. **Copilot Integration**: Sends to GitHub Copilot LSP client
5. **Smart Replacement**: Replaces function while preserving indentation

## Troubleshooting

**"Tree-sitter parser not available"**
- Install the parser: `:TSInstall <language>`

**"Copilot LSP client not found"**
- Ensure GitHub Copilot plugin is installed and active
- Check `:LspInfo` to verify Copilot is running

**"No comment found in function"**
- Use interactive mode (`<leader>cp`) instead
- Or add a comment to your function stub

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.

## Credits

Built with ♥ for the Neovim community.
