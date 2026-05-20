local annotations = require("relay.annotations")

local M = {}

local function sort_annotations(items)
  table.sort(items, function(a, b)
    if a.bufnr ~= b.bufnr then
      return a.bufnr < b.bufnr
    end
    if a.start_row ~= b.start_row then
      return a.start_row < b.start_row
    end
    return a.start_col < b.start_col
  end)
end

local function current_index(items)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  for index, item in ipairs(items) do
    if item.bufnr == bufnr and (item.start_row > row or (item.start_row == row and item.start_col > col)) then
      return index - 1
    end
  end

  return #items
end

local function jump(annotation)
  if vim.api.nvim_get_current_buf() ~= annotation.bufnr then
    vim.api.nvim_set_current_buf(annotation.bufnr)
  end
  vim.api.nvim_win_set_cursor(0, { annotation.start_row + 1, annotation.start_col })
end

function M.next()
  local items = annotations.all()
  if #items == 0 then
    return nil
  end

  sort_annotations(items)
  local index = current_index(items) + 1
  if index > #items then
    index = 1
  end

  jump(items[index])
  return items[index]
end

function M.prev()
  local items = annotations.all()
  if #items == 0 then
    return nil
  end

  sort_annotations(items)
  local index = current_index(items)
  if index < 1 then
    index = #items
  end

  jump(items[index])
  return items[index]
end

function M.sorted()
  local items = annotations.all()
  sort_annotations(items)
  return items
end

return M

