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
inoremap <silent> <C-f> <C-R>=UltiSnips#JumpForwards()<CR>
inoremap <silent> <C-b> <C-R>=UltiSnips#JumpBackwards()<CR>

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
