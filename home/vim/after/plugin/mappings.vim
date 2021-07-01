" Load custom mappings
let mapleader=','

" Convenience
nnoremap ; :
" https://github.com/neovim/neovim/issues/13086
" If you type <ESC>; quickly enough, the key sequence generated will be <M-;>
inoremap <M-;> <ESC>:

" Unmap the arrow keys
no <down> ddp
no <left> <Nop>
no <right> <Nop>
no <up> ddkP
ino <down> <Nop>
ino <left> <Nop>
ino <right> <Nop>
ino <up> <Nop>
vno <down> <Nop>
vno <left> <Nop>
vno <right> <Nop>
vno <up> <Nop>

"close current buffer with bufkill
nnoremap <Leader>c :BD<CR>
nnoremap <Leader>C :%bd\|e#<CR>

"make moving between splits easier
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

"I really hate that things don't auto-center
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap } }zz
nmap { {zz

"make mappings for display lines
"These mappings make it easy to move along long lines
vmap <M-j> gj
vmap <M-k> gk
vmap <M-4> g$
vmap <M-6> g^
vmap <M-0> g^
nmap <M-j> gj
nmap <M-k> gk
nmap <M-4> g$
nmap <M-6> g^
nmap <M-0> g^

"This unsets the "last search pattern" register by hitting return
nnoremap <silent> <backspace> :noh<CR>

nmap =j :%!python -m json.tool<CR>
nmap =x :%!xmllint --format -<CR>

" Ultisnips
" By default, mapped to <Tab>,<Tab>,<S-Tab>
inoremap <silent> <C-e> <C-R>=UltiSnips#ExpandSnippet()<CR>
" matches g:coc_snippet_next
inoremap <silent> <C-j> <C-R>=UltiSnips#JumpForwards()<CR>
" matches g:coc_snippet_prev
inoremap <silent> <C-k> <C-R>=UltiSnips#JumpBackwards()<CR>

" easymotion style search
" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
nmap <Leader>s <Plug>(easymotion-s)

" Replace operator operator
nmap <Leader>r <plug>(SubversiveSubstitute)
nmap <Leader>rr <plug>(SubversiveSubstituteLine)
nmap <Leader>R <plug>(SubversiveSubstituteToEndOfLine)

" SkipIr mappings

" Since S-Tab is not recognized in console mode map to another key
" <C-n> and <C-p> are used for navigating the pum forwards and backwards so
" they are not available
silent! imap <unique> <C-f> <Plug>(SkipItForward)
silent! imap <unique> <C-b> <Plug>(SkipItBack)
silent! imap <unique> <C-g>f <Plug>(SkipAllForward)
silent! imap <unique> <C-g>b <Plug>(SkipAllBack)

" easy-align mappings
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)
"
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Toggles

" <C-r> is by default used in insert mode for pasting registers so let's not
" meddle with that
imap <C-l> <C-o>:call ToggleRl()<CR>

func! ToggleRl()
	if &rl
		set norl
	else
		set rl
	end
endfunc

" Toggle rl
nmap ]r :set rl<CR>
nmap [r :set norl<CR>

nmap <Leader>p :call TogglePaste()<CR>

func! TogglePaste()
	if &paste
		set nopaste
	else
		set paste
	end
endfunc

" Simple Ag mapping

" Bring up NERDTree on the current working directory (the current project)
nnoremap gn :NERDTreeToggle<CR>

" Toggle undo tree
nmap gu :UndotreeToggle<CR>

" Toggle tagbar
nmap gt :TagbarToggle<CR>

" Mapping selecting mappings
nmap <Leader><Tab> <Plug>(fzf-maps-n)
xmap <Leader><Tab> <Plug>(fzf-maps-x)
omap <Leader><Tab> <Plug>(fzf-maps-o)

if isdirectory('.git')
  nmap <C-p> :GFiles<CR>
else
  nmap <C-p> :Files<CR> 
endif

" command from ~/.fzf
nmap gfz :FZF<CR>

nmap gfa :Ag<CR>
nmap gff :Files<CR>
nmap gfb :Buffers<CR>
nmap gft :Tags<CR>
nmap gfg :GFiles<CR>
nmap gfs :Snippets<CR>

" Manually sets the mappings
call lexima#set_default_rules()
" https://github.com/cohama/lexima.vim/issues/65
call lexima#insmode#map_hook('before', '<CR>', '')

if has('nvim')
  imap <expr> <cr>  pumvisible() ? complete_info()["selected"] != "-1" ?
        \ "\<Plug>(completion_confirm_completion)"  : "\<c-e>\<CR>" :  "\<CR>"

  " Use <c-space> to trigger completion.
  imap <silent> <c-space> <Plug>(completion_trigger)
else
  function! s:my_cr_function() abort
    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
    " Coc only does snippet and additional edit on confirm.
    " :h complete_CTRL-Y used to accept completion
    " lexima needs to be triggered manually because it conflicts with <CR>
    return pumvisible() ? "\<C-y>" : "\<C-g>u" . lexima#expand('<CR>', 'i')
  endfunction

  function! s:show_documentation()
    if (index(['vim','help'], &filetype) >= 0)
      execute 'h '.expand('<cword>')
    else
      call CocAction('doHover')
    endif
  endfunction

  inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>

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
  xmap ic <Plug>(coc-classobj-i)
  omap ic <Plug>(coc-classobj-i)
  xmap ac <Plug>(coc-classobj-a)
  omap ac <Plug>(coc-classobj-a)

  " Use <TAB> for select selections ranges, needs server support, like: coc-tsserver, coc-python
  nmap <silent> <TAB> <Plug>(coc-range-select)
  xmap <silent> <TAB> <Plug>(coc-range-select)

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
