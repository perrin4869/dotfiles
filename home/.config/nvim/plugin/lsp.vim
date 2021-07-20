packadd nvim-lspconfig
packadd nvim-compe
packadd lsp_signature
packadd lspsaga
packadd nvim-metals
packadd lsp-status
packadd vim-illuminate
" coc equivalent
" if exists('+tagfunc') | setlocal tagfunc=CocTagFunc | endif
" Enables jumping to definition using <C-]> and jumping back with <C-t>
" Jumping back to the previous location can also happen using <C-o> and <C-i>
packadd nvim-lsp-smag

lua require'lsp'

set completeopt=menuone,noselect

function! LspStatus() abort
  return luaeval("require('lsp').get_status()")
endfunction

function! MetalsStatus() abort
  return metals#status()
endfunction

" This is nicer than having virtual text
" https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics({focusable = false})

" illuminate
hi def link LspReferenceText CursorLine
hi def link LspReferenceWrite CursorLine
hi def link LspReferenceRead CursorLine

" Mappings
inoremap <silent><expr> <C-Space> compe#complete()
" TODO: explain why <LT> is needed?
inoremap <silent><expr> <CR>      compe#confirm(lexima#expand('<LT>CR>', 'i'))
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
" inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
" inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
