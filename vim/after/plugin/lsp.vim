function! s:FixCtrlSpace()
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
endfunction

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

  call s:FixCtrlSpace()
  " Use <c-space> to trigger completion.
  imap <silent> <c-space> <Plug>(completion_trigger)

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
    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " https://github.com/neoclide/coc.nvim/issues/1026
  " https://github.com/neoclide/coc.nvim/issues/1054
  " Enables jumping to definition using <C-]> and jumping back with <C-t>
  " Jumping back to the previous location can also happen using <C-o> and <C-i>
  if exists('+tagfunc') | setlocal tagfunc=CocTagFunc | endif

  function! s:my_cr_function() abort
    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
    " Coc only does snippet and additional edit on confirm.
    " :h complete_CTRL-Y used to accept completion
    " lexima needs to be triggered manually because it conflicts with <CR>
    return pumvisible() ? "\<C-y>" : "\<C-g>u" . lexima#expand('<CR>', 'i')
  endfunction

  inoremap <CR> <C-r>=<SID>my_cr_function()<CR>


  call s:FixCtrlSpace()
  " Use <c-space> to trigger completion.
  inoremap <silent><expr> <c-space> coc#refresh()

  " Use `[g` and `]g` to navigate diagnostics
  nmap <silent> [g <Plug>(coc-diagnostic-prev)
  nmap <silent> ]g <Plug>(coc-diagnostic-next)

  " Remap keys for gotos
  nmap <silent> gd <Plug>(coc-definition)
  nmap <silent> gy <Plug>(coc-type-definition)
  nmap <silent> gi <Plug>(coc-implementation)
  nmap <silent> gr <Plug>(coc-references)

  " Use K to show documentation in preview window
  nnoremap <silent> K :call <SID>show_documentation()<CR>

  function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('doHover')
    endif
  endfunction

  " Remap for rename current word
  nmap <leader>rn <Plug>(coc-rename)

  " Remap for format selected region
  xmap <leader>f  <Plug>(coc-format-selected)
  nmap <leader>f  <Plug>(coc-format-selected)

  " Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
  xmap <leader>a  <Plug>(coc-codeaction-selected)
  nmap <leader>a  <Plug>(coc-codeaction-selected)

  " Remap for do codeAction of current line
  nmap <leader>ac  <plug>(coc-codeaction)
  " fix autofix problem of current line
  nmap <leader>qf  <Plug>(coc-fix-current)

  " Create mappings for function text object, requires document symbols feature of languageserver.
  xmap if <Plug>(coc-funcobj-i)
  xmap af <Plug>(coc-funcobj-a)
  omap if <Plug>(coc-funcobj-i)
  omap af <Plug>(coc-funcobj-a)

  " Use <TAB> for select selections ranges, needs server support, like: coc-tsserver, coc-python
  nmap <silent> <TAB> <Plug>(coc-range-select)
  xmap <silent> <TAB> <Plug>(coc-range-select)

  " Use `:Format` to format current buffer
  command! -nargs=0 Format :call CocAction('format')

  " Use `:Fold` to fold current buffer
  command! -nargs=? Fold :call     CocAction('fold', <f-args>)

  " use `:OR` for organize import of current buffer
  command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

  " Using CocList
  " Show all diagnostics
  nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
  " Manage extensions
  nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
  " Show commands
  nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
  " Find symbol of current document
  nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
  " Search workspace symbols
  nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
  " Do default action for next item.
  nnoremap <silent> <space>j  :<C-u>CocNext<CR>
  " Do default action for previous item.
  nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
  " Resume latest coc list
  nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
endif
