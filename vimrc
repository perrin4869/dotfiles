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
set tabstop=5

"completion hint in command mode
set wildmenu
set wildmode=list:longest,full

" Coloring options
"make sure that vimrc is initiated in 256 colors mode
set t_Co=256
colo skittles_berry
" Override with custom colors
source ~/.vim/settings/colors.vim

" Airline options
"make sure airline is opened by default
set laststatus=2

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline_theme="badwolf"

"youcompleteme options
let g:ycm_global_ycm_extra_conf='~/.vim/youcompleteme/.ycm_extra_conf.py'
" let g:ycm_path_to_python_interpreter='/usr/bin/python/'

"use omnicomplete whenever there's no completion engine in youcompleteme (for
"example, in the case of PHP)
set omnifunc=syntaxcomplete#Complete

" let g:ycm_key_invoke_completion = '<C-s>' " Ctrl-suggest - doesn't work
" because C-s freezes the command line
let g:ycm_key_invoke_completion = '<C-h>'
" let g:ycm_key_list_select_completion = ['<C-j>']
" let g:ycm_key_list_previous_completion = ['<C-k>']
let g:ycm_key_list_select_completion = ['<Tab>']
let g:ycm_key_list_previous_completion = ['<S-Tab>']

" Ultisnips
" let g:UltiSnipsExpandTrigger="<Tab>"
" let g:UltiSnipsJumpForwardTrigger="<Tab>"
" let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

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

" Latex-suite options
" IMPORTANT: grep will sometimes skip displaying the file name if you
" search in a singe file. This will confuse Latex-Suite. Set your grep
" program to always generate a file-name.
set grepprg=grep\ -nH\ $*

" OPTIONAL: Starting with Vim 7, the filetype of empty .tex files defaults to
" 'plaintex' instead of 'tex', which results in vim-latex not being loaded.
" The following changes the default filetype back to 'tex':
let g:tex_flavor='latex'

" fix the mapping of imap.vim in latex-suite which remaps <c-j>
nnoremap <Leader><Leader>j <Plug>IMAP_JumpForward
" If you take a look at the code of imaps.vim you’ll see that it won’t create a mapping if there is a mapping to <Plug>IMAP_JumpForward ({rhs}), not if there is a <C-j> mapping ({lhs}). Thus you should use
" nnoremap <SID>I_won’t_ever_type_this <Plug>IMAP_JumpForward
 
" easymotion configuration
" enable japanese search

" Easymotion
"make sure the key to trigger easy motion is <leader> and not <leader><leader>
"as default
let g:EasyMotion_leader_key = '<Leader>'

" easymotion style search
" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" Taggatron
" By default taggatron will be disabled, you can enable taggatron from Sauce
" files
let g:taggatron_enabled=0


" Load custom mappings
let mapleader=','
source ~/.vim/settings/mappings.vim

