# Fill Function - Neovim Plugin Plan

## Overview
A Neovim plugin that allows users to stub out functions with comments as prompts, then use a hotkey to have GitHub Copilot fill in the function body asynchronously.

## Core Functionality

### 1. Two Modes of Operation

#### Mode A: Auto-Fill with Comment Prompt (Primary Mode)
- Default hotkey: `<leader>cf` (copilot fill)
- User writes a function stub with a comment inside
- Press hotkey → extracts comment as prompt → sends function + prompt to Copilot
- Replaces function body with generated code

**Example:**
```lua
function calculate_sum(a, b)
  -- calculate the sum of two numbers and return it
end
```
Press `<leader>cf` → Copilot fills it in

#### Mode B: Interactive Prompt (Edit/Create Mode)
- Default hotkey: `<leader>cp` (copilot prompt)
- Works on ANY function (stub or complete)
- Press hotkey → opens input prompt at bottom
- User types instruction: "add error handling" or "make it recursive"
- Sends function + context + user prompt to Copilot
- Replaces function with edited/generated code

**Example:**
```lua
function calculate_sum(a, b)
  return a + b
end
```
Cursor inside function → Press `<leader>cp` → Type "add type checking and return nil on error" → Copilot modifies the function

### 2. Function Detection (Simplified)
- Detect if cursor is inside a function (any function)
- Extract function boundaries
- No need to check if it's a "stub" or parse comments
- Just send the whole function + surrounding context

### 3. Asynchronous Copilot Integration
- Use Copilot API to generate/edit function implementation
- Show loading indicator while waiting
- Handle errors gracefully
- Allow cancellation with `<Esc>` or another hotkey

## Architecture

### File Structure
```
fill_func/
├── README.md
├── LICENSE
├── plugin/
│   └── fill_func.lua          # Plugin initialization
├── lua/
│   └── fill_func/
│       ├── init.lua            # Main entry point
│       ├── config.lua          # Configuration management
│       ├── detector.lua        # Function detection (Tree-sitter based)
│       ├── prompt.lua          # Extract comment prompts, handle user input
│       ├── copilot.lua         # Copilot API integration
│       ├── ui.lua              # UI feedback (loading, errors)
│       └── languages/
│           ├── init.lua        # Language registry
│           ├── lua.lua         # Lua comment patterns
│           ├── python.lua      # Python comment patterns
│           └── javascript.lua  # JavaScript comment patterns
└── doc/
    └── fill_func.txt           # Vim help documentation
```

### Core Modules

#### 1. `config.lua`
- Default configuration
- User configuration overrides
- Configurable options:
  - Hotkey mapping
  - Supported languages
  - Copilot timeout
  - Loading indicator style
  - Prompt comment patterns

#### 2. `detector.lua`
- Detect if cursor is inside a function using Tree-sitter
- Get Tree-sitter node at cursor position
- Check if node or parent is a function node
- Extract function node range and text
- Get surrounding context from buffer
- Return function boundaries and context:
  ```lua
  {
    start_line = 10,
    end_line = 15,
    indent = "  ",
    function_text = "function calculate_sum(a, b)\n  return a + b\nend",
    context_before = "-- Previous 5 lines of code",
    context_after = "-- Next 5 lines of code",
    language = "lua"
  }
  ```

#### 3. `prompt.lua`
- **For auto-fill mode**: Extract comment from function body
- **For interactive mode**: Open input prompt using `vim.ui.input()`
- Clean and format prompts
- Return prompt string for Copilot

#### 4. `copilot.lua`
- Interface with GitHub Copilot
- Options:
  - **Option A**: Use `copilot.lua` plugin's internal API (if available)
  - **Option B**: Use Copilot CLI/API directly
  - **Option C**: Use `vim.lsp.buf_request` to LSP copilot server
- Send context + prompt
- Handle async response
- Return generated code

