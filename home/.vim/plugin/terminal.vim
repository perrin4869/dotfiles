noremap  <silent> <leader>t :FloatermToggle<CR>
noremap! <silent> <leader>t <Esc>:FloatermToggle<CR>
tnoremap <silent> <leader>t <C-\><C-n>:FloatermToggle<CR>

" vim-powered terminal in split window
nnoremap <silent> <Leader>T :term<cr>
tnoremap <silent> <Leader>T <c-w>:term<cr>

if has("nvim")
  " Make escape work in the Neovim terminal.
  " Esc is useful in zsh in vim-mode, so use <C-o> instead
  tnoremap <C-o> <C-\><C-n>

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd TermOpen * startinsert
endif
