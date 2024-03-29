" Nerdtree options
" Close vim automatically if nerdtree is the only pane left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" Bring up NERDTree on the current working directory (the current project)
nnoremap gN <cmd>NERDTreeToggle<CR>

let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
