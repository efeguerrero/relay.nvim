local M = {}

M.defaults = {
  export_dir = vim.fn.stdpath("cache") .. "/relay",
  highlight_group = "RelayAnnotation",
  sign_text = "*",
  show_virtual_text = false,
  keymaps = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M

