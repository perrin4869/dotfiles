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

"make tabs and newlines visible
set list
set listchars=tab:▸\ ,eol:¬

" width of a tab
set tabstop=4
set shiftwidth=4

"completion hint in command mode
set wildmenu
set wildmode=list:longest,full
set wildignore=*.o,*.obj,*.la,*.lo,*.so,*.pyc,*.pyo,*.jpg,*.png,*.gif

" Coloring options
"make sure that vimrc is initiated in 256 colors mode
set t_Co=256
colo skittles_berry
" Override with custom colors
source ~/.vim/settings/colors.vim

" Airline options
"make sure airline is opened by default
set laststatus=2

" Undo can't be left in the same dir as the edited file because we may not
" have writing permission there
set undodir=$HOME/.vim/undo

" Stop cluttering cwd with swap and tilde files
set backupdir=$HOME/.vim/backup//,/tmp//,. " For tilde files"
set directory=$HOME/.vim/backup//,/tmp//,. " for swp files"
" For Unix and Win32, if a directory ends in two path separators, the swap
" file name will be built from the complete path to the file with all path
" separators substituted to percent '%' signs. This will ensure file name
" uniqueness in the preserve directory

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme="badwolf"

"youcompleteme options
let g:ycm_global_ycm_extra_conf='~/.vim/youcompleteme/.ycm_extra_conf.py'
" let g:ycm_path_to_python_interpreter='/usr/bin/python/'

"use omnicomplete whenever there's no completion engine in youcompleteme (for
"example, in the case of PHP)
set omnifunc=syntaxcomplete#Complete

" Folding options
" get folding signs space
set foldcolumn=3

" Save and load folds automatically
set viewoptions-=options

" stop creating annoying tilde files
set nobackup
set nowritebackup
" alternatively, you could change the directory in which tilde files are stored
" set backupdir=~/.vim/backup

" Fugitive options
" all snippets are taken from: http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
" For navigating trees
autocmd User fugitive 
  \ if fugitive#buffer().type() =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif

" For autocleaning of fugitive buffers
autocmd BufReadPost fugitive://* set bufhidden=delete

" Taggatron
" By default taggatron will be disabled, you can enable taggatron from Sauce
" files
let g:taggatron_enabled=0

" PyMatcher for CtrlP
if has('python')
	let g:ctrlp_match_func = { 'match': 'pymatcher#PyMatch' }
endif
" If ag is available use it as filename list generator instead of 'find'
if executable("ag")
	set grepprg=ag\ --nogroup\ --nocolor
	let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup --hidden -g ""'
endif

" Delimitmate options
let delimitMate_expand_cr = 1
let delimitMate_expand_space = 1
" Don't jump over multiple lines - use skipit for that
let delimitMate_jump_expansion = 0
" Nerdtree options
" Close vim automatically if nerdtree is the only pane left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" Unite
" Use ag for search
if executable('ag')
	let g:unite_source_rec_async_command = 'ag --follow --nocolor --nogroup --hidden -g ""'
	let g:unite_source_grep_command = 'ag'
	let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
	let g:unite_source_grep_recursive_opt = ''
endif

call unite#custom#source('file_rec/async', 'ignore_pattern', '(png\|gif\|jpeg\|jpg)$')
" Allow for searches without having to put spaces
call unite#filters#matcher_default#use(['matcher_fuzzy'])
call unite#custom#source('file_rec/async', 'ignore_globs',
			\ split(&wildignore, ','))


" Load custom mappings
let mapleader=','
source ~/.vim/settings/mappings.vim

"Custom commads
command -bang -nargs=? W SudoWrite<bang> <args>
command -bang -nargs=? E SudoRead<bang> <args>
command -bang Q qall<bang>

