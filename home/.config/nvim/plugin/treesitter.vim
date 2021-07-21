lua require'treesitter'

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
" https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
set foldlevelstart=99
