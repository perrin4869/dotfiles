set completeopt=menuone,noselect

function! LspStatus() abort
  return luaeval("require'lsp-progress'.progress()")
endfunction

function! MetalsStatus() abort
  return get(g:, 'metals_status', '') .. ' ' .. get(g:, 'bsp_status', '')
endfunction

" document highlighting
hi def link LspReferenceText CursorLine
hi def link LspReferenceWrite CursorLine
hi def link LspReferenceRead CursorLine
