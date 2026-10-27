local annotations = require("relay.annotations")
local navigation = require("relay.navigation")
local utils = require("relay.utils")

local M = {}

function M.open()
  local ok, fzf_lua = pcall(require, "fzf-lua")
  if not ok then
    utils.notify("RelayFzf requires fzf-lua to be installed", vim.log.levels.WARN)
    return false
  end

  local items = navigation.sorted()
  if #items == 0 then
    utils.notify("No Relay annotations", vim.log.levels.WARN)
    return false
  end

  local entries = {}
  local items_by_entry = {}
  for _, annotation in ipairs(items) do
    local entry = ("%s:%d:%d"):format(
      utils.buf_path(annotation.bufnr),
      annotation.start_row + 1,
      annotation.start_col + 1
    )
    table.insert(entries, entry)
    -- Identical locations are indistinguishable in the picker and jump to the same place.
    items_by_entry[entry] = items_by_entry[entry] or annotation
  end

  return fzf_lua.fzf_exec(entries, {
    prompt = "Relay annotations> ",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        local item = selected and items_by_entry[selected[1]]
        local annotation = item and annotations.get(item.bufnr, item.id)
        if annotation then
          navigation.jump(annotation)
        end
      end,
    },
  })
end

return M
