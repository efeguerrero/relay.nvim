local config = require("relay.config")
local utils = require("relay.utils")

local M = {}

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "RelayAnnotation", { link = "Visual", default = true })
  vim.api.nvim_set_hl(0, "RelayAnnotationSign", { link = "DiagnosticHint", default = true })
  vim.api.nvim_set_hl(0, "RelayAnnotationText", { link = "Comment", default = true })
end

function M.extmark_opts(note)
  local opts = config.options
  local extmark_opts = {
    hl_group = opts.highlight_group,
    end_right_gravity = true,
    right_gravity = false,
    sign_text = opts.sign_text,
    sign_hl_group = "RelayAnnotationSign",
    user_data = { note = note },
  }

  if opts.show_virtual_text then
    extmark_opts.virt_text = { { utils.first_line(note), "RelayAnnotationText" } }
    extmark_opts.virt_text_pos = "eol"
  end

  return extmark_opts
end

function M.input(prompt, default, callback)
  vim.ui.input({ prompt = prompt, default = default or "" }, function(value)
    if value == nil then
      return
    end

    callback(value)
  end)
end

function M.keymaps()
  if not config.options.keymaps then
    return
  end

  vim.keymap.set("v", "<leader>ra", "<cmd>RelayAdd<cr>", { desc = "Relay add annotation" })
  vim.keymap.set("n", "<leader>re", "<cmd>RelayEdit<cr>", { desc = "Relay edit annotation" })
  vim.keymap.set("n", "<leader>rd", "<cmd>RelayDelete<cr>", { desc = "Relay delete annotation" })
  vim.keymap.set("n", "<leader>rD", "<cmd>RelayClear<cr>", { desc = "Relay clear annotations" })
  vim.keymap.set("n", "<leader>rt", "<cmd>RelayToggleText<cr>", { desc = "Relay toggle inline text" })
  vim.keymap.set("n", "]r", "<cmd>RelayNext<cr>", { desc = "Relay next annotation" })
  vim.keymap.set("n", "[r", "<cmd>RelayPrev<cr>", { desc = "Relay previous annotation" })
  vim.keymap.set("n", "<leader>rx", "<cmd>RelayExport<cr>", { desc = "Relay export annotations" })
end

return M

