local relay = require("relay")
local annotations = relay.annotations
local exporter = relay.exporter

local failures = {}

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, ("%s: expected %s, got %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function assert_truthy(value, message)
  if not value then
    table.insert(failures, message)
  end
end

local function fresh_buffer(name, lines, filetype)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_name(bufnr, vim.fn.getcwd() .. "/" .. name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = filetype or "lua"
  vim.bo[bufnr].modified = false
  return bufnr
end

local function finish()
  if #failures > 0 then
    error(table.concat(failures, "\n"))
  end
end

local bufnr = fresh_buffer("fixture.lua", {
  "local function greet(name)",
  "  return 'hello ' .. name",
  "end",
}, "lua")

local id = annotations.create({
  bufnr = bufnr,
  start_row = 0,
  start_col = 0,
  end_row = 1,
  end_col = 26,
}, "make greeting configurable")

assert_truthy(id, "annotation id should be created")

local all = annotations.all(bufnr)
assert_equal(#all, 1, "one annotation should exist")
assert_equal(all[1].note, "make greeting configurable", "annotation note should round-trip through extmark metadata")

vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { "-- inserted line" })
local shifted = annotations.all(bufnr)[1]
assert_equal(shifted.start_row, 1, "extmark should track inserted lines")

vim.api.nvim_win_set_cursor(0, { 2, 2 })
local found = annotations.find_at_cursor()
assert_truthy(found, "annotation should be found under cursor")
assert_equal(found.note, "make greeting configurable", "cursor lookup should return metadata")

relay.edit("return a table")
assert_equal(annotations.all(bufnr)[1].note, "return a table", "edit should update metadata")

local enabled = relay.toggle_text()
assert_equal(enabled, true, "toggle should enable annotation text")
local details = vim.api.nvim_buf_get_extmarks(bufnr, require("relay.namespace").id, 0, -1, { details = true })[1][4]
assert_truthy(details.virt_lines, "virtual lines should be rendered when annotation text is enabled")
assert_truthy(details.virt_lines[1][1][1]:find("return a table", 1, true), "virtual lines should render the full note")

local second = fresh_buffer("other.lua", {
  "local value = 1",
  "return value",
}, "lua")
annotations.create({
  bufnr = second,
  start_row = 0,
  start_col = 0,
  end_row = 0,
  end_col = 13,
}, "rename value")

vim.api.nvim_set_current_buf(bufnr)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local next_annotation = relay.next()
assert_truthy(next_annotation, "next navigation should return an annotation")
assert_equal(vim.api.nvim_get_current_buf(), bufnr, "next navigation should visit first annotation in current buffer")

vim.api.nvim_set_current_buf(second)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local prev_annotation = relay.prev()
assert_truthy(prev_annotation, "previous navigation should return an annotation")
assert_equal(prev_annotation.bufnr, bufnr, "previous navigation should move to the prior buffer annotation")

local markdown = exporter.generate()
assert_truthy(markdown:find("# Relay Context", 1, true), "export should include title")
assert_truthy(markdown:find("fixture.lua:2%-3"), "export should include shifted fixture range")
assert_truthy(markdown:find("return a table", 1, true), "export should include edited comment")
assert_truthy(markdown:find("other.lua:1%-1"), "export should include second buffer")

local path = relay.export()
assert_truthy(vim.fn.filereadable(path) == 1, "export should write a markdown file")

vim.api.nvim_set_current_buf(bufnr)
vim.api.nvim_win_set_cursor(0, { 2, 2 })
assert_equal(relay.delete(), true, "delete should remove annotation under cursor")
assert_equal(#annotations.all(bufnr), 0, "annotation should be deleted")

relay.clear()
assert_equal(#annotations.all(), 0, "clear should remove every annotation")

finish()
