" Load custom mappings
let mapleader=','

" Convenience
nnoremap ; :

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

"make moving between buffers easier
nnoremap <Tab> :bn<CR>
nnoremap <S-Tab> :bp<CR>

"folding
nnoremap <Space> za
vnoremap <Space> zf

"This unsets the "last search pattern" register by hitting return
nnoremap <silent> <backspace> :noh<CR>

" Ultisnips
" let g:UltiSnipsExpandTrigger="<Tab>"
" let g:UltiSnipsJumpForwardTrigger="<Tab>"
" let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-f>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

" easymotion style search
" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)
nmap <Leader>s <Plug>(easymotion-s)

" skipit mappings

" Since S-Tab is not recognized in console mode map to another key
" <C-n> and <C-p> are used for navigating the pum forwards and backwards so
" they are not available
silent! imap <unique> <C-k> <Plug>(SkipItForward)
silent! imap <unique> <C-j> <Plug>(SkipItBack)
silent! imap <unique> <C-g>k <Plug>(SkipAllForward)
silent! imap <unique> <C-g>j <Plug>(SkipAllBack)

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
nnoremap <Leader>n :NERDTreeToggle<CR>

" Toggle relative numbers
nmap <Leader>r :call ToggleRnu()<CR>

func! ToggleRnu()
	if &rnu
		set nornu
	else
		set rnu
	end
endfunc

" Toggle undo tree
nmap <Leader>u :UndotreeToggle<CR>

" Toggle tagbar
nmap <Leader>t :TagbarToggle<CR>

" Mapping selecting mappings
nmap <Leader><Tab> <Plug>(fzf-maps-n)
xmap <Leader><Tab> <Plug>(fzf-maps-x)
omap <Leader><Tab> <Plug>(fzf-maps-o)

nmap <C-p> :FZF<CR>
nmap <Leader>a :Ag<CR>
nmap <Leader>ff :Files<CR>
nmap <Leader>fb :Buffers<CR>
nmap <Leader>ft :Tags<CR>
nmap <Leader>fg :GFiles<CR>
nmap <Leader>fs :Snippets<CR>

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

" Manually sets the mappings
call lexima#set_default_rules()
" https://github.com/cohama/lexima.vim/issues/65
call lexima#insmode#map_hook('before', '<CR>', '')

function! s:my_cr_function() abort
  " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
  " Coc only does snippet and additional edit on confirm.
  " :h complete_CTRL-Y used to accept completion
  " lexima needs to be triggered manually because it conflicts with <CR>
  return pumvisible() ? "\<C-y>" : "\<C-g>u" . lexima#expand('<CR>', 'i')
endfunction

inoremap <CR> <C-r>=<SID>my_cr_function()<CR>

" Remap keys for gotos
nmap <silent> <Leader>d <Plug>(coc-definition)
nmap <silent> <Leader>y <Plug>(coc-type-definition)
nmap <silent> <Leader>i <Plug>(coc-implementation)
nmap <silent> <Leader>r <Plug>(coc-references)

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)
