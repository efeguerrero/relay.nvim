local config = require("relay.config")

local M = {}

local state = nil

local function valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function valid_window(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function size(value, total, margin)
  local resolved = value
  if value > 0 and value <= 1 then
    resolved = math.floor(total * value)
  end

  return math.max(1, math.min(math.floor(resolved), math.max(1, total - margin)))
end

local function editor_width()
  return size(config.options.note_editor.width, vim.o.columns, 4)
end

local function max_height()
  return size(config.options.note_editor.max_height, vim.o.lines, 4)
end

local function content_height(bufnr, width)
  local height = 0

  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    height = height + math.max(1, math.ceil(vim.api.nvim_strwidth(line) / width))
  end

  return height
end

local function window_config(bufnr)
  local opts = config.options.note_editor
  local width = editor_width()
  local maximum_height = max_height()
  local height = math.max(opts.min_height, content_height(bufnr, width))
  height = math.min(height, maximum_height)

  return {
    relative = "editor",
    style = "minimal",
    border = opts.border,
    title = " Relay note ",
    title_pos = "center",
    footer = " Enter save  Shift-Enter newline  Esc/Ctrl-C cancel ",
    footer_pos = "center",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - maximum_height) / 2),
  }
end

local function restore_window(session)
  if valid_window(session.parent_winid) then
    vim.api.nvim_set_current_win(session.parent_winid)
  end
end

local function finish(session, value, close_window)
  if state ~= session then
    return
  end

  state = nil
  if session.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, session.augroup)
  end
  if close_window and valid_window(session.winid) then
    vim.api.nvim_win_close(session.winid, true)
  end
  if valid_buffer(session.bufnr) then
    vim.api.nvim_buf_delete(session.bufnr, { force = true })
  end

  restore_window(session)
  if value == nil then
    if session.on_cancel then
      session.on_cancel()
    end
  else
    session.on_submit(value)
  end
end

function M.resize()
  if state and valid_window(state.winid) and valid_buffer(state.bufnr) then
    vim.api.nvim_win_set_config(state.winid, window_config(state.bufnr))
  end
end

function M.submit()
  if not state or not valid_buffer(state.bufnr) then
    return
  end

  local session = state
  local value = vim.fn.prompt_getinput(session.bufnr)
  finish(session, value, true)
end

function M.cancel()
  if state then
    finish(state, nil, true)
  end
end

local function set_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set({ "i", "n" }, "<CR>", M.submit, vim.tbl_extend("force", opts, { desc = "Save Relay note" }))
  vim.keymap.set({ "i", "n" }, "<Esc>", M.cancel, vim.tbl_extend("force", opts, { desc = "Cancel Relay note" }))
  vim.keymap.set({ "i", "n" }, "<C-c>", M.cancel, vim.tbl_extend("force", opts, { desc = "Cancel Relay note" }))
end

local function create_buffer(default)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "relay://note")
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].buftype = "prompt"
  vim.bo[bufnr].filetype = "relay_note"
  vim.bo[bufnr].swapfile = false
  vim.fn.prompt_setprompt(bufnr, "")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(default or "", "\n", { plain = true }))
  set_keymaps(bufnr)
  return bufnr
end

local function configure_window(winid)
  vim.wo[winid].wrap = true
  vim.wo[winid].linebreak = true
  vim.wo[winid].cursorline = true
end

function M.open(opts)
  vim.validate("opts", opts, "table")
  vim.validate("opts.on_submit", opts.on_submit, "function")

  M.cancel()

  local session = {
    parent_winid = vim.api.nvim_get_current_win(),
    on_submit = opts.on_submit,
    on_cancel = opts.on_cancel,
  }
  session.bufnr = create_buffer(opts.default)
  session.winid = vim.api.nvim_open_win(session.bufnr, true, window_config(session.bufnr))
  session.augroup = vim.api.nvim_create_augroup("relay.note_editor", { clear = true })
  state = session

  configure_window(session.winid)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = session.augroup,
    buffer = session.bufnr,
    callback = M.resize,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = session.augroup,
    pattern = tostring(session.winid),
    callback = function()
      vim.schedule(function()
        finish(session, nil, false)
      end)
    end,
  })

  vim.api.nvim_win_set_cursor(session.winid, { vim.api.nvim_buf_line_count(session.bufnr), 0 })
  vim.cmd("startinsert!")
  return session.winid
end

function M.state()
  return state
end

return M
