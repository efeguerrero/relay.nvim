local annotations = require("relay.annotations")
local config = require("relay.config")
local export = require("relay.export")
local navigation = require("relay.navigation")
local preview = require("relay.preview")
local quickfix = require("relay.quickfix")
local selection = require("relay.selection")
local ui = require("relay.ui")
local utils = require("relay.utils")

local M = {}

function M.setup(opts)
  config.setup(opts)
  ui.setup_highlights()
  ui.keymaps()
end

function M.add(note)
  if note then
    local id = annotations.create_from_visual(note)
    if id then
      utils.notify("Annotation added")
    end
    return id
  end

  local range = selection.visual_range()
  local highlight = selection.highlight(range)
  ui.input("Relay note: ", "", function(value)
    selection.clear_highlight(highlight)
    local id = annotations.create(range, value)
    if id then
      utils.notify("Annotation added")
    end
  end, function()
    selection.clear_highlight(highlight)
  end)
end

function M.edit(note)
  local annotation = annotations.find_at_cursor()
  if not annotation then
    utils.notify("No Relay annotation under cursor", vim.log.levels.WARN)
    return nil
  end

  if note then
    annotations.update(annotation, note)
    utils.notify("Annotation updated")
    return annotation.id
  end

  ui.input("Relay note: ", annotation.note, function(value)
    annotations.update(annotation, value)
    utils.notify("Annotation updated")
  end)
end

function M.delete()
  local annotation = annotations.find_at_cursor()
  if not annotation then
    utils.notify("No Relay annotation under cursor", vim.log.levels.WARN)
    return false
  end

  annotations.delete(annotation)
  utils.notify("Annotation deleted")
  return true
end

function M.clear()
  annotations.clear()
  utils.notify("All Relay annotations cleared")
end

function M.toggle_text()
  local enabled = annotations.toggle_text()
  utils.notify(enabled and "Relay annotation text enabled" or "Relay annotation text disabled")
  return enabled
end

function M.next()
  local annotation = navigation.next()
  if not annotation then
    utils.notify("No Relay annotations", vim.log.levels.WARN)
  end
  return annotation
end

function M.prev()
  local annotation = navigation.prev()
  if not annotation then
    utils.notify("No Relay annotations", vim.log.levels.WARN)
  end
  return annotation
end

function M.export()
  local path = export.write()
  utils.notify("Relay context exported: " .. path)
  return path
end

function M.preview()
  return preview.open()
end

function M.quickfix()
  local items = quickfix.populate()
  utils.notify(("%d Relay references added to quickfix"):format(#items))
  return items
end

function M.debug()
  local state = navigation.debug_state()
  print(vim.inspect(state))
  return state
end

M.annotations = annotations
M.exporter = export
M.navigation = navigation
M.previewer = preview
M.quickfix_list = quickfix

return M
