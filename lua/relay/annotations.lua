local config = require("relay.config")
local namespace = require("relay.namespace")
local selection = require("relay.selection")
local ui = require("relay.ui")

local M = {}

local function extmark_to_annotation(bufnr, mark)
  local id = mark[1]
  local row = mark[2]
  local col = mark[3]
  local details = mark[4] or {}

  return {
    id = id,
    bufnr = bufnr,
    start_row = row,
    start_col = col,
    end_row = details.end_row or row,
    end_col = details.end_col or col,
    note = details.url or "",
  }
end

local function set_extmark(range, note, id)
  local opts = ui.extmark_opts(note)
  opts.end_row = range.end_row
  opts.end_col = range.end_col
  opts.strict = false
  if id then
    opts.id = id
  end

  return vim.api.nvim_buf_set_extmark(
    range.bufnr,
    namespace.id,
    range.start_row,
    range.start_col,
    opts
  )
end

local function contains_position(annotation, row, col)
  if row < annotation.start_row or row > annotation.end_row then
    return false
  end

  if annotation.start_row ~= annotation.end_row then
    return true
  end

  return col >= annotation.start_col and col <= annotation.end_col
end

function M.create(range, note)
  vim.validate("range", range, "table")
  vim.validate("note", note, "string")

  if note == "" then
    return nil
  end

  return set_extmark(range, note)
end

function M.create_from_visual(note)
  return M.create(selection.visual_range(), note)
end

function M.update(annotation, note)
  vim.validate("annotation", annotation, "table")
  vim.validate("note", note, "string")

  local range = {
    bufnr = annotation.bufnr,
    start_row = annotation.start_row,
    start_col = annotation.start_col,
    end_row = annotation.end_row,
    end_col = annotation.end_col,
  }

  return set_extmark(range, note, annotation.id)
end

function M.delete(annotation)
  vim.validate("annotation", annotation, "table")
  return vim.api.nvim_buf_del_extmark(annotation.bufnr, namespace.id, annotation.id)
end

function M.clear(bufnr)
  if bufnr then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace.id, 0, -1)
    return
  end

  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) then
      vim.api.nvim_buf_clear_namespace(buffer, namespace.id, 0, -1)
    end
  end
end

function M.all(bufnr)
  local buffers = bufnr and { bufnr } or vim.api.nvim_list_bufs()
  local annotations = {}

  for _, buffer in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buffer) then
      local marks = vim.api.nvim_buf_get_extmarks(buffer, namespace.id, 0, -1, { details = true })
      for _, mark in ipairs(marks) do
        table.insert(annotations, extmark_to_annotation(buffer, mark))
      end
    end
  end

  return annotations
end

function M.get(bufnr, id)
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace.id, id, id, { details = true })
  if marks[1] == nil then
    return nil
  end
  return extmark_to_annotation(bufnr, marks[1])
end

function M.find_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  for _, annotation in ipairs(M.all(bufnr)) do
    if contains_position(annotation, row, col) then
      return annotation
    end
  end

  return nil
end

function M.refresh_visuals()
  for _, annotation in ipairs(M.all()) do
    M.update(annotation, annotation.note)
  end
end

function M.toggle_text()
  config.options.show_virtual_text = not config.options.show_virtual_text
  M.refresh_visuals()
  return config.options.show_virtual_text
end

return M