#### 5. `ui.lua`
- Show "Generating..." virtual text or floating window
- Display errors in a user-friendly way
- Show success indicator
- Handle cancellation

#### 6. `languages/*.lua`
- Language-specific comment syntax only (Tree-sitter handles function detection)
- Comment extraction patterns
- Example for Lua:
  ```lua
  {
    comment_patterns = {
      single_line = "^%s*%-%-(.*)$",      -- matches: -- comment
      multi_line_start = "^%s*%-%-%[%[",  -- matches: --[[
      multi_line_end = "%]%]%s*$"         -- matches: ]]
    }
  }
  ```
- Tree-sitter queries handle all function detection automatically

## Implementation Steps

### Phase 1: Basic Infrastructure (Foundational)
1. Set up plugin structure and file skeleton
2. Create basic configuration system
3. Implement language detection
4. Set up hotkey mapping

### Phase 2: Function Detection (Core Feature)
5. Implement Tree-sitter integration for function detection
6. Create Tree-sitter queries for common function node types
7. Test cursor position detection across multiple languages
8. Extract function boundaries + surrounding context

### Phase 3: Prompt Handling
9. Extract comment from function body (auto-fill mode)
10. Implement `vim.ui.input()` for interactive prompt (edit mode)
11. Clean and format prompts
12. Handle multi-line comments

### Phase 4: Copilot Integration
13. Research best method to integrate with Copilot
14. Implement async API calls
15. Handle authentication/authorization
16. Parse and format response

### Phase 5: Code Replacement
17. Replace stub body with generated code
18. Preserve indentation
19. Handle edge cases (empty response, malformed code)
20. Maintain cursor position

### Phase 6: UI/UX
21. Add loading indicator
22. Show error messages
23. Add success feedback
24. Implement cancellation

### Phase 7: Multi-language Support (Tree-sitter Based)
25. Use Tree-sitter for language-agnostic function detection
26. Query Tree-sitter for function nodes (works for all languages with TS parsers)
27. Add language-specific comment patterns only (via `languages/*.lua`)
28. Automatic support for any language with Tree-sitter parser installed

### Phase 8: Polish & Documentation
29. Write comprehensive README
30. Create Vim help documentation
31. Add configuration examples
32. Write tests

## Configuration Example

```lua
require('fill_func').setup({
  -- Keymaps
  keymaps = {
    fill = '<leader>cf',      -- Auto-fill using comment as prompt
    prompt = '<leader>cp',    -- Interactive prompt for edit/create
  },
  
  -- Timeout for Copilot request (ms)
  timeout = 10000,
  
  -- Show loading indicator
  show_loading = true,
  
  -- Lines of context to include before/after function
  context_lines = 5,
  
  -- Supported languages (auto-detected)
  languages = { 'lua', 'python', 'javascript', 'typescript', 'go', 'rust' },
  
  -- Custom language patterns (advanced)
  custom_patterns = {},
  
  -- Copilot options
  copilot = {
    -- Use copilot.lua plugin if available
    use_plugin = true,
    -- Max tokens for generation
    max_tokens = 500,
  },
  
  -- UI options
  ui = {
    loading_text = "⏳ Generating...",
    success_text = "✓ Done",
    error_text = "✗ Error: %s",
    virtual_text = true,
    -- Prompt input options
    prompt_title = "Copilot Instruction:",
  }
})
```

## Usage Examples

### Example 1: Auto-Fill Mode (Comment as Prompt)

1. Write a stub:
```lua
function fibonacci(n)
  -- calculate the nth fibonacci number recursively
end
```

2. Place cursor inside function
3. Press `<leader>cf`
4. Wait for generation
5. Result:
```lua
function fibonacci(n)
  -- calculate the nth fibonacci number recursively
  if n <= 1 then
    return n
  end
  return fibonacci(n - 1) + fibonacci(n - 2)
end
```

### Example 2: Interactive Prompt Mode (Edit Existing Function)

1. You have this function:
```lua
function calculate_sum(a, b)
  return a + b
end
```

