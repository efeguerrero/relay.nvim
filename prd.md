# relay.nvim — PRD / Technical Specification

## Goal

Create a lightweight Neovim plugin for building contextual AI prompts directly from code selections.

The plugin allows a developer to:

* select code ranges
* attach short comments/instructions
* visually annotate the code in-editor
* navigate annotations
* edit/delete annotations
* export all annotations into a portable markdown document
* hand that document to an external coding agent

The workflow is intentionally:

* ephemeral
* lightweight
* editor-native
* code-centric

---

# Core Philosophy

The plugin should:

* minimize friction
* stay inside the coding workflow
* avoid chat-style prompting
* allow developers to think directly through code

The core interaction model is:

```text
(code selection) + (developer intent/comment)
```

Repeated iteratively across buffers/files.

---

# V1 Scope

## Primary Goals

V1 should:

* use extmarks as the only source of truth
* provide visual feedback in buffers
* support editing/deleting annotations
* support annotation navigation
* allow exporting annotations to markdown
* remain entirely ephemeral

---

# V1 Constraints

Annotations are lost if:

* Neovim exits
* buffer unloads
* buffer is deleted

This is acceptable for V1.

The plugin assumes:

* active coding session
* loaded buffers
* temporary workflows

---

# Why Extmarks

Extmarks provide:

* range tracking across edits
* automatic positional updates
* metadata attachment
* visual decoration primitives

They are ideal for:

* live code annotations
* evolving code regions
* editor-native overlays

---

# Repository Structure

```txt
relay.nvim/
├── README.md
├── plugin/
│   └── relay.lua
└── lua/
    └── relay/
        ├── init.lua
        ├── config.lua
        ├── namespace.lua
        ├── annotations.lua
        ├── selection.lua
        ├── navigation.lua
        ├── ui.lua
        ├── export.lua
        └── utils.lua
```

---

# Module Responsibilities

## plugin/relay.lua

Registers:

* commands
* keymaps

Minimal bootstrap only.

---

## init.lua

Public API.

Example:

```lua
require("relay").setup({})
```

---

## config.lua

Handles:

* defaults
* user configuration merging

Example:

```lua
{
  export_dir = "/tmp/relay",
  highlight_group = "Visual",
  show_virtual_text = false,
  sign_text = "●",
}
```

---

## namespace.lua

Creates/exposes plugin namespace.

Example:

```lua
local ns = vim.api.nvim_create_namespace("relay")
```

---

## annotations.lua

Core extmark logic.

Responsibilities:

* create annotations
* update annotations
* delete annotations
* clear all annotations
* query annotations
* attach metadata
* resolve extmark ranges
* find annotation under cursor

This is the heart of V1.

---

## selection.lua

Handles:

* visual selection extraction
* range normalization
* buffer/file info

---

## navigation.lua

Handles:

* next annotation
* previous annotation
* cross-buffer navigation
* annotation sorting

---

## ui.lua

Handles visual behavior:

* highlights
* sign column markers
* virtual text
* prompts
* notifications

---

## export.lua

Responsible for:

* gathering annotations
* resolving current buffer text
* markdown generation
* temp file creation
* clipboard integration

---

## utils.lua

Shared helpers:

* path helpers
* timestamps
* buffer utilities

---

# Extmark Data Model

Example:

```lua
{
  id = extmark_id,
  bufnr = 12,
  start_row = 40,
  end_row = 48,
  note = "render skeleton instead"
}
```

Stored in:

* extmark metadata
* not Lua state

---

# Annotation Lifecycle

## Create Annotation

Flow:

```text
1. User selects code
2. Trigger :RelayAdd
3. Prompt for note
4. Create extmark
5. Attach metadata
6. Render visuals
```

---

## Edit Annotation

Flow:

```text
1. Cursor inside annotated region
2. Trigger :RelayEdit
3. Find extmark under cursor
4. Read current range + metadata
5. Open input prefilled with current note
6. Delete old extmark
7. Recreate extmark using SAME live range
```

Important:

* extmarks are dynamically updated by Neovim
* edit operation uses CURRENT resolved range
* not original stale range

---

## Delete Annotation

Flow:

```text
1. Cursor inside annotation
2. Trigger :RelayDelete
3. Find extmark under cursor
4. Delete extmark
```

---

## Delete All Annotations

Flow:

```text
clear namespace
```

---

# Finding Annotation Under Cursor

