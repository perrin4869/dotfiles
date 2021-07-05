" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

if has('nvim')
  packadd nvim-lspconfig
  packadd nvim-compe
  packadd lsp_signature
  packadd lspsaga
  packadd nvim-metals
  packadd lsp-status
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
  autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()
else
  packadd coc.nvim

  function! LspStatus() abort
    return coc#status()
  endfunction

  function! LspCurrentFunction() abort
    return CocCurrentFunction()
  endfunction

  " Highlight symbol under cursor on CursorHold
  autocmd CursorHold * silent call CocActionAsync('highlight')

  augroup cocgroup
    autocmd!
      " Setup formatexpr specified filetype(s).
      autocmd FileType typescript,scala,json setl formatexpr=CocAction('formatSelected')
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " https://github.com/neoclide/coc.nvim/issues/1026
  " https://github.com/neoclide/coc.nvim/issues/1054
  " Enables jumping to definition using <C-]> and jumping back with <C-t>
  " Jumping back to the previous location can also happen using <C-o> and <C-i>
  if exists('+tagfunc') | setlocal tagfunc=CocTagFunc | endif

  " Use `:Format` to format current buffer
  command! -nargs=0 Format :call CocAction('format')

  " Use `:Fold` to fold current buffer
  command! -nargs=? Fold :call     CocAction('fold', <f-args>)

  " use `:OR` for organize import of current buffer
  command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
endif
