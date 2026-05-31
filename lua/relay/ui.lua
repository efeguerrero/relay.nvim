local config = require("relay.config")
local M = {}

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok then
    return hl
  end

  return {}
end

local function relay_background()
  local visual = get_hl("Visual")
  if visual.bg then
    return visual.bg
  end

  local cursorline = get_hl("CursorLine")
  return cursorline.bg
end

function M.setup_highlights()
  local bg = relay_background()
  local diagnostic = get_hl("DiagnosticInfo")
  local hint = get_hl("DiagnosticHint")

  vim.api.nvim_set_hl(0, "RelayAnnotation", { bg = bg, default = true })
  vim.api.nvim_set_hl(0, "RelayAnnotationSign", { fg = hint.fg, bg = bg, default = true })
  vim.api.nvim_set_hl(0, "RelayAnnotationText", { fg = diagnostic.fg, bg = bg, italic = true, default = true })
end

local function note_virtual_lines(note)
  local lines = vim.split(note, "\n", { plain = true })
  local virtual_lines = {}

  for index, line in ipairs(lines) do
    local prefix = index == 1 and "Relay: " or "       "
    table.insert(virtual_lines, { { prefix .. line, "RelayAnnotationText" } })
  end

  return virtual_lines
end

function M.extmark_opts(note)
  local opts = config.options
  local extmark_opts = {
    hl_group = opts.highlight_group,
    end_right_gravity = true,
    right_gravity = true,
    sign_text = opts.sign_text,
    sign_hl_group = "RelayAnnotationSign",
    url = note,
  }

  if opts.show_virtual_text then
    extmark_opts.virt_lines = note_virtual_lines(note)
    extmark_opts.virt_lines_above = true
    extmark_opts.virt_lines_overflow = "scroll"
  end

  return extmark_opts
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
  vim.keymap.set("n", "<leader>rp", "<cmd>RelayPreview<cr>", { desc = "Relay preview context" })
  vim.keymap.set("n", "<leader>cr", "<cmd>RelayQuickfix<cr>", { desc = "Relay add references to quickfix" })
  vim.keymap.set("n", "<leader>rx", "<cmd>RelayExport<cr>", { desc = "Relay export annotations" })
end

return M
