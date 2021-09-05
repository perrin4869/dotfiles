" Toggle panel with Tree Views
nnoremap <silent> <leader>tv <cmd>lua require("metals").toggle_tree_view()<CR>
" Reveal current current class (trait or object) in Tree View 'metalsPackages'
nnoremap <silent> <leader>tf <cmd>lua require("metals").reveal_in_tree()<CR>

nnoremap <silent> <leader>o <cmd>lua require("metals").organize_imports()<CR>
command! -nargs=0 OR   MetalsOrganizeImport

lua require('lsp').initialize_metals()
