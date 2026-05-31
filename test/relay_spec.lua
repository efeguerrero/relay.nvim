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
  "return greet('relay')",
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

vim.api.nvim_win_set_cursor(0, { 3, 80 })
local found_by_line = annotations.find_at_cursor()
assert_truthy(found_by_line, "multiline annotation should be found by line even when cursor is past end_col")
assert_equal(found_by_line.id, id, "line-based lookup should find the multiline annotation")

relay.edit("return a table")
assert_equal(annotations.all(bufnr)[1].note, "return a table", "edit should update metadata")

local enabled = relay.toggle_text()
assert_equal(enabled, true, "toggle should enable annotation text")
local details = vim.api.nvim_buf_get_extmarks(bufnr, require("relay.namespace").id, 0, -1, { details = true })[1][4]
assert_truthy(details.virt_lines, "virtual lines should be rendered when annotation text is enabled")
assert_equal(details.virt_lines_above, true, "annotation text should render above the annotated range")
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

local third_id = annotations.create({
  bufnr = bufnr,
  start_row = 3,
  start_col = 0,
  end_row = 3,
  end_col = 19,
}, "check ending")

vim.api.nvim_set_current_buf(bufnr)
vim.api.nvim_win_set_cursor(0, { 2, 4 })
local next_from_inside = relay.next()
assert_truthy(next_from_inside, "next navigation from inside an annotation should return an annotation")
assert_equal(next_from_inside.id, third_id, "next navigation from inside an annotation should move to the next annotation in the current buffer")

vim.api.nvim_win_set_cursor(0, { 4, 1 })
local prev_from_inside_same_buffer = relay.prev()
assert_truthy(prev_from_inside_same_buffer, "previous navigation from inside a same-buffer annotation should return an annotation")
assert_equal(prev_from_inside_same_buffer.id, id, "previous navigation from inside an annotation should move to the previous annotation in the current buffer")

vim.api.nvim_set_current_buf(second)
vim.api.nvim_win_set_cursor(0, { 1, 4 })
local prev_from_inside = relay.prev()
assert_truthy(prev_from_inside, "previous navigation from inside an annotation should return an annotation")
assert_equal(prev_from_inside.bufnr, second, "previous navigation with one current-buffer annotation should stay in the current buffer")

vim.api.nvim_set_current_buf(bufnr)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local next_annotation = relay.next()
assert_truthy(next_annotation, "next navigation should return an annotation")
assert_equal(vim.api.nvim_get_current_buf(), bufnr, "next navigation should visit first annotation in current buffer")

vim.api.nvim_set_current_buf(second)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local prev_annotation = relay.prev()
assert_truthy(prev_annotation, "previous navigation should return an annotation")
assert_equal(prev_annotation.bufnr, second, "previous navigation should prefer annotations in the current buffer")

local quickfix_items = relay.quickfix()
local quickfix = vim.fn.getqflist({ title = 1, items = 1 })
assert_equal(#quickfix_items, 3, "quickfix should include every annotation")
assert_equal(quickfix.title, "Relay references", "quickfix should use a Relay title")
assert_equal(quickfix.items[1].bufnr, bufnr, "quickfix should use sorted annotations")
assert_equal(quickfix.items[1].lnum, 2, "quickfix line should use one-based indexing")
assert_equal(quickfix.items[1].col, 1, "quickfix column should use one-based indexing")
assert_equal(quickfix.items[1].end_lnum, 3, "quickfix end line should use one-based indexing")
assert_equal(quickfix.items[1].end_col, shifted.end_col + 1, "quickfix end column should use one-based indexing")
assert_equal(quickfix.items[1].text, "return a table", "quickfix text should include the annotation note")
vim.cmd("cfirst")
assert_equal(vim.api.nvim_get_current_buf(), bufnr, "quickfix navigation should jump to the first annotation buffer")
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 2, "quickfix navigation should jump to the first annotation line")
vim.cmd("cnext")
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 4, "quickfix navigation should cycle to the next annotation")

local markdown = exporter.generate()
assert_truthy(markdown:find("# Relay Context", 1, true), "export should include title")
assert_truthy(markdown:find("fixture.lua:2%-3"), "export should include shifted fixture range")
assert_truthy(markdown:find("return a table", 1, true), "export should include edited comment")
assert_truthy(markdown:find("other.lua:1%-1"), "export should include second buffer")

local path = relay.export()
assert_truthy(vim.fn.filereadable(path) == 1, "export should write a markdown file")
assert_truthy(path:find("/tmp/context%.md$") ~= nil, "export should use the stable context filename")

vim.fn.writefile({ "existing export" }, path)
local preview_win = relay.preview()
local preview_buf = vim.api.nvim_win_get_buf(preview_win)
local preview_text = table.concat(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), "\n")
assert_truthy(vim.api.nvim_win_is_valid(preview_win), "preview should open a floating window")
assert_equal(vim.api.nvim_buf_get_name(preview_buf), "relay://preview", "preview should use a named scratch buffer")
assert_equal(vim.bo[preview_buf].filetype, "markdown", "preview should use markdown filetype")
assert_equal(vim.bo[preview_buf].buftype, "nofile", "preview should not edit the exported file")
assert_equal(vim.bo[preview_buf].modifiable, false, "preview should be read-only")
assert_truthy(preview_text:find("return a table", 1, true), "preview should include generated annotations")
assert_equal(vim.fn.readfile(path)[1], "existing export", "preview should not rewrite the exported file")
relay.previewer.close()

annotations.update(annotations.all(bufnr)[1], "preview refreshed comment")
preview_win = relay.preview()
preview_buf = vim.api.nvim_win_get_buf(preview_win)
preview_text = table.concat(vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false), "\n")
assert_truthy(preview_text:find("preview refreshed comment", 1, true), "preview should refresh from extmark metadata")
relay.previewer.close()

vim.api.nvim_set_current_buf(bufnr)
vim.api.nvim_win_set_cursor(0, { 2, 2 })
assert_equal(relay.delete(), true, "delete should remove annotation under cursor")
assert_equal(#annotations.all(bufnr), 1, "annotation under cursor should be deleted")

relay.clear()
assert_equal(#annotations.all(), 0, "clear should remove every annotation")
assert_equal(#relay.quickfix(), 0, "quickfix should support clearing the list when no annotations remain")
assert_equal(#vim.fn.getqflist(), 0, "empty quickfix population should clear existing entries")

finish()
