nnoremap <silent> <M-t> <cmd>FloatermToggle<CR>
tnoremap <silent> <M-t> <cmd>FloatermToggle<CR>

nnoremap   <silent>   <F6>    :FloatermNew<CR>
tnoremap   <silent>   <F6>    <C-\><C-n>:FloatermNew<CR>
nnoremap   <silent>   <F7>    :FloatermPrev<CR>
tnoremap   <silent>   <F7>    <C-\><C-n>:FloatermPrev<CR>
nnoremap   <silent>   <F8>    :FloatermNext<CR>
tnoremap   <silent>   <F8>    <C-\><C-n>:FloatermNext<CR>
nnoremap   <silent>   <F12>   :FloatermToggle<CR>
tnoremap   <silent>   <F12>   <C-\><C-n>:FloatermToggle<CR>

nnoremap   <silent>   <F9>   :FloatermKill<CR>
tnoremap   <silent>   <F9>   <C-\><C-n>:FloatermKill<CR>

if has("nvim")
  " Make escape work in the Neovim terminal.
  " Esc is useful in zsh in vim-mode, so use <C-o> instead
  tnoremap <Esc><Esc> <C-\><C-n>

  " Prefer Neovim terminal insert mode to normal mode.
  autocmd TermOpen * startinsert
endif
