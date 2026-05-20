local M = {}

function M.notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "relay.nvim" })
end

function M.buf_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end

  local cwd = vim.loop.cwd()
  if cwd and vim.startswith(name, cwd .. "/") then
    return name:sub(#cwd + 2)
  end

  return name
end

function M.timestamp()
  return os.date("%Y-%m-%d %H:%M")
end

function M.ensure_dir(path)
  vim.fn.mkdir(path, "p")
end

function M.first_line(text)
  local line = (text or ""):match("([^\n\r]*)") or ""
  if #line > 80 then
    return line:sub(1, 77) .. "..."
  end
  return line
end

return M

