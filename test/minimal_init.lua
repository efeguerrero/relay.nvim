vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false

require("relay").setup({
  keymaps = false,
  export_dir = vim.fn.getcwd() .. "/tmp",
})