V1 requires helper:

```lua
annotations.find_at_cursor()
```

Responsibilities:

* get cursor position
* query extmarks in namespace
* find matching annotation range
* return annotation metadata

This helper powers:

* edit
* delete
* future interactions

---

# Visual Feedback

## Highlighted Range

Annotated ranges should visually stand out.

Initial implementation:

* lightweight highlight group

---

## Sign Column Marker

Each annotation should display:

* sign/gutter marker

Similar to:

* GitSigns
* diagnostics
* breakpoints

Purpose:

* lightweight awareness
* minimal visual noise

Configurable:

```lua
sign_text = "●"
```

---

## Virtual Text

Optional inline note rendering.

Example:

```text
render skeleton instead
```

Should:

* be toggleable
* default OFF
* remain minimal/non-intrusive

Recommended:

* truncated first line only

---

# Toggle Virtual Text

Command/mapping:

```vim
<leader>rt
```

Behavior:

* toggle inline annotation text visibility

---

# Navigation

Users should be able to cycle through annotations.

Example mappings:

```vim
]r  -> next annotation
[r  -> previous annotation
```

Navigation should support:

* current buffer
* all loaded buffers

Implementation:

* query extmarks
* sort by buffer + position
* jump cursor

---

# Export Format

V1 exports markdown.

Example:

````md
# Relay Context

Generated: 2026-05-20 14:20

## src/components/UserMenu.tsx:44-50

```tsx
if (loading) {
  return null
}
```

Comment:
render skeleton instead

---

## src/hooks/useAuth.ts:10-24

```ts
const login = () => {
}
```

Comment:
should probably be async
````

---

# Commands

## Add Annotation

```vim
:RelayAdd
```

Expected usage:

* visual mode

---

## Edit Annotation

```vim
:RelayEdit
```

Behavior:

* edit annotation under cursor

---

## Delete Annotation

```vim
:RelayDelete
```

Behavior:

* delete annotation under cursor

---

## Export

```vim
:RelayExport
```

Behavior:

* generate markdown
* write temp file
* copy filepath to clipboard

---

## Clear All

```vim
:RelayClear
```

Behavior:

* remove all plugin extmarks

---

## Toggle Inline Text

```vim
:RelayToggleText
```

Behavior:

* show/hide virtual text

---

## Navigation

```vim
:RelayNext
:RelayPrev
```

Behavior:

* navigate between annotations

---

# Suggested Keymaps

```lua
vim.keymap.set("v", "<leader>ra", "<cmd>RelayAdd<cr>")

vim.keymap.set("n", "<leader>re", "<cmd>RelayEdit<cr>")
vim.keymap.set("n", "<leader>rd", "<cmd>RelayDelete<cr>")
vim.keymap.set("n", "<leader>rD", "<cmd>RelayClear<cr>")

vim.keymap.set("n", "<leader>rt", "<cmd>RelayToggleText<cr>")

vim.keymap.set("n", "]r", "<cmd>RelayNext<cr>")
vim.keymap.set("n", "[r", "<cmd>RelayPrev<cr>")

vim.keymap.set("n", "<leader>rx", "<cmd>RelayExport<cr>")
```

---

# V2 Direction

## Goal

Add recovery/persistence without changing the V1 interaction model.

---

# V2 Additions

## Lua Persistence Layer

Persist:

* annotation metadata
* file paths
* ranges
* notes

Used ONLY for:

* recovery
* rebuilding extmarks

NOT as active runtime source of truth.

---

# V2 Recovery Flow

On startup:

* load persisted annotations
* recreate extmarks
* restore visuals

---

# V2 Important Rule

Extmarks remain authoritative during runtime.

Persistence layer is:

* snapshot/recovery only

This avoids synchronization complexity.

---

# Future Ideas (Not Planned Yet)

Possible future extensions:

* Telescope picker
* annotation browser
* inline editing panel
* annotation preview popup
* Git-aware exports
* diagnostics integration
* diff-aware exports
* direct Codex/Claude/Aider integrations
* workspace sessions
* floating annotation panel

These are intentionally excluded from V1/V2 scope.

---

# Non-Goals

The plugin should NOT become:

* Jira
* Notion
* Linear
* AI IDE framework
* spec-driven planning system

The plugin exists to:

* annotate code quickly
* build contextual prompts
* stay lightweight
* stay fast
* stay ephemeral
