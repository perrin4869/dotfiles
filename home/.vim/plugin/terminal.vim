noremap  <leader>t  :FloatermToggle<CR>
noremap! <leader>t  <Esc>:FloatermToggle<CR>
tnoremap <leader>t  <C-\><C-n>:FloatermToggle<CR>

" vim-powered terminal in split window
nnoremap <Leader>T :term<cr>
tnoremap <Leader>T <c-w>:term<cr>

if has("nvim")
  " Make escape work in the Neovim terminal.
  " Esc is useful in zsh in vim-mode, so use <C-o> instead
  tnoremap <C-o> <C-\><C-n>

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd TermOpen * startinsert
endif
