" Mapping selecting mappings
nmap <Leader><Tab> <Plug>(fzf-maps-n)
xmap <Leader><Tab> <Plug>(fzf-maps-x)
omap <Leader><Tab> <Plug>(fzf-maps-o)

if isdirectory('.git')
  nmap <C-p> :GFiles<CR>
else
  nmap <C-p> :Files<CR>
endif

" command from ~/.fzf
nmap gfz :FZF<CR>

nmap gfa :Ag<CR>
nmap gff :Files<CR>
nmap gfb :Buffers<CR>
nmap gft :Tags<CR>
nmap gfg :GFiles<CR>
nmap gfs :Snippets<CR>
