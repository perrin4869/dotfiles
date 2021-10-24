" vim-powered terminal in split window
nnoremap <Leader>t :term<cr>
tnoremap <Leader>t <c-w>:term<cr>

noremap  <leader>T  :FloatermToggle<CR>
noremap! <leader>T  <Esc>:FloatermToggle<CR>
tnoremap <leader>T  <C-\><C-n>:FloatermToggle<CR>

if has("nvim")
  " Make escape work in the Neovim terminal.
  tnoremap <Esc> <C-\><C-n>

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd TermOpen * startinsert
endif
