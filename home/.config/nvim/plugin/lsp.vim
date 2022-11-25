lua require'autocomplete'
lua require'lsp'

set completeopt=menuone,noselect

function! LspStatus() abort
  if (luaeval("#vim.lsp.buf_get_clients()") > 0)
    return luaeval("require'lsp-status'.status()")
  endif

  return ''
endfunction

function! MetalsStatus() abort
  return get(g:, 'metals_status', '')
endfunction

" This is nicer than having virtual text
" https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
autocmd CursorHold * lua vim.diagnostic.open_float({focusable = false})

" document highlighting
hi def link LspReferenceText CursorLine
hi def link LspReferenceWrite CursorLine
hi def link LspReferenceRead CursorLine
