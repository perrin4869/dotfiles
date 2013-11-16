"pathogen installation
runtime bundle/vim-pathogen/autoload/pathogen.vim
execute pathogen#infect()

"syntax highlightning
syntax on
set nu

"make it so that vim doesn't warn us about moving from an unchanged buffer
set hidden

"generate help tags from all the plugins installed by pathogen
Helptags

"make sure that vimrc is initiated in 256 colors mode
set t_Co=256
colo jellybeans
filetype plugin indent on

"make sure airline is opened by default
set laststatus=2

let g:airline#extensions#tabline#enabled = 1
let g:airline_theme="badwolf"

if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

"completion hint in command mode
set wildmenu
set wildmode=list:longest,full

"make mappings for display lines
vmap <C-j> gj
vmap <C-k> gk
vmap <C-4> g$
vmap <C-6> g^
vmap <C-0> g^
nmap <C-j> gj
nmap <C-k> gk
nmap <C-4> g$
nmap <C-6> g^
nmap <C-0> g^

"make tabs and newlines visible
set list
set listchars=tab:▸\ ,eol:¬
"
"remove vi compatibility
set nocompatible

"make sure we don't highlight / search results
" set nohlsearch

"This unsets the "last search pattern" register by hitting return
nnoremap <CR> :noh<CR><CR>

"make sure the key to trigger easy motion is <leader> and not <leader><leader>
"as default
let g:EasyMotion_leader_key = '<Leader>'

" stop creating annoying tilde files
set nobackup
set nowritebackup

" alternatively, you could change the directory in which tilde files are stored
" set backupdir=~/.vim/backup

"youcompleteme options
let g:ycm_global_ycm_extra_conf='~/.vim/youcompleteme/.ycm_extra_conf.py'

"use omnicomplete whenever there's no completion engine in youcompleteme (for
"example, in the case of PHP)
set omnifunc=syntaxcomplete#Complete

"make ycm play nice with ultisnips
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
