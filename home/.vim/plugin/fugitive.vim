" all snippets are taken from: http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
" For navigating trees
autocmd User fugitive
  \ if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif

" For autocleaning of fugitive buffers
autocmd BufReadPost fugitive://* set bufhidden=delete

nnoremap <silent> <C-g>w :Gwrite<CR>
nnoremap <silent> <C-g>r :Gread<CR>
nnoremap <silent> <C-g>c :Git commit<CR>
nnoremap <silent> <C-g>C :Git commit --amend<CR>
nnoremap <silent> <C-g>p :Git push<CR>
nnoremap <silent> <C-g>P :Git push --force<CR>
nnoremap <silent> <C-g>d :Gdiff<CR>
nnoremap <silent> <C-g>s :Git status<CR>
nnoremap <silent> <C-g>l :Git log<CR>
