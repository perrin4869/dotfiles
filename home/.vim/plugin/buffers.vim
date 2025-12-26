" close current buffer with bufkill, will avoid closing the current window
nnoremap <silent> <C-q> <cmd>BD<CR>
" close-buffers.vim, will close the current window on `Bdelete this`
nnoremap <silent> <C-g>q <cmd>Bdelete hidden<CR>
