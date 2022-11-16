" Automatically save with sudo when lacking permissions
" let g:suda_smart_edit = 1
" when using lsp jump to definition to a readonly file (this happens with
" `.metals/readonly/dependencies`) suda will replace the buffer and it will
" fail to jump to the right spot in the file
" https://github.com/lambdalisue/suda.vim/issues/54
