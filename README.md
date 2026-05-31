# relay.nvim

`relay.nvim` is a lightweight Neovim plugin for building contextual AI prompts from code selections. It lets you annotate ranges in loaded buffers, navigate those annotations, and export the current context to markdown.

Annotations are intentionally ephemeral in V1. They live in Neovim extmarks and are lost when buffers unload or Neovim exits.

## Installation

Use your plugin manager of choice and call:

```lua
require("relay").setup()
```

Optional configuration:

```lua
require("relay").setup({
  export_dir = vim.fn.getcwd() .. "/.relay",
  export_filename = "context.md",
  highlight_group = "RelayAnnotation",
  show_virtual_text = false,
  sign_text = "*",
  keymaps = true,
  preview = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
  },
})
```

## Commands

| Command | Description |
| --- | --- |
| `:RelayAdd` | Add an annotation for the visual selection. |
| `:RelayEdit` | Edit the annotation under the cursor. |
| `:RelayDelete` | Delete the annotation under the cursor. |
| `:RelayClear` | Clear all annotations from loaded buffers. |
| `:RelayToggleText` | Toggle inline virtual text notes. |
| `:RelayNext` | Jump to the next annotation. |
| `:RelayPrev` | Jump to the previous annotation. |
| `:RelayPreview` | Open a read-only floating preview of the generated markdown. |
| `:RelayQuickfix` | Add all annotations to the quickfix list. |
| `:RelayExport` | Export annotations to markdown and copy the path to the clipboard. |

## Default Keymaps

```lua
vim.keymap.set("v", "<leader>ra", "<cmd>RelayAdd<cr>")
vim.keymap.set("n", "<leader>re", "<cmd>RelayEdit<cr>")
vim.keymap.set("n", "<leader>rd", "<cmd>RelayDelete<cr>")
vim.keymap.set("n", "<leader>rD", "<cmd>RelayClear<cr>")
vim.keymap.set("n", "<leader>rt", "<cmd>RelayToggleText<cr>")
vim.keymap.set("n", "]r", "<cmd>RelayNext<cr>")
vim.keymap.set("n", "[r", "<cmd>RelayPrev<cr>")
vim.keymap.set("n", "<leader>rp", "<cmd>RelayPreview<cr>")
vim.keymap.set("n", "<leader>cr", "<cmd>RelayQuickfix<cr>")
vim.keymap.set("n", "<leader>rx", "<cmd>RelayExport<cr>")
```

Set `keymaps = false` to skip default mappings.

## Development

Exports are written to `.relay/context.md` in the current working directory by default. Each export overwrites that file instead of creating timestamped markdown files.

`:RelayPreview` renders the current annotations in a read-only floating buffer without writing the export file. Use `q` to close the preview. `:RelayExport` writes the generated markdown file and copies its path to the clipboard.

`:RelayQuickfix` replaces the current quickfix list with all loaded Relay annotations. Use `:cnext` and `:cprev` to cycle through them, or `:copen` to inspect the list.

Run the headless test suite:

```sh
nvim --headless -u test/minimal_init.lua -i NONE -c 'luafile test/relay_spec.lua' -c 'qa!'
```
