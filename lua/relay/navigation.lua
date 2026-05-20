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

local function annotation_is_after_cursor(item, bufnr, row, col)
  if item.bufnr ~= bufnr then
    return item.bufnr > bufnr
  end

  return item.start_row > row or (item.start_row == row and item.start_col > col)
end

local function annotation_is_before_cursor(item, bufnr, row, col)
  if item.bufnr ~= bufnr then
    return item.bufnr < bufnr
  end

  return item.start_row < row or (item.start_row == row and item.start_col < col)
end

local function same_annotation(left, right)
  return left
    and right
    and left.bufnr == right.bufnr
    and left.id == right.id
end

local function current_buffer_items(items)
  local bufnr = vim.api.nvim_get_current_buf()
  local filtered = {}

  for _, item in ipairs(items) do
    if item.bufnr == bufnr then
      table.insert(filtered, item)
    end
  end

  return filtered
end

local function current_annotation_index(items, current)
  current = current or annotations.find_at_cursor()
  if not current then
    return nil
  end

  for index, item in ipairs(items) do
    if same_annotation(item, current) then
      return index
    end
  end

  return nil
end

local function navigation_items(items)
  local buffer_items = current_buffer_items(items)
  if #buffer_items > 0 then
    return buffer_items
  end

  return items
end

local function next_index(items)
  local current = current_annotation_index(items)
  if current then
    return current == #items and 1 or current + 1
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  for index, item in ipairs(items) do
    if annotation_is_after_cursor(item, bufnr, row, col) then
      return index
    end
  end

  return 1
end

local function prev_index(items)
  local current = current_annotation_index(items)
  if current then
    return current == 1 and #items or current - 1
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  for index = #items, 1, -1 do
    if annotation_is_before_cursor(items[index], bufnr, row, col) then
      return index
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
  local items = navigation_items(annotations.all())
  if #items == 0 then
    return nil
  end

  sort_annotations(items)
  local index = next_index(items)
  jump(items[index])
  return items[index]
end

function M.prev()
  local items = navigation_items(annotations.all())
  if #items == 0 then
    return nil
  end

  sort_annotations(items)
  local index = prev_index(items)
  jump(items[index])
  return items[index]
end

function M.sorted()
  local items = annotations.all()
  sort_annotations(items)
  return items
end

function M.debug_state()
  local items = navigation_items(annotations.all())
  sort_annotations(items)

  local cursor = vim.api.nvim_win_get_cursor(0)
  local current = annotations.find_at_cursor()
  local current_index = current_annotation_index(items, current)
  local next = #items > 0 and items[next_index(items)] or nil
  local prev = #items > 0 and items[prev_index(items)] or nil

  return {
    bufnr = vim.api.nvim_get_current_buf(),
    cursor = {
      row = cursor[1] - 1,
      col = cursor[2],
    },
    current = current,
    current_index = current_index,
    next = next,
    prev = prev,
    items = items,
  }
end

return M
