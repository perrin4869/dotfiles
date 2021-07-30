"syntax highlightning
syntax on
filetype plugin indent on

"show the line numbers
set nu
" set rnu

" get the current line highlighed
set cul " set cursorline

"remove vi compatibility
set nocompatible

"make it so that vim doesn't warn us about moving from an unchanged buffer
set hidden

"make sure we don't highlight / search results
" set nohlsearch

"make tabs and newlines visible
set list
set listchars=tab:▸\ ,eol:¬

" width of a tab
set expandtab
set tabstop=2
set shiftwidth=2

"completion hint in command mode
set wildmenu
set wildmode=list:longest,full
set wildignore=*.o,*.obj,*.la,*.lo,*.so,*.pyc,*.pyo,*.jpg,*.png,*.gif

" On MacOS the default backspace option is messed up
set backspace=indent,eol,start

" Airline options
"make sure airline is opened by default
set laststatus=2

" Undo can't be left in the same dir as the edited file because we may not
" have writing permission there
set undodir=$HOME/.vim/undo
set undofile

" Stop cluttering cwd with swap and tilde files
set backupdir=$HOME/.vim/backup//,/tmp//,. " For tilde files"
set directory=$HOME/.vim/backup//,/tmp//,. " for swp files"
" For Unix and Win32, if a directory ends in two path separators, the swap
" file name will be built from the complete path to the file with all path
" separators substituted to percent '%' signs. This will ensure file name
" uniqueness in the preserve directory

" Folding options
" get folding signs space
set foldcolumn=3

" Save and load folds automatically
set viewoptions-=options
" https://vi.stackexchange.com/questions/11903/working-directory-different-than-current-file-directory
" restore_view plugin related - prevent unnecessary pwd changes
set viewoptions-=curdir

" stop creating annoying tilde files
set nobackup
set nowritebackup
" alternatively, you could change the directory in which tilde files are stored
" set backupdir=~/.vim/backup

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
nnoremap Q :Bdelete<CR>
nnoremap <Leader>Q :Bdelete hidden<CR>

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

nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf

nmap =j :%!python -m json.tool<CR>
nmap =x :%!xmllint --format -<CR>

"Custom commads
command -bang Q qall<bang>

" Run xrdb whenever Xdefaults or Xresources are updated.
autocmd BufWritePost *Xresources,*Xdefaults !xrdb %
