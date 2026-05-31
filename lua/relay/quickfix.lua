local navigation = require("relay.navigation")
local utils = require("relay.utils")

local M = {}

local function quickfix_item(annotation)
  return {
    bufnr = annotation.bufnr,
    lnum = annotation.start_row + 1,
    col = annotation.start_col + 1,
    end_lnum = annotation.end_row + 1,
    end_col = annotation.end_col + 1,
    text = utils.first_line(annotation.note),
  }
end

function M.populate()
  local items = {}

  for _, annotation in ipairs(navigation.sorted()) do
    table.insert(items, quickfix_item(annotation))
  end

  vim.fn.setqflist({}, "r", {
    title = "Relay references",
    items = items,
  })

  return items
end

return M