2. Place cursor inside function
3. Press `<leader>cp`
4. Input prompt appears: `Copilot Instruction: _`
5. Type: `add type checking and handle nil values`
6. Press Enter, wait for generation
7. Result:
```lua
function calculate_sum(a, b)
  if type(a) ~= "number" or type(b) ~= "number" then
    return nil, "arguments must be numbers"
  end
  return a + b
end
```

### Example 3: Create Complex Function from Scratch

1. Empty stub:
```python
def process_data(items):
    pass
```

2. Press `<leader>cp`
3. Type: `filter items where value > 10, sort by name, return as dictionary`
4. Copilot generates full implementation

## Technical Considerations

### Tree-sitter Integration (Primary Method)
- **Require** `nvim-treesitter` for function detection (no regex fallback needed)
- Use Tree-sitter queries to find function nodes:
  - Generic queries work across languages: `(function_declaration)`, `(function_definition)`, `(method_definition)`
  - Tree-sitter automatically adapts to language grammar
- Get function node at cursor position
- Extract node text and boundaries
- Get surrounding context nodes
- **Benefits**: Works for ANY language with Tree-sitter parser installed (Lua, Python, JS, TS, Go, Rust, C, C++, Java, etc.)

**Example Tree-sitter query:**
```lua
local query = vim.treesitter.query.parse(lang, [[
  [
    (function_declaration) @func
    (function_definition) @func
    (method_definition) @func
    (arrow_function) @func
  ]
]])
```

### Copilot Integration Options

**Option 1: Via copilot.lua plugin**
- Pros: Already integrated, handles auth
- Cons: Dependency on another plugin
- Method: Call internal API if exposed

**Option 2: Direct LSP communication**
- Pros: Direct control, no extra dependencies
- Cons: Need to handle Copilot LSP protocol
- Method: Use `vim.lsp.buf_request_sync` or async variant

**Option 3: Copilot CLI**
- Pros: Simple interface
- Cons: Requires CLI installation, slower
- Method: Use `vim.fn.system()` or job API

**Recommended: Option 2 (Direct LSP)** with fallback to Option 1

### Async Handling
- Use `vim.loop` (libuv) for async operations
- Use `vim.schedule()` to update UI safely
- Implement proper error handling and timeouts

### Error Scenarios
- Cursor not in function → Show error message
- No comment found (auto-fill mode) → Show error, suggest using interactive mode
- Empty prompt (interactive mode) → Cancel operation
- Copilot timeout → Show timeout error, allow retry
- Invalid code generated → Show warning, allow manual edit
- Copilot not available → Show setup instructions

## Future Enhancements

1. **Multiple implementations**: Generate several options, let user choose
2. **Inline preview**: Show generated code as ghost text before applying
3. **Undo support**: Easy revert to stub
4. **Batch processing**: Fill multiple stubs at once
5. **Custom prompts**: Override comment with visual selection
6. **Test generation**: Generate tests for the filled function
7. **Documentation generation**: Auto-generate doc comments
8. **Learning from feedback**: Track which generations were kept/reverted

## Dependencies

- Neovim >= 0.9.0 (for stable Tree-sitter API)
- `nvim-treesitter` (required for function detection)
- Tree-sitter parsers for languages you want to use (installed via `:TSInstall <lang>`)
- GitHub Copilot (subscription required)
- Optional: `copilot.lua` or `copilot.vim` plugin

## Testing Strategy

1. Unit tests for parser and detector
2. Integration tests with sample files
3. Test each supported language
4. Test error scenarios
5. Performance testing with large files

## Success Criteria

- ✓ Correctly detect function stubs in multiple languages
- ✓ Extract comments and use as prompts
- ✓ Asynchronously call Copilot without blocking UI
- ✓ Replace stub with generated code maintaining formatting
- ✓ Handle errors gracefully
- ✓ Configurable and extensible
- ✓ Well-documented
