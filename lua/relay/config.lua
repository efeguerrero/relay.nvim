local M = {}

M.defaults = {
  export_dir = vim.fn.getcwd() .. "/.relay",
  export_filename = "context.md",
  highlight_group = "RelayAnnotation",
  sign_text = "*",
  show_virtual_text = false,
  keymaps = true,
  note_editor = {
    width = 0.6,
    min_height = 6,
    max_height = 0.4,
    border = "rounded",
  },
  preview = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
