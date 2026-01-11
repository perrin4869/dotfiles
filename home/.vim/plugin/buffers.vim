" close current buffer with bufkill, will avoid closing the current window
nnoremap <silent> <leader><bs> <cmd>BD<CR>
" close-buffers.vim, will close the current window on `Bdelete this`
" <C-BS> sends <C-h>
nnoremap <silent> <leader><c-h> <cmd>Bdelete hidden<CR>
