if exists("g:loaded_hone")
  finish
endif
let g:loaded_hone = 1

augroup hone_options
  autocmd!
  autocmd FileType c,cpp call hone#update_win_options()
augroup END
