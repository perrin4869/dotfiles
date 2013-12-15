
" Add vim commands, mappings, functions, etc for this source
"
" Eg:

let g:current_dir = "~/websites/coddress"
exec 'cd ' . g:current_dir

" make html snippets available when editting php files
autocmd FileType php UltiSnipsAddFiletypes php.html
au BufRead *.php set ft=php.html
au BufNewFile *.php set ft=php.html

" If using NERDTree:
exec 'NERDTree ' . g:current_dir
