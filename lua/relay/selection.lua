local M = {}
local pending_namespace = vim.api.nvim_create_namespace("relay.pending_selection")

local function mark_pos(mark)
  local pos = vim.fn.getpos(mark)
  return {
    row = pos[2] - 1,
    col = math.max(pos[3] - 1, 0),
  }
end

local function visual_positions()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    return mark_pos("v"), mark_pos("."), mode
  end

  return mark_pos("'<"), mark_pos("'>"), vim.fn.visualmode()
end

local function clamp_position(bufnr, pos)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local row = math.min(math.max(pos.row, 0), line_count - 1)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

  return {
    row = row,
    col = math.min(pos.col, #line),
  }
end

function M.normalize(start_pos, end_pos)
  if start_pos.row > end_pos.row or (start_pos.row == end_pos.row and start_pos.col > end_pos.col) then
    start_pos, end_pos = end_pos, start_pos
  end

  return start_pos, end_pos
end

function M.visual_range(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local start_pos, end_pos, mode = visual_positions()
  start_pos = clamp_position(bufnr, start_pos)
  end_pos = clamp_position(bufnr, end_pos)
  start_pos, end_pos = M.normalize(start_pos, end_pos)
  local line = vim.api.nvim_buf_get_lines(bufnr, end_pos.row, end_pos.row + 1, false)[1] or ""
  local end_col = mode == "V" and #line or math.min(end_pos.col + 1, #line)

  if end_col <= start_pos.col and start_pos.row == end_pos.row then
    end_col = math.min(start_pos.col + 1, #line)
  end

  return {
    bufnr = bufnr,
    start_row = start_pos.row,
    start_col = mode == "V" and 0 or start_pos.col,
    end_row = end_pos.row,
    end_col = end_col,
  }
end

function M.highlight(range)
  return {
    bufnr = range.bufnr,
    id = vim.api.nvim_buf_set_extmark(range.bufnr, pending_namespace, range.start_row, range.start_col, {
      end_row = range.end_row,
      end_col = range.end_col,
      hl_group = "Visual",
      strict = false,
    }),
  }
end

function M.clear_highlight(mark)
  if mark and vim.api.nvim_buf_is_valid(mark.bufnr) then
    vim.api.nvim_buf_del_extmark(mark.bufnr, pending_namespace, mark.id)
  end
end

function M.current_file_info(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return {
    bufnr = bufnr,
    path = vim.api.nvim_buf_get_name(bufnr),
    filetype = vim.bo[bufnr].filetype,
  }
end

return M
