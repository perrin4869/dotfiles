"pathogen installation
runtime bundle/vim-pathogen/autoload/pathogen.vim
execute pathogen#infect()

"generate help tags from all the plugins installed by pathogen
Helptags

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

" stop creating annoying tilde files
set nobackup
set nowritebackup
" alternatively, you could change the directory in which tilde files are stored
" set backupdir=~/.vim/backup

"make tabs and newlines visible
set list
set listchars=tab:▸\ ,eol:¬

" width of a tab
set tabstop=5

"completion hint in command mode
set wildmenu
set wildmode=list:longest,full

"use omnicomplete whenever there's no completion engine in youcompleteme (for
"example, in the case of PHP)
set omnifunc=syntaxcomplete#Complete

"make sure that vimrc is initiated in 256 colors mode
set t_Co=256
colo skittles_berry
" colo jellybeans

"make sure airline is opened by default
set laststatus=2

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme="badwolf"

"youcompleteme options
let g:ycm_global_ycm_extra_conf='~/.vim/youcompleteme/.ycm_extra_conf.py'
" let g:ycm_path_to_python_interpreter='/usr/bin/python/'

" Load custom settings
source ~/.vim/settings/mappings.vim
