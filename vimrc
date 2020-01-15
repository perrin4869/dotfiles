"https://github.com/vim/vim/issues/5026
silent! helptags ALL

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

" Coloring options
"make sure that vimrc is initiated in 256 colors mode
set t_Co=256
colo skittles_berry
" Override with custom colors
source ~/.vim/settings/colors.vim

set statusline+=%{gutentags#statusline()}

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

set rtp+=~/.fzf

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme="badwolf"

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

" Markdown
let g:vim_markdown_preview_use_xdg_open=1

" Fugitive options
" all snippets are taken from: http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/
" For navigating trees
autocmd User fugitive 
  \ if get(b:, 'fugitive_type', '') =~# '^\%(tree\|blob\)$' |
  \   nnoremap <buffer> .. :edit %:h<CR> |
  \ endif

" For autocleaning of fugitive buffers
autocmd BufReadPost fugitive://* set bufhidden=delete

" ale
let g:ale_fix_on_save=1

" Use tern_for_vim.
let g:tern#command = ["tern"]
let g:tern#arguments = ["--persistent"]

" Nerdtree options
" Close vim automatically if nerdtree is the only pane left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" Load custom mappings
let mapleader=','
source ~/.vim/settings/mappings.vim

"Custom commads
command -bang -nargs=? W SudoWrite<bang> <args>
command -bang -nargs=? E SudoRead<bang> <args>
command -bang Q qall<bang>

aug i3config_ft_detection
  au!
  au BufNewFile,BufRead ~/.config/i3/config set filetype=i3config
aug end

" Update binds when sxhkdrc is updated.
autocmd BufWritePost *sxhkdrc !pkill -USR1 sxhkd

" Run xrdb whenever Xdefaults or Xresources are updated.
autocmd BufWritePost *Xresources,*Xdefaults !xrdb %

" Comments on json files syntax
autocmd FileType json syntax match Comment +\/\/.\+$+
