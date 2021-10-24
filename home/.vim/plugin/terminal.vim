" vim-powered terminal in split window
map <Leader>t :term<cr>
tmap <Leader>t <c-w>:term<cr>

if has("nvim")
  " Make escape work in the Neovim terminal.
  tnoremap <Esc> <C-\><C-n>

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd TermOpen * startinsert
endif
