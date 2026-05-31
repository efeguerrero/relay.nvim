if vim.g.loaded_relay == 1 then
  return
end
vim.g.loaded_relay = 1

local relay = require("relay")

vim.api.nvim_create_user_command("RelayAdd", function()
  relay.add()
end, { desc = "Add a Relay annotation", range = true })

vim.api.nvim_create_user_command("RelayEdit", function()
  relay.edit()
end, { desc = "Edit the Relay annotation under the cursor" })

vim.api.nvim_create_user_command("RelayDelete", function()
  relay.delete()
end, { desc = "Delete the Relay annotation under the cursor" })

vim.api.nvim_create_user_command("RelayClear", function()
  relay.clear()
end, { desc = "Clear all Relay annotations" })

vim.api.nvim_create_user_command("RelayToggleText", function()
  relay.toggle_text()
end, { desc = "Toggle Relay inline annotation text" })

vim.api.nvim_create_user_command("RelayNext", function()
  relay.next()
end, { desc = "Jump to the next Relay annotation" })

vim.api.nvim_create_user_command("RelayPrev", function()
  relay.prev()
end, { desc = "Jump to the previous Relay annotation" })

vim.api.nvim_create_user_command("RelayExport", function()
  relay.export()
end, { desc = "Export Relay annotations to markdown" })

vim.api.nvim_create_user_command("RelayPreview", function()
  relay.preview()
end, { desc = "Preview Relay annotations as markdown" })

vim.api.nvim_create_user_command("RelayQuickfix", function()
  relay.quickfix()
end, { desc = "Add Relay references to the quickfix list" })

vim.api.nvim_create_user_command("RelayDebug", function()
  relay.debug()
end, { desc = "Print Relay annotation debug state" })
