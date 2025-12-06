# Contributing to Fill Func

Thank you for your interest in contributing to Fill Func! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs

When filing an issue, please include:
- Neovim version (`:version`)
- fill_func version
- Steps to reproduce
- Expected vs actual behavior
- Sample code that demonstrates the issue
- Relevant configuration

### Suggesting Features

Feature requests are welcome! Please include:
- Clear use case description
- Example of how it would work
- Any relevant examples from other plugins/tools

### Contributing Code

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/yourusername/fill_func.git
   cd fill_func
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Keep changes focused and atomic

4. **Test your changes**
   - Test with multiple languages
   - Test both auto-fill and interactive modes
   - Verify no regressions

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   git push origin feature/my-feature
   ```

6. **Open a Pull Request**
   - Describe what the PR does
   - Reference any related issues
   - Include examples/screenshots if relevant

## Development Setup

### Prerequisites
- Neovim >= 0.9.0
- nvim-treesitter
- GitHub Copilot
- Tree-sitter parsers for testing

### Local Development
```lua
-- In your nvim config, point to local copy:
{
  dir = '~/projects/fill_func',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('fill_func').setup({
      -- your test config
    })
  end,
}
```

### Project Structure
```
fill_func/
├── plugin/           # Plugin initialization
├── lua/fill_func/    # Core modules
│   ├── languages/    # Language-specific patterns
│   └── ...
├── doc/              # Help documentation
└── examples/         # Example files for testing
```

## Code Style

- Use 2 spaces for indentation
- Follow Lua conventions
- Comment complex logic
- Keep functions small and focused
- Use descriptive variable names

## Adding Language Support

To add support for a new language:

1. Create `lua/fill_func/languages/<language>.lua`:
```lua
local M = {}

M.comment_patterns = {
  single_line = '^#(.*)$',  -- Adjust for your language
  multi_line_start = '^"""',
  multi_line_end = '"""$',
}

return M
```

2. Register in `lua/fill_func/languages/init.lua`:
```lua
local language_modules = {
  -- ...
  ruby = 'fill_func.languages.ruby',
}
```

3. Add example file in `examples/test.<ext>`

4. Test with Tree-sitter parser installed

## Testing Checklist

Before submitting a PR, verify:

- [ ] Auto-fill mode works
- [ ] Interactive mode works
- [ ] Error handling is graceful
- [ ] Progress indicator shows/hides correctly
- [ ] Function detection works for edge cases
- [ ] Indentation is preserved
- [ ] Multiple languages tested
- [ ] No console errors or warnings
- [ ] Documentation updated if needed

## Commit Message Format

Follow conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance tasks

Examples:
- `feat: add support for Ruby`
- `fix: incorrect indentation in generated code`
- `docs: update installation instructions`

## Questions?

Feel free to:
- Open an issue for discussion
- Ask in pull request comments
- Reach out to maintainers

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to make great software together!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
