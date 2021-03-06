if has('nvim')
  packadd nvim-lspconfig
  packadd completion-nvim
  packadd completion-buffers
  packadd nvim-metals
  packadd lsp-status
  " coc equivalent
  " if exists('+tagfunc') | setlocal tagfunc=CocTagFunc | endif
  " Enables jumping to definition using <C-]> and jumping back with <C-t>
  " Jumping back to the previous location can also happen using <C-o> and <C-i>
  packadd nvim-lsp-smag

  lua require'lsp'

  " Set completeopt to have a better completion experience
  set completeopt=menuone,noinsert,noselect

  " possible value: 'UltiSnips', 'Neosnippet', 'vim-vsnip', 'snippets.nvim'
  let g:completion_enable_snippet = 'UltiSnips'

  " Better display for messages
  set cmdheight=2

  " You will have bad experience for diagnostic messages when it's default 4000.
  set updatetime=300

  " don't give |ins-completion-menu| messages.
  set shortmess+=c

  " always show signcolumns
  set signcolumn=yes

  " Avoids conflict with lexima lexima#expand('<CR>', 'i')
  let g:completion_confirm_key = ""
  imap <expr> <cr>  pumvisible() ? complete_info()["selected"] != "-1" ?
        \ "\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>" :  "\<CR>"

  function! LspStatus() abort
    return luaeval("require('lsp').get_status()")
  endfunction

  function! MetalsStatus() abort
    return metals#status()
  endfunction

  " When you press <C-Space>, the terminal sends an ambiguous signal to Vim
  " which interprets it as <Nul>. Because <Nul> is usually represented as <C-@>,
  " Vim acts as if you actually pressed <C-@> and tries to insert the previously
  " inserted text.
  " http://h-miyako.hatenablog.com/entry/2014/01/20/053327
  if !has('gui_running')
    augroup term_vim_c_space
      autocmd!
      autocmd VimEnter * map <Nul> <C-Space>
      autocmd VimEnter * map! <Nul> <C-Space>
    augroup END
  endif

  " Use <c-space> to trigger completion.
  inoremap <silent><expr> <c-space> <Plug>(completion_trigger)

  " This is nicer than having virtual text
  autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()
endif
