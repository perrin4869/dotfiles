" Mapping selecting mappings
nmap <Leader><Tab> <Plug>(fzf-maps-n)
xmap <Leader><Tab> <Plug>(fzf-maps-x)
omap <Leader><Tab> <Plug>(fzf-maps-o)

if isdirectory('.git')
  nmap <C-p> :GFiles<CR>
else
  nmap <C-p> :Files<CR>
endif

nmap <leader><CR> :Buffers<CR>

" command from ~/.fzf
nmap gfz :FZF<CR>

nmap <leader><leader>a :Ag<CR>
nmap <leader><leader>r :Rg<CR>
nmap <leader><leader>f :Files<CR>
nmap <leader><leader>b :Buffers<CR>
nmap <leader><leader>t :Tags<CR>
nmap <leader><leader>g :GFiles<CR>
nmap <leader><leader>s :Snippets<CR>
