
local M = {}

local parsers = require('nvim-treesitter.parsers')

local query = vim.treesitter.query.parse_query('cpp', [[(comment) @the-comment]])

local function warn(msg)
  vim.api.nvim_echo({{"[hone] "..msg, "WarningMsg"}}, true, {})
end

local function get_node_under_curser()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row-1
  local root = parsers.get_parser(bufnr):parse()[1]:root();
  return root:named_descendant_for_range(row, col, row, col)
end

local function iter_comment_nodes(start_row, end_row)
  local bufnr = vim.api.nvim_get_current_buf()
  local root = parsers.get_parser(bufnr):parse()[1]:root();
  return query:iter_captures(root, bufnr, start_row, end_row)
end

local function is_multi_comment(lines, idx, col)
  return lines[idx]:sub(col+2, col+2) == '*'
end

function M.inner_comment_textobj() 
  local node = get_node_under_curser()
  if node:type() ~= 'comment' then
    return
  end
  local row1, col1, row2, col2 = node:range()
  local lines = vim.api.nvim_buf_get_lines(0, row1, row2+1, true)
  if is_multi_comment(lines, 1, col1) then
    col2 = col2-2
    if col2 == 0 then
      col2 = lines[row2-row1]:len()
      row2 = row2-1
    end
  end
  col1 = col1+2
  vim.fn.execute("normal! vv")
  vim.api.nvim_buf_set_mark(0, '<', row1+1, col1, {})
  vim.api.nvim_buf_set_mark(0, '>', row2+1, col2-1, {})
  vim.fn.execute("normal! gv")
end

function M.outer_comment_textobj() 
  local node = get_node_under_curser()
  if node:type() ~= 'comment' then
    return
  end
  local row1, col1, row2, col2 = node:range()
  vim.fn.execute("normal! vv")
  vim.api.nvim_buf_set_mark(0, '<', row1+1, col1, {})
  vim.api.nvim_buf_set_mark(0, '>', row2+1, col2-1, {})
  vim.fn.execute("normal! gv")
end

function M.comment_linewise(start_row, end_row)
  for id, node in iter_comment_nodes(start_row, start_row+1) do
    local row1, col1, row2, col2 = node:range()
    if row1 < start_row then
      warn("intersects another comment")
      return
    end
  end
  for id, node in iter_comment_nodes(end_row, end_row+1) do
    local row1, col1, row2, col2 = node:range()
    if row2 > end_row then
      warn("intersects another comment")
      return
    end
  end

  local uncomment = true
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row+1, true)
  for i = 1, #lines do
    if not lines[i]:find('^%s*//') then
      uncomment = false
      break
    end
  end
  if uncomment then
    for i = 1, #lines do
      lines[i] = lines[i]:gsub('^%s*//', '', 1)
    end
  else
    for i = 1, #lines do
      lines[i] = "//"..lines[i]
    end
  end
  vim.api.nvim_buf_set_lines(0, start_row, end_row+1, true, lines)
end

function M.comment_charwise(start_row, start_col, end_row, end_col)
  for id, node in iter_comment_nodes(start_row, end_row+1) do
    local row1, col1, row2, col2 = node:range()
    if row1 <= start_row or row2 >= end_row then
      warn("intersects another comment")
      return
    end
    local lines = vim.api.nvim_buf_get_lines(0, row1, row1+1, true)
    if is_multi_comment(linex, 0, col1) then
      warn("intersects another comment")
      return
    end
  end
  if start_row == end_row then
    local line = vim.api.nvim_buf_get_lines(0, start_row, start_row+1, true)[1]
    line = line:sub(0, start_col)..'/*'..line:sub(start_col+1,end_col+1)..'*/'..line:sub(end_col+2)
    vim.api.nvim_buf_set_lines(0, start_row, start_row+1, true, {line})
  else
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row+1, true)
    lines[1] = lines[1]:sub(0, start_col)..'/*'..lines[1]:sub(start_col+1)
    lines[#lines] = lines[#lines]:sub(0, end_col+1)..'*/'..lines[#lines]:sub(end_col+2)
    vim.api.nvim_buf_set_lines(0, start_row, end_row+1, true, lines)
  end
end

local function can_join_node(node)
  if node:type() ~= 'comment' then
    return false
  end
  local row, col = node:start()
  local line = vim.api.nvim_buf_get_lines(0, row, row+1, true)[1]
  return line:find('^%s*//') == 1
end

local function extract(s, from, len)
  local tmp = ''
  if from ~= 1 then
    tmp = s:sub(1, from-1)
  end
  return tmp..s:sub(from+len)
end

function M.uncomment_under_cursor()
  local node = get_node_under_curser()
  if node:type() ~= 'comment' then
    return
  end

  local row1, col1, row2, col2 = node:range()

  local lines = vim.api.nvim_buf_get_lines(0, row1, row2+1, true)
  if is_multi_comment(lines, 1, col1) then
    if row2==row1 then 
      lines[1] = extract(lines[1], col2-1, 2)
      lines[1] = extract(lines[1], col1+1, 2)
    else
      lines[1] = extract(lines[1], col1+1, 2)
      lines[#lines] = extract(lines[#lines], col2-1, 2)
    end
    vim.api.nvim_buf_set_lines(0, row1, row2+1, true, lines)
  elseif col1 ~= 0 then
    lines[1] = extract(lines[1], col1+1, 2)
    vim.api.nvim_buf_set_lines(0, row1, row2+1, true, lines)
  else
    local tmp = node:prev_sibling() 
    while can_join_node(tmp) do
      local row, col = tmp:start()
      row1 = row
      tmp = tmp:prev_sibling()
    end
    tmp = node:next_sibling() 
    while can_join_node(tmp) do
      local row, col = tmp:start()
      row2 = row
      tmp = tmp:next_sibling()
    end
    lines = vim.api.nvim_buf_get_lines(0, row1, row2+1, true)
    for i = 1, #lines do
      lines[i] = lines[i]:gsub('^%s*//', '', 1)
    end
    vim.api.nvim_buf_set_lines(0, row1, row2+1, true, lines)
  end
end

return M
