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
  export_dir = vim.fn.stdpath("cache") .. "/relay",
  highlight_group = "RelayAnnotation",
  show_virtual_text = false,
  sign_text = "*",
  keymaps = true,
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
vim.keymap.set("n", "<leader>rx", "<cmd>RelayExport<cr>")
```

Set `keymaps = false` to skip default mappings.

## Development

Run the headless test suite:

```sh
nvim --headless -u test/minimal_init.lua -i NONE -c 'luafile test/relay_spec.lua' -c 'qa'
```

