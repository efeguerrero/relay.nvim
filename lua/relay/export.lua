local annotations = require("relay.annotations")
local config = require("relay.config")
local utils = require("relay.utils")

local M = {}

local function fence_for(bufnr)
  return vim.bo[bufnr].filetype or ""
end

local function annotation_text(annotation)
  return vim.api.nvim_buf_get_text(
    annotation.bufnr,
    annotation.start_row,
    annotation.start_col,
    annotation.end_row,
    annotation.end_col,
    {}
  )
end

local function markdown_for(annotation)
  local path = utils.buf_path(annotation.bufnr)
  local start_line = annotation.start_row + 1
  local end_line = annotation.end_row + 1
  local lines = annotation_text(annotation)
  local chunk = table.concat(lines, "\n")
  local fence = fence_for(annotation.bufnr)

  return table.concat({
    ("## %s:%d-%d"):format(path, start_line, end_line),
    "",
    ("```%s"):format(fence),
    chunk,
    "```",
    "",
    "Comment:",
    annotation.note,
    "",
    "---",
    "",
  }, "\n")
end

function M.generate()
  local items = require("relay.navigation").sorted()
  local lines = {
    "# Relay Context",
    "",
    "Generated: " .. utils.timestamp(),
    "",
  }

  for _, annotation in ipairs(items) do
    table.insert(lines, markdown_for(annotation))
  end

  return table.concat(lines, "\n")
end

function M.write()
  utils.ensure_dir(config.options.export_dir)
  local path = ("%s/relay-%s.md"):format(config.options.export_dir, os.date("%Y%m%d-%H%M%S"))
  local file = assert(io.open(path, "w"))
  file:write(M.generate())
  file:close()

  pcall(vim.fn.setreg, "+", path)
  return path
end

return M

