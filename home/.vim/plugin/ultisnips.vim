" Disable automatic mappings
let g:UltiSnipsExpandTrigger="<Nop>"
let g:UltiSnipsJumpForwardTrigger="<Nop>"
let g:UltiSnipsJumpBackwardTrigger="<Nop>"

function! s:UltiSnipsExpandOrJump()
  if UltiSnips#CanExpandSnippet() == 1 || UltiSnips#CanJumpForwards() == 1
    return "\<C-R>=UltiSnips#ExpandSnippetOrJump()\<CR>"
  endif

  return "\<Tab>"
endfunction

inoremap <buffer><nowait><silent><expr> <Tab> <SID>UltiSnipsExpandOrJump()
snoremap <buffer><nowait><silent> <Tab> <Esc>:call UltiSnips#ExpandSnippetOrJump()<CR>
inoremap <buffer><nowait><silent><expr> <S-Tab>
      \ UltiSnips#CanJumpBackwards() == 1 ? "\<C-R>=UltiSnips#JumpBackwards()\<CR>" : "\<S-Tab>"
snoremap <buffer><nowait><silent> <S-Tab> <Esc>:call UltiSnips#JumpBackwards()<CR>
