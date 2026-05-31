local config = require("relay.config")
local export = require("relay.export")

local M = {}

local state = {
  bufnr = nil,
  winid = nil,
}

local function valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_window(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function preview_size(value, total, margin)
  local size = value
  if value > 0 and value <= 1 then
    size = math.floor(total * value)
  end

  return math.max(1, math.min(math.floor(size), math.max(1, total - margin)))
end

local function window_config()
  local opts = config.options.preview
  local width = preview_size(opts.width, vim.o.columns, 4)
  local height = preview_size(opts.height, vim.o.lines, 4)

  return {
    relative = "editor",
    style = "minimal",
    border = opts.border,
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
  }
end

local function preview_buffer()
  if valid_buffer(state.bufnr) then
    return state.bufnr
  end

  state.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.bufnr, "relay://preview")
  vim.bo[state.bufnr].bufhidden = "hide"
  vim.bo[state.bufnr].filetype = "markdown"
  vim.bo[state.bufnr].swapfile = false
  vim.keymap.set("n", "q", M.close, { buffer = state.bufnr, desc = "Close Relay preview" })
  return state.bufnr
end

local function update_buffer(bufnr)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(export.generate(), "\n", { plain = true }))
  vim.bo[bufnr].modifiable = false
end

function M.close()
  if valid_window(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
  end
  state.winid = nil
end

function M.open()
  local bufnr = preview_buffer()
  update_buffer(bufnr)

  if valid_window(state.winid) then
    vim.api.nvim_win_set_config(state.winid, window_config())
    vim.api.nvim_set_current_win(state.winid)
    return state.winid
  end

  state.winid = vim.api.nvim_open_win(bufnr, true, window_config())
  return state.winid
end

return M
