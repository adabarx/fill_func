# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-06

### Added
- Initial release of Fill Func plugin
- Auto-fill mode: Extract comments from function stubs as prompts
- Interactive mode: Custom prompt input for function generation/modification
- Tree-sitter integration for accurate function detection
- Support for multiple languages: Lua, Python, JavaScript/TypeScript, Go, Rust, C/C++
- GitHub Copilot LSP integration
- Async operation with non-blocking UI
- Visual progress indicators (virtual text and floating window options)
- Context-aware prompt building (5 lines before/after function)
- Configurable keybindings and behavior
- Comprehensive documentation (README, QUICKSTART, help docs)
- Example files for testing
- Error handling and timeout management
- Indentation preservation in generated code

### Features
- `:FillFuncAuto` command for auto-fill mode
- `:FillFuncPrompt` command for interactive mode
- `<leader>cf` default keymap for auto-fill
- `<leader>cp` default keymap for interactive prompt
- Language-specific comment pattern support
- Extensible architecture for adding new languages

### Documentation
- Complete README with installation and usage
- Quick start guide (QUICKSTART.md)
- Contributing guidelines (CONTRIBUTING.md)
- Vim help documentation (`:help fill_func`)
- Project summary document
- Example files for testing

[1.0.0]: https://github.com/adabarx/fill_func/releases/tag/v1.0.0
