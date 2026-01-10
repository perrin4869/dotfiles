" all snippets are taken from: http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
" For navigating trees
autocmd User fugitive
  \ if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif

" For autocleaning of fugitive buffers
autocmd BufReadPost fugitive://* set bufhidden=delete

nnoremap <silent> <leader>gw <cmd>Gwrite<CR>
nnoremap <silent> <leader>gr <cmd>Gread<CR>
nnoremap <silent> <leader>gc <cmd>Git commit<CR>
nnoremap <silent> <leader>gC <cmd>Git commit --amend<CR>
nnoremap <silent> <leader>gp <cmd>Git push<CR>
nnoremap <silent> <leader>gP <cmd>Git push --force<CR>
nnoremap <silent> <leader>gd <cmd>Gdiff<CR>
nnoremap <silent> <leader>gs <cmd>Git status<CR>
nnoremap <silent> <leader>gl <cmd>Git log<CR>

" Convenience
nnoremap <silent> <M-s> <cmd>Gwrite<CR>
nnoremap <silent> <leader>W <cmd>Gwrite<CR>
nnoremap <silent> <leader><C-w> <cmd>Gwrite<CR>
nnoremap <silent> <leader><C-s> <cmd>Gwrite<CR>
