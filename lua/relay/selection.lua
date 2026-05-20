local M = {}

local function mark_pos(mark)
  local pos = vim.fn.getpos(mark)
  return {
    row = pos[2] - 1,
    col = math.max(pos[3] - 1, 0),
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
  local start_pos, end_pos = M.normalize(mark_pos("'<"), mark_pos("'>"))
  local line = vim.api.nvim_buf_get_lines(bufnr, end_pos.row, end_pos.row + 1, false)[1] or ""
  local end_col = math.min(end_pos.col + 1, #line)

  if end_col <= start_pos.col and start_pos.row == end_pos.row then
    end_col = math.min(start_pos.col + 1, #line)
  end

  return {
    bufnr = bufnr,
    start_row = start_pos.row,
    start_col = start_pos.col,
    end_row = end_pos.row,
    end_col = end_col,
  }
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

