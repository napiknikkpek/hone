onoremap <buffer> ic <Cmd>lua require('hone.cpp').inner_comment_textobj()<cr>
onoremap <buffer> ac <Cmd>lua require('hone.cpp').outer_comment_textobj()<cr>
vnoremap <buffer> ic <Cmd>lua require('hone.cpp').inner_comment_textobj()<cr>
vnoremap <buffer> ac <Cmd>lua require('hone.cpp').outer_comment_textobj()<cr>

fu! s:comment(mode)
  if a:mode == 'v'
lua << EOF
  local row1, col1 = unpack(vim.api.nvim_buf_get_mark(0, '<'))
  local row2, col2 = unpack(vim.api.nvim_buf_get_mark(0, '>'))
  require('hone.cpp').comment_charwise(row1-1, col1, row2-1, col2)
EOF
  elseif a:mode == 'V'
lua << EOF
  local row1, _ = unpack(vim.api.nvim_buf_get_mark(0, '<'))
  local row2, _ = unpack(vim.api.nvim_buf_get_mark(0, '>'))
  require('hone.cpp').comment_linewise(row1-1, row2-1)
EOF
  elseif a:mode == 'char'
lua << EOF
  local row1, col1 = unpack(vim.api.nvim_buf_get_mark(0, '['))
  local row2, col2 = unpack(vim.api.nvim_buf_get_mark(0, ']'))
  require('hone.cpp').comment_charwise(row1-1, col1, row2-1, col2)
EOF
  elseif a:mode == 'line'
lua << EOF
  local row1, _ = unpack(vim.api.nvim_buf_get_mark(0, '['))
  local row2, _ = unpack(vim.api.nvim_buf_get_mark(0, ']'))
  require('hone.cpp').comment_linewise(row1-1, row2-1)
EOF
  else
    echohl WarningMsg
    echo "[hone] unsupported mode: ".a:mode
    echohl None
  endif
endfu

fu! s:comment_line()
lua << EOF
  local row = vim.fn.line('.')
  require('hone.cpp').comment_linewise(row-1, row-1)
EOF
endfu

nnoremap <buffer> gcu <Cmd>lua require('hone.cpp').uncomment_under_cursor()<cr>
nnoremap <buffer> gc :<C-u>set opfunc=<SID>comment<cr>g@
nnoremap <buffer> gcc <Cmd>call <SID>comment_line()<cr>
vnoremap <buffer> gc :<C-u>call <SID>comment(visualmode())<cr>

setlocal commentstring=//%s

