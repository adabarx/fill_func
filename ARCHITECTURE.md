# Fill Func - Architecture Documentation

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Data Flow](#data-flow)
4. [Module Documentation](#module-documentation)
5. [Data Structures](#data-structures)
6. [Design Decisions](#design-decisions)
7. [Extension Points](#extension-points)

---

## Overview

Fill Func is a Neovim plugin that uses GitHub Copilot to intelligently generate or modify function implementations. The architecture follows a modular design pattern with clear separation of concerns.

### Core Principles

- **Modularity**: Each module has a single, well-defined responsibility
- **Async-First**: Non-blocking operations for smooth user experience
- **Tree-sitter Native**: No regex fallbacks - requires proper parser support
- **Extensibility**: Easy to add new languages and features

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                           │
│  (Keybindings: <leader>cf, <leader>cp)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     plugin/fill_func.lua                        │
│  • Plugin initialization                                        │
│  • Command registration (:FillFuncAuto, :FillFuncPrompt)       │
│  • Keymap setup                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    lua/fill_func/init.lua                       │
│  • Main orchestrator                                            │
│  • Coordinates all modules                                      │
│  • Entry points: auto_fill(), interactive_fill()               │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐      ┌──────────────┐
│   detector   │    │    prompt    │      │     ui       │
│              │    │              │      │              │
│ Tree-sitter  │    │   Comment    │      │  Progress    │
│  Function    │    │  Extraction  │      │ Indicators   │
│  Detection   │    │  & User      │      │  & Feedback  │
│              │    │   Input      │      │              │
└──────────────┘    └──────────────┘      └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                    ┌──────────────┐
                    │   copilot    │
                    │              │
                    │  LSP Client  │
                    │ Integration  │
                    │              │
                    └──────────────┘
                              │
                              ▼
                    ┌──────────────┐
                    │   GitHub     │
                    │   Copilot    │
                    │  LSP Server  │
                    └──────────────┘

Supporting Modules:
┌──────────────┐    ┌──────────────┐
│   config     │    │  languages   │
│              │    │              │
│ Config Store │    │  Language    │
│ & Defaults   │    │  Patterns    │
└──────────────┘    └──────────────┘
```

---

## Data Flow

### Auto-Fill Mode Flow

```
1. User presses <leader>cf
       │
       ▼
2. init.auto_fill() called
       │
       ▼
3. detector.detect_function()
   - Get cursor position
   - Find function node via Tree-sitter
   - Extract function boundaries
   - Capture surrounding context
   - Returns: func_info structure
       │
       ▼
4. prompt.extract_comment(function_text, language)
   - Parse function text line by line
   - Match comment patterns for language
   - Concatenate comment text
   - Returns: instruction string
       │
       ▼
5. ui.show_progress()
   - Display "Generating..." indicator
       │
       ▼
6. copilot.generate(func_info, instruction, callback)
   - Find Copilot LSP client
   - Build prompt with context + instruction
   - Send LSP request (async)
   - Wait for response
       │
       ▼
7. Callback executed (in vim.schedule)
   - ui.hide_progress()
   - replace_function() with generated code
   - ui.show_success()
```

### Interactive Mode Flow

```
1. User presses <leader>cp
       │
       ▼
2. init.interactive_fill() called
       │
       ▼
3. detector.detect_function()
   - Same as auto-fill
   - Returns: func_info structure
       │
       ▼
4. prompt.get_user_prompt(callback)
   - Open vim.ui.input() dialog
   - User types instruction
   - Callback invoked with input
       │
       ▼
5. ui.show_progress()
       │
       ▼
6. copilot.generate(func_info, instruction, callback)
   - Same as auto-fill
       │
       ▼
7. Callback executed
   - ui.hide_progress()
   - replace_function() with generated code
   - ui.show_success()
```

---

## Module Documentation

### 1. `plugin/fill_func.lua` - Plugin Entry Point

**Purpose**: Initialize the plugin and register commands/keymaps when Neovim loads.

**Why it's needed**: Neovim plugins require a file in the `plugin/` directory to auto-load. This is the standard plugin initialization pattern.

#### Global Variables

- **`vim.g.loaded_fill_func`** (boolean)
  - **Purpose**: Prevent double-loading of plugin
  - **Why**: Multiple sourcing would create duplicate commands/keymaps

#### Functions

None (executes at load time)

#### Key Operations

1. **Guard clause check** (lines 2-4)
   ```lua
   if vim.g.loaded_fill_func then return end
   ```
   - Prevents reloading if already loaded
   - Standard Vim plugin pattern

2. **Command registration** (lines 9-15)
   ```lua
   vim.api.nvim_create_user_command('FillFuncAuto', ...)
   vim.api.nvim_create_user_command('FillFuncPrompt', ...)
   ```
   - Creates `:FillFuncAuto` and `:FillFuncPrompt` commands
   - Delegates to main module functions

3. **Keymap setup** (lines 20-21)
   - Reads config for user-defined keymaps
   - Sets up default `<leader>cf` and `<leader>cp`

---

### 2. `lua/fill_func/init.lua` - Main Orchestrator

**Purpose**: Coordinate all modules to execute the complete workflow.

**Why it's needed**: Central point of control that ties together detection, prompting, generation, and replacement.

#### Module Dependencies

```lua
local detector = require('fill_func.detector')  -- Function detection
local prompt = require('fill_func.prompt')      -- Comment/prompt handling
local copilot = require('fill_func.copilot')    -- Copilot integration
local ui = require('fill_func.ui')              -- User feedback
local config = require('fill_func.config')      -- Configuration
```

#### Functions

##### `M.setup(user_config)`

**Purpose**: Initialize plugin with user configuration.

**Parameters**:
- `user_config` (table|nil): User-provided configuration overrides

**Why it's needed**: Allows users to customize keymaps, timeouts, and other settings.

**Implementation**:
```lua
function M.setup(user_config)
  config.setup(user_config)
end
```
Simply delegates to config module.

---

##### `replace_function(func_info, new_code)` (Local Helper)

**Purpose**: Replace the detected function with generated code while preserving formatting.

**Parameters**:
- `func_info` (FunctionInfo): Detected function metadata
- `new_code` (string): Generated code from Copilot

**Why it's needed**: 
- Copilot may return code with inconsistent formatting
- Must preserve buffer indentation style
- Must clean up extra whitespace

**Algorithm**:

1. **Split into lines** (line 20)
   ```lua
   local lines = vim.split(new_code, '\n')
   ```

2. **Remove leading empty lines** (lines 23-25)
   ```lua
   while #lines > 0 and lines[1]:match('^%s*$') do
     table.remove(lines, 1)
   end
   ```
   - Why: Copilot often returns extra whitespace
   - Prevents ugly spacing in buffer

3. **Remove trailing empty lines** (lines 26-28)
   - Same reason as above

4. **Apply original indentation** (lines 31-36)
   ```lua
   for i, line in ipairs(lines) do
     if i > 1 and not line:match('^%s*$') then
       lines[i] = indent .. line
     end
   end
   ```
   - Preserves user's indentation style (tabs vs spaces)
   - Skips first line (already has correct indent)
   - Skips blank lines (don't indent)

5. **Replace buffer lines** (line 40)
   ```lua
   vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, lines)
   ```
   - Atomic replacement operation
   - Maintains undo history

**Why this is complex**: Different indentation styles (tabs vs spaces, 2 vs 4 spaces) must be preserved. Copilot's output may not match user's style.

---

##### `M.auto_fill()`

**Purpose**: Auto-fill mode - extract comment and generate function.

**Why it's needed**: Main entry point for comment-based generation.

**Flow**:

1. **Detect function** (line 44)
   ```lua
   local func_info, err = detector.detect_function()
   ```
   - Get function boundaries and context
   - Early return if cursor not in function

2. **Extract comment** (line 50)
   ```lua
   local instruction = prompt.extract_comment(func_info.function_text, func_info.language)
   ```
   - Parse function body for comments
   - Language-specific pattern matching
   - Early return if no comment found

3. **Show progress** (line 56)
   - User feedback during async operation

4. **Generate with Copilot** (line 58)
   ```lua
   copilot.generate(func_info, instruction, function(result, error)
   ```
   - Async operation - doesn't block UI
   - Callback handles success/error

5. **Replace and notify** (lines 66-67)
   - Only if generation succeeded
   - Update buffer and show success message

---

##### `M.interactive_fill()`

**Purpose**: Interactive mode - prompt user for instruction.

**Why it's needed**: More flexible than comment-based - works on any function, allows specific instructions.

**Flow**: Similar to auto_fill() but:
- Step 2: Prompts user instead of extracting comment
- More flexible - no comment required
- Can modify existing implementations

---

### 3. `lua/fill_func/detector.lua` - Function Detection

**Purpose**: Use Tree-sitter to accurately detect function boundaries and extract context.

**Why it's needed**: 
- Regex-based function detection is unreliable across languages
- Tree-sitter provides accurate AST-based detection
- Works across all languages with TS parsers

#### Functions

##### `get_function_node_at_cursor()` (Local Helper)

**Purpose**: Find the Tree-sitter function node at cursor position.

**Returns**: 
- `node, nil` on success
- `nil, error_message` on failure

**Algorithm**:

1. **Get cursor position** (lines 5-7)
   ```lua
   local bufnr = vim.api.nvim_get_current_buf()
   local cursor = vim.api.nvim_win_get_cursor(0)
   local row, col = cursor[1] - 1, cursor[2]  -- Convert to 0-indexed
   ```
   - Why 0-indexed: Tree-sitter uses 0-based indexing

2. **Get Tree-sitter parser** (lines 9-12)
   ```lua
   local parser = vim.treesitter.get_parser(bufnr)
   if not parser then
     return nil, "Tree-sitter parser not available for this filetype"
   end
   ```
   - Fails gracefully if no parser installed
   - User gets clear error message

3. **Parse buffer and get AST** (lines 14-15)
   ```lua
   local tree = parser:parse()[1]
   local root = tree:root()
   ```
   - Parse returns array of trees (multi-language support)
   - We use first tree (main language)

4. **Find node at cursor** (lines 17-20)
   ```lua
   local node = root:named_descendant_for_range(row, col, row, col)
   ```
   - Gets deepest named node at position
   - "Named" = syntactically significant (not punctuation)

5. **Traverse upward to find function** (lines 23-39)
   ```lua
   local function_node_types = {
     'function_declaration',    -- C, Go
     'function_definition',     -- Python, C++
     'method_definition',       -- Python, Ruby
     'arrow_function',          -- JavaScript
     'function',                -- Lua
     'method',                  -- Java, etc.
     'function_item',           -- Rust
   }
   
   local current = node
   while current do
     if vim.tbl_contains(function_node_types, current:type()) then
       return current, nil
     end
     current = current:parent()
   end
   ```
   - Start at cursor node, walk up parent chain
   - Check each node's type against known function types
   - **Why multiple types**: Different languages name function nodes differently
   - **Why upward traversal**: Cursor might be inside function body/parameter/etc

**Why this approach**:
- Tree-sitter node types vary by language grammar
- Walking up ensures we find enclosing function
- Type list covers most common languages

---

##### `M.detect_function()`

**Purpose**: Main export - detect function and return complete metadata structure.

**Returns**: 
- `FunctionInfo table, nil` on success
- `nil, error_message` on failure

**Algorithm**:

1. **Get function node** (lines 45-48)
   - Delegates to helper function
   - Early return on error

2. **Extract function boundaries** (lines 50-55)
   ```lua
   local start_row, start_col, end_row, end_col = func_node:range()
   local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
   local function_text = table.concat(lines, '\n')
   ```
   - Tree-sitter provides exact byte ranges
   - Extract full function text from buffer

3. **Detect indentation** (line 58)
   ```lua
   local indent = lines[1]:match('^(%s*)')
   ```
   - Capture leading whitespace of first line
   - **Why**: Need to preserve user's indent style when replacing

4. **Extract context** (lines 61-78)
   ```lua
   local context_start = math.max(0, start_row - context_lines)
   local context_end = math.min(total_lines, end_row + 1 + context_lines)
   ```
   - Get N lines before and after function (default: 5)
   - **Why context matters**: 
     - Copilot sees imports, type definitions, related functions
     - Better generation quality with more context
     - Understands project style and patterns
   - Bounds checking prevents reading outside buffer

5. **Build result structure** (lines 82-91)
   ```lua
   return {
     start_line = start_row,
     end_line = end_row,
     indent = indent,
     function_text = function_text,
     context_before = context_before,
     context_after = context_after,
     language = filetype,
     bufnr = bufnr,
   }
   ```

**Why this structure**: Provides everything needed for:
- Prompting Copilot (function text + context)
- Replacing in buffer (line numbers, bufnr)
- Formatting (indent style)

---

### 4. `lua/fill_func/prompt.lua` - Prompt Handling

**Purpose**: Extract comments from functions or get user input.

**Why it's needed**: Two modes require different prompt sources (comments vs user input).

#### Functions

##### `get_language_patterns(language)` (Local Helper)

**Purpose**: Get comment patterns for a language.

**Parameters**:
- `language` (string): Filetype (e.g., "lua", "python")

**Returns**: Pattern table or nil

**Why it's needed**: Different languages have different comment syntax.

---

##### `M.extract_comment(function_text, language)`

**Purpose**: Extract comment text from function body for auto-fill mode.

**Parameters**:
- `function_text` (string): Full function source code
- `language` (string): Language/filetype

**Returns**: 
- `string` - concatenated comment text
- `nil` - if no comments found

**Algorithm**:

1. **Get language patterns** (lines 10-13)
   ```lua
   local patterns = get_language_patterns(language)
   if not patterns then return nil end
   ```
   - Loads language-specific regex patterns
   - Falls back to C-style for unknown languages

2. **Split into lines** (line 15)
   ```lua
   local lines = vim.split(function_text, '\n')
   ```

3. **Extract comments from each line** (lines 18-25)
   ```lua
   for _, line in ipairs(lines) do
     local trimmed = line:match('^%s*(.-)%s*$')  -- Trim whitespace
     if patterns.single_line then
       local comment = trimmed:match(patterns.single_line)
       if comment then
         table.insert(comments, comment:match('^%s*(.-)%s*$'))
       end
     end
   end
   ```
   - Trim each line
   - Apply single-line comment pattern
   - Extract and trim comment text
   - **Why trim twice**: Line has leading indent, comment may have spacing

4. **Concatenate comments** (lines 28-30)
   ```lua
   if #comments > 0 then
     return table.concat(comments, ' ')
   end
   ```
   - Join with spaces (multiple comment lines become one instruction)
   - Return nil if no comments

**Example**:
```lua
function foo()
  -- calculate sum
  -- of two numbers
end
```
Returns: `"calculate sum of two numbers"`

**Why this approach**:
- Simple and works for 90% of cases
- Multi-line comments become cohesive instruction
- Language-agnostic through pattern abstraction

---

##### `M.get_user_prompt(callback)`

**Purpose**: Show input dialog for interactive mode.

**Parameters**:
- `callback` (function): Called with user input or nil

**Why callback pattern**: `vim.ui.input()` is async, can't return value directly.

**Implementation**:
```lua
vim.ui.input({
  prompt = 'Copilot Instruction: ',
  default = '',
}, function(input)
  if input and input ~= '' then
    callback(input)
  else
    callback(nil)  -- User cancelled or empty input
  end
end)
```

**Why it's needed**: Interactive mode requires runtime user input, not hardcoded in comment.

---

### 5. `lua/fill_func/copilot.lua` - Copilot Integration

**Purpose**: Interface with GitHub Copilot LSP server to generate code.

**Why it's needed**: 
- Core feature - generates the actual code
- Abstracts LSP communication complexity
- Handles async response properly

#### Functions

##### `find_copilot_client()` (Local Helper)

**Purpose**: Find the active Copilot LSP client.

**Returns**: 
- `client` object if found
- `nil` if not found

**Algorithm**:
```lua
local clients = vim.lsp.get_active_clients()
for _, client in ipairs(clients) do
  if client.name == 'copilot' then
    return client
  end
end
return nil
```

**Why it's needed**: 
- Need client object to send LSP requests
- Copilot must be running for plugin to work
- Provides clear error if Copilot unavailable

---

##### `build_prompt(func_info, instruction)` (Local Helper)

**Purpose**: Construct the prompt sent to Copilot.

**Parameters**:
- `func_info` (FunctionInfo): Function metadata
- `instruction` (string): What to do (from comment or user)

**Returns**: Complete prompt string

**Algorithm**:

```lua
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
```

**Structure**:
```
// Context before:
[5 lines before function]

// Function to modify/complete:
[actual function code]

// Context after:
[5 lines after function]

// Instruction: [user instruction]
// Please provide ONLY the complete function implementation, no explanation.
```

**Why this format**:
- **Context sections**: Help Copilot understand imports, types, related code
- **Labels** (`// Context before:`): Clarify structure for AI
- **Instruction**: Clear task specification
- **"ONLY function implementation"**: Prevent Copilot from adding markdown, explanations
- **Comments**: Work across all languages (Copilot understands `//` universally)

**Design decision**: Why `//` comments?
- Universal: Copilot trained on many languages, recognizes `//`
- Harmless: Even in languages without `//`, Copilot treats as meta-instruction
- Alternative would be language-specific comments, but adds complexity

---

##### `M.generate(func_info, instruction, callback)`

**Purpose**: Send generation request to Copilot and handle response.

**Parameters**:
- `func_info` (FunctionInfo): Function metadata
- `instruction` (string): Generation instruction
- `callback` (function): `function(result, error)` - called with result or error

**Why callback pattern**: LSP requests are async - can't block editor.

**Algorithm**:

1. **Find Copilot client** (lines 40-45)
   ```lua
   local client = find_copilot_client()
   if not client then
     callback(nil, "GitHub Copilot LSP client not found...")
     return
   end
   ```
   - Early return with error if Copilot not running

2. **Build prompt** (line 47)
   ```lua
   local prompt_text = build_prompt(func_info, instruction)
   ```

3. **Prepare LSP request params** (lines 49-61)
   ```lua
   local params = {
     doc = {
       source = prompt_text,           -- What to generate
       tabSize = vim.bo.tabstop,       -- Editor tab size
       indentSize = vim.bo.shiftwidth, -- Editor indent size
       insertSpaces = vim.bo.expandtab, -- Tabs or spaces
       path = vim.api.nvim_buf_get_name(func_info.bufnr),
       uri = vim.uri_from_bufnr(func_info.bufnr),
       relativePath = vim.fn.expand('%:t'),
       languageId = func_info.language,
       position = { line = func_info.start_line, character = 0 },
     }
   }
   ```
   - **Why include editor settings**: Copilot adapts formatting to match
   - **Why include path/uri**: Copilot uses file context for better suggestions
   - **Why include position**: Some LSP methods need cursor position

4. **Send LSP request** (lines 63-84)
   ```lua
   client.request('getCompletionsCycling', params, function(err, result)
     vim.schedule(function()
       -- Handle response
     end)
   end, func_info.bufnr)
   ```
   - **Method**: `getCompletionsCycling` - Copilot's completion API
   - **vim.schedule**: Required for buffer modifications from async context
   - **Why schedule**: LSP callbacks run in libuv thread, must schedule buffer ops

5. **Handle response** (lines 64-82)
   ```lua
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
   ```
   - Defensive checks at each step
   - Use first completion (best match)
   - Try both `text` and `displayText` fields (API varies)

**Why this complexity**: 
- Async LSP communication is inherently complex
- Need defensive error handling (network issues, Copilot errors, malformed responses)
- Must schedule buffer operations properly

---

### 6. `lua/fill_func/ui.lua` - User Interface Feedback

**Purpose**: Provide visual feedback during async operations.

**Why it's needed**: 
- User needs to know generation is happening (async = no immediate result)
- Errors must be displayed clearly
- Success confirmation improves UX

#### Module State

##### `ns_id` (number)

```lua
local ns_id = vim.api.nvim_create_namespace('fill_func')
```

**Purpose**: Namespace ID for extmarks.

**Why it's needed**: 
- Extmarks need namespace to avoid conflicts with other plugins
- Allows bulk clearing of all our extmarks

##### `current_extmark` (number | table | nil)

**Purpose**: Track currently displayed progress indicator.

**Why it's needed**: Must store reference to hide it later.

**Types**:
- `number`: Extmark ID (for virtual text style)
- `table`: `{type='float', win=win_id, buf=buf_id}` (for floating window style)
- `nil`: No progress shown

#### Functions

##### `M.show_progress(bufnr, line)`

**Purpose**: Display progress indicator at function location.

**Parameters**:
- `bufnr` (number): Buffer number
- `line` (number): Line number to show indicator

**Algorithm**:

1. **Check if enabled** (lines 10-12)
   ```lua
   if not config.show_progress then return end
   ```

2. **Virtual text style** (lines 14-18)
   ```lua
   if config.progress_style == 'virtual_text' then
     current_extmark = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
       virt_text = { { '  Generating with Copilot...', 'Comment' } },
       virt_text_pos = 'eol',
     })
   end
   ```
   - Shows text at end of line
   - Styled as comment (non-intrusive)
   - **Why EOL**: Doesn't interfere with code
   - Returns extmark ID for later removal

3. **Floating window style** (lines 19-39)
   ```lua
   elseif config.progress_style == 'floating' then
     local buf = vim.api.nvim_create_buf(false, true)
     vim.api.nvim_buf_set_lines(buf, 0, -1, false, { ' Generating with Copilot...' })
     
     local opts = {
       relative = 'win',
       width = 30,
       height = 1,
       row = vim.api.nvim_win_get_cursor(0)[1],
       col = 0,
       style = 'minimal',
       border = 'rounded',
     }
     
     local win = vim.api.nvim_open_win(buf, false, opts)
     current_extmark = { type = 'float', win = win, buf = buf }
   end
   ```
   - Creates scratch buffer
   - Opens floating window
   - Positioned at cursor row
   - **Why not focused**: Don't interrupt user
   - Store window and buffer IDs for cleanup

**Design choice**: Two styles because:
- Virtual text: Minimal, unobtrusive
- Floating: More visible, good for slow connections
- User preference

---

##### `M.hide_progress()`

**Purpose**: Remove progress indicator after generation completes.

**Algorithm**:

```lua
if not current_extmark then return end

if type(current_extmark) == 'table' and current_extmark.type == 'float' then
  if vim.api.nvim_win_is_valid(current_extmark.win) then
    vim.api.nvim_win_close(current_extmark.win, true)
  end
  if vim.api.nvim_buf_is_valid(current_extmark.buf) then
    vim.api.nvim_buf_delete(current_extmark.buf, { force = true })
  end
else
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

current_extmark = nil
```

**Why complex**:
- Must handle both styles (virtual text vs floating)
- **Validation checks** (`nvim_win_is_valid`): Window might be closed by user
- **Force delete**: Prevent "unsaved changes" prompts for scratch buffer
- **Clear namespace**: Remove all extmarks at once (efficient)
- Reset state to nil

---

##### `M.show_error(message)` and `M.show_success(message)`

**Purpose**: Display user notifications.

```lua
function M.show_error(message)
  vim.notify('Fill Func: ' .. message, vim.log.levels.ERROR)
end

function M.show_success(message)
  vim.notify('Fill Func: ' .. (message or 'Function filled successfully!'), vim.log.levels.INFO)
end
```

**Why it's needed**: 
- Consistent error handling
- Plugin prefix helps user identify source
- Proper log levels for filtering
- Success feedback improves UX

---

### 7. `lua/fill_func/config.lua` - Configuration Management

**Purpose**: Store and manage plugin configuration.

**Why it's needed**: 
- Single source of truth for settings
- Default values
- User overrides
- Accessed by all modules

#### Module State

##### `defaults` (table)

```lua
local defaults = {
  keymaps = {
    auto_fill = '<leader>cf',
    interactive = '<leader>cp',
    cancel = '<Esc>',
  },
  timeout = 30000,
  context_lines = 5,
  show_progress = true,
  progress_style = 'virtual_text',
}
```

**Purpose**: Default configuration values.

**Why these defaults**:
- `<leader>cf`: Mnemonic "Copilot Fill"
- `<leader>cp`: Mnemonic "Copilot Prompt"
- 30s timeout: Copilot usually responds in 2-5s, allows for slow networks
- 5 context lines: Enough context without overwhelming Copilot
- Virtual text: Non-intrusive default

##### `config` (table)

```lua
local config = vim.deepcopy(defaults)
```

**Purpose**: Active configuration (defaults + user overrides).

**Why deepcopy**: Prevent mutation of defaults table.

#### Functions

##### `M.setup(user_config)`

**Purpose**: Merge user configuration with defaults.

```lua
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', defaults, user_config or {})
end
```

**Why `tbl_deep_extend`**: 
- Deep merge (nested tables)
- User can override just `keymaps.auto_fill` without specifying all keymaps
- 'force' mode: User values override defaults

##### `M.get()`

**Purpose**: Get current configuration.

```lua
function M.get()
  return config
end
```

**Why getter function**: 
- Encapsulation
- Could add validation logic later
- Clear API

---

### 8. `lua/fill_func/languages/init.lua` - Language Registry

**Purpose**: Map filetypes to language-specific comment patterns.

**Why it's needed**: Different languages use different comment syntax.

#### Module State

##### `language_modules` (table)

```lua
local language_modules = {
  lua = 'fill_func.languages.lua',
  python = 'fill_func.languages.python',
  javascript = 'fill_func.languages.javascript',
  typescript = 'fill_func.languages.javascript',  -- Reuse JS patterns
  javascriptreact = 'fill_func.languages.javascript',
  typescriptreact = 'fill_func.languages.javascript',
  go = 'fill_func.languages.go',
  rust = 'fill_func.languages.rust',
  c = 'fill_func.languages.c',
  cpp = 'fill_func.languages.c',  -- Reuse C patterns
}
```

**Purpose**: Map Neovim filetypes to pattern modules.

**Why separate modules**: 
- Each language has unique comment syntax
- Easy to add new languages
- Reduces coupling

**Pattern**: Some languages share modules (TS/JS, C/C++) because comment syntax is identical.

#### Functions

##### `M.get_patterns(language)`

**Purpose**: Load comment patterns for a language.

**Parameters**:
- `language` (string): Neovim filetype

**Returns**: 
- Pattern table with `single_line`, `multi_line_start`, `multi_line_end`
- Default C-style patterns if language unknown
- `nil` if module load fails

**Algorithm**:

```lua
local module_name = language_modules[language]
if not module_name then
  return {
    single_line = '^//(.*)$',  -- Default to C-style
  }
end

local ok, module = pcall(require, module_name)
if not ok then
  return nil
end

return module.comment_patterns
```

**Why pcall**: 
- Graceful failure if module doesn't exist
- Won't crash entire plugin

**Why default to C-style**: 
- Most common syntax (`//`)
- Works for many unlisted languages
- Better than failing completely

---

## Data Structures

### FunctionInfo

**Produced by**: `detector.detect_function()`  
**Used by**: All modules after detection

```lua
{
  start_line = number,       -- 0-indexed start line
  end_line = number,         -- 0-indexed end line (inclusive)
  indent = string,           -- Leading whitespace (e.g., "  " or "\t")
  function_text = string,    -- Full function source
  context_before = string,   -- N lines before function
  context_after = string,    -- N lines after function
  language = string,         -- Filetype (e.g., "lua", "python")
  bufnr = number,           -- Buffer number
}
```

**Why each field**:
- `start_line`, `end_line`: Where to replace in buffer
- `indent`: Preserve user's indentation style
- `function_text`: What to send to Copilot
- `context_before/after`: Improve generation quality
- `language`: Select comment patterns
- `bufnr`: Which buffer to modify

**Design note**: Could include more (function name, parameters) but not needed for current features. Keep it minimal.

---

### CommentPatterns

**Produced by**: Language modules  
**Used by**: `prompt.extract_comment()`

```lua
{
  single_line = string,       -- Lua pattern for single-line comments
  multi_line_start = string,  -- Lua pattern for multi-line start (optional)
  multi_line_end = string,    -- Lua pattern for multi-line end (optional)
}
```

**Examples**:

```lua
-- Lua
{
  single_line = '^%-%-(.*)$',
  multi_line_start = '^%-%-%[%[',
  multi_line_end = '%]%]$',
}

-- Python
{
  single_line = '^#(.*)$',
  multi_line_start = '^"""',
  multi_line_end = '"""$',
}

-- JavaScript
{
  single_line = '^//(.*)$',
  multi_line_start = '^/%*',
  multi_line_end = '%*/$',
}
```

**Why Lua patterns**: 
- Built into Lua, no dependencies
- Fast pattern matching
- Good enough for comment detection
- **Note**: These are Lua patterns, not regex (different syntax)

**Limitations**: 
- Currently only extracts single-line comments
- Multi-line patterns defined but not used
- Future enhancement: Extract from doc comments

---

### Config Structure

**Produced by**: `config.setup()`  
**Used by**: All modules

```lua
{
  keymaps = {
    auto_fill = string,      -- Keymap for auto-fill mode
    interactive = string,    -- Keymap for interactive mode
    cancel = string,         -- Keymap to cancel (future use)
  },
  timeout = number,          -- Copilot request timeout (ms)
  context_lines = number,    -- Lines of context to extract
  show_progress = boolean,   -- Whether to show progress indicator
  progress_style = string,   -- 'virtual_text' or 'floating'
}
```

**Why each field**:
- `keymaps`: User customization
- `timeout`: Slow connections need longer
- `context_lines`: Balance between context and noise
- `show_progress`: Some users prefer minimal UI
- `progress_style`: User preference

---

## Design Decisions

### 1. Why Tree-sitter Only (No Regex Fallback)?

**Decision**: Require Tree-sitter parser, don't fall back to regex.

**Rationale**:
- **Accuracy**: Regex can't handle nested functions, closures, edge cases
- **Simplicity**: Maintaining regex for each language is complex
- **Future-proof**: Tree-sitter is Neovim's future
- **User expectation**: Tree-sitter is standard in modern Neovim (0.9+)

**Tradeoff**: Plugin won't work without parser, but that's acceptable given benefits.

---

### 2. Why Async (Non-blocking)?

**Decision**: Use async LSP requests with callbacks.

**Rationale**:
- Copilot requests take 2-10 seconds
- Blocking UI for that long is unacceptable
- Users can continue editing during generation

**Implementation**: LSP client API is inherently async, we embrace it.

**Complexity cost**: Callback pattern is more complex than sync, but necessary.

---

### 3. Why Context Extraction?

**Decision**: Send 5 lines before/after function to Copilot.

**Rationale**:
- Copilot generates better code with context
- Sees imports, type definitions, related functions
- Understands project conventions

**Why 5 lines**: 
- Enough to capture nearby imports/types
- Not so much that it confuses Copilot
- Configurable via `context_lines`

**Tradeoff**: Slightly slower (more text to send), but much better results.

---

### 4. Why Two Modes (Auto vs Interactive)?

**Decision**: Support both comment-based and prompt-based generation.

**Rationale**:
- **Auto mode**: Fast, works for simple cases, good for greenfield code
- **Interactive mode**: Flexible, works on existing code, specific instructions

**Why not just one**:
- Different use cases deserve different UX
- Auto mode is faster (no typing)
- Interactive mode is more powerful

**User feedback**: Having both modes is a strength.

---

### 5. Why Language-Specific Comment Patterns?

**Decision**: Maintain pattern files for each language instead of universal approach.

**Rationale**:
- Comment syntax varies significantly (`--` vs `#` vs `//`)
- Lua patterns are simple and fast
- Easy to add new languages

**Tradeoff**: More files to maintain, but better accuracy.

**Alternative considered**: Universal tree-sitter comment detection, but TS doesn't consistently tag comments across languages.

---

### 6. Why Module-per-Concern Architecture?

**Decision**: Split into small, focused modules.

**Rationale**:
- **Testability**: Each module can be tested in isolation
- **Maintainability**: Easy to find and fix bugs
- **Extensibility**: Add features without touching unrelated code
- **Clarity**: Each file has one job

**Tradeoff**: More files, but worth it for large plugins.

---

### 7. Why Store Indent String?

**Decision**: Capture and reuse original indentation style.

**Rationale**:
- Users have strong preferences (tabs vs spaces, 2 vs 4 spaces)
- Copilot might return different style
- Inconsistent indentation is jarring

**Implementation**: Extract from first line, apply to generated code.

---

## Extension Points

### Adding a New Language

**Steps**:

1. Create `lua/fill_func/languages/<language>.lua`:
```lua
local M = {}

M.comment_patterns = {
  single_line = '^pattern(.*)$',
  multi_line_start = '^pattern',
  multi_line_end = 'pattern$',
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

3. Ensure Tree-sitter parser installed (`:TSInstall <language>`)

**That's it!** No other changes needed.

---

### Adding a New Progress Style

**Steps**:

1. Add case to `ui.show_progress()`:
```lua
elseif config.progress_style == 'statusline' then
  -- Set statusline indicator
  current_extmark = { type = 'statusline', ... }
```

2. Handle in `ui.hide_progress()`:
```lua
elseif current_extmark.type == 'statusline' then
  -- Clear statusline
```

3. Document in README

---

### Adding Multi-line Comment Support

**Current state**: Patterns defined but not used.

**To implement**:

1. Enhance `prompt.extract_comment()`:
```lua
local in_multiline = false
for _, line in ipairs(lines) do
  if line:match(patterns.multi_line_start) then
    in_multiline = true
  end
  
  if in_multiline then
    -- Extract comment content
  end
  
  if line:match(patterns.multi_line_end) then
    in_multiline = false
  end
end
```

2. Test with each language's multi-line syntax

---

### Adding Copilot Alternatives

**To support ChatGPT/Claude/etc**:

1. Add adapter in `copilot.lua`:
```lua
local function generate_openai(func_info, instruction, callback)
  -- OpenAI API call
end

function M.generate(func_info, instruction, callback)
  local provider = config.get().provider
  if provider == 'openai' then
    return generate_openai(func_info, instruction, callback)
  elseif provider == 'copilot' then
    return generate_copilot(func_info, instruction, callback)
  end
end
```

2. Add config option:
```lua
defaults.provider = 'copilot'
```

---

## Performance Considerations

### 1. Tree-sitter Parsing

- **Cost**: Negligible - Neovim already parses incrementally
- **Our usage**: Just query existing AST
- **Optimization**: Cache parser object? Not needed - Neovim caches

### 2. Context Extraction

- **Cost**: Reading N lines from buffer (default: 5 before + 5 after)
- **Impact**: Minimal - 10 lines is tiny
- **Optimization possible**: Only extract if generation fails first time

### 3. LSP Request

- **Cost**: Network latency + Copilot processing (2-10 seconds)
- **Impact**: High, but unavoidable
- **Mitigation**: Async operation prevents blocking

### 4. Buffer Replacement

- **Cost**: Single `nvim_buf_set_lines()` call
- **Impact**: Negligible
- **Optimization**: Already atomic

**Conclusion**: Performance is excellent. No bottlenecks.

---

## Error Handling Strategy

### Defensive Programming

Every external operation checks for errors:
- Tree-sitter parser availability
- Node finding
- LSP client availability
- Copilot response validity
- Window/buffer validity

### User-Friendly Messages

Errors include actionable information:
- "Tree-sitter parser not available" → User knows to install parser
- "Copilot LSP client not found" → User knows to install Copilot
- "No comment found" → User knows to use interactive mode

### Graceful Degradation

- Missing language patterns → Fall back to C-style
- Invalid progress state → Skip cleanup (don't crash)
- Cancelled user input → Silent return (not an error)

---

## Testing Strategy

### Manual Testing

Use example files:
```bash
nvim examples/test.lua
# Try auto-fill
# Try interactive mode
# Try error cases (no parser, no copilot)
```

### Unit Testing (Future)

Potential test structure:
```lua
describe('detector', function()
  it('finds function at cursor', function()
    -- Create buffer with function
    -- Set cursor inside
    -- Call detect_function()
    -- Assert correct boundaries
  end)
end)
```

### Integration Testing (Future)

Mock Copilot responses:
```lua
describe('auto_fill', function()
  it('replaces function with generated code', function()
    -- Mock copilot.generate()
    -- Call auto_fill()
    -- Assert buffer updated
  end)
end)
```

---

## Conclusion

Fill Func's architecture prioritizes:
- **Modularity**: Each file has one job
- **Reliability**: Defensive error handling throughout
- **User experience**: Async operations, clear feedback
- **Extensibility**: Easy to add languages and features
- **Simplicity**: No unnecessary complexity

The design achieves these goals through:
- Tree-sitter for accurate detection
- LSP for AI integration
- Callbacks for async operations
- Pattern-based language support
- Focused, composable modules

Future enhancements can build on this solid foundation without major refactoring.
