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

"gutentags
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

" This is needed for the separate fzf.vim plugin to work
set rtp+=~/.fzf

" lightline-bufferline requires this
set showtabline=2

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

" Coc configurations

" Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

augroup cocgroup
  autocmd!
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

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

"Custom commads
command -bang Q qall<bang>

" Automatically save with sudo when lacking permissions
let g:suda_smart_edit = 1

aug i3config_ft_detection
  au!
  au BufNewFile,BufRead ~/.config/i3/config set filetype=i3config
aug end

" Disable default ultisnips mappings, gets mapped on after/plugins/mappinigs.vim
let g:UltiSnipsExpandTrigger="<Nop>"
let g:UltiSnipsJumpForwardTrigger="<Nop>"
let g:UltiSnipsJumpBackwardTrigger="<Nop>"

" Update binds when sxhkdrc is updated.
autocmd BufWritePost *sxhkdrc !pkill -USR1 sxhkd

" Run xrdb whenever Xdefaults or Xresources are updated.
autocmd BufWritePost *Xresources,*Xdefaults !xrdb %

" Comments on json files syntax
autocmd FileType json syntax match Comment +\/\/.\+$+

" Set lexima mappings manually since they conflict with <CR>
let g:lexima_no_default_rules = 1

let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1

let g:lightline = {}
let g:lightline.colorscheme = 'gruvbox'
let g:lightline.active = {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitgutter', 'gitbranch' ],
      \             [ 'cocstatus', 'currentfunction'],
      \             [ 'vimtex' ],
      \             [ 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'fileformat', 'fileencoding', 'filetype' ],
      \              [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok' ]],
      \ }
let g:lightline.component = {
      \   'lineinfo': ' %3l:%-2v'
      \ }
" overrides default readonly, fileformat, fileencoding and filetype components
let g:lightline.component_function = {
      \   'gitbranch': 'LightLineFugitive',
      \   'gitgutter': 'LightLineGitGutter',
      \   'vimtex': 'LightLineVimTex',
      \   'cocstatus': 'coc#status',
      \   'currentfunction': 'CocCurrentFunction',
      \   'readonly': 'LightLineReadonly',
      \   'fileformat': 'LightlineFileformat',
      \   'fileencoding': 'LightlineFileencoding',
      \   'filetype': 'LightlineFiletype',
      \ }
let g:lightline.tabline = {
      \   'left': [ ['buffers'] ],
      \   'right': [ ['close'] ]
      \ }
let g:lightline.component_expand = {
      \  'buffers': 'lightline#bufferline#buffers',
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_infos': 'lightline#ale#infos',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
      \ }
let g:lightline.component_type = {
      \   'buffers': 'tabsel',
      \   'linter_checking': 'right',
      \   'linter_infos': 'right',
      \   'linter_warnings': 'warning',
      \   'linter_errors': 'error',
      \   'linter_ok': 'right',
      \ }
let g:lightline.separator = {
      \   'left': '',
      \   'right': ''
      \ }
let g:lightline.subseparator = {
      \   'left': '',
      \   'right': ''
      \ }

let g:lightline#bufferline#enable_devicons = 1
let g:lightline#ale#indicator_checking = "\uf110"
let g:lightline#ale#indicator_infos = "\uf129"
let g:lightline#ale#indicator_warnings = "\uf071"
let g:lightline#ale#indicator_errors = "\uf05e"
let g:lightline#ale#indicator_ok = "\uf00c"

function! LightLineReadonly()
  return &readonly && &filetype !=# 'help' ? '' : ''
endfunction

function! LightLineFugitive()
  let _ = fugitive#head()
  return strlen(_) ? ' '._.'⚡' : ''
endfunction

function! LightLineGitGutter()
  if exists('*GitGutterGetHunkSummary')
    let [ added, modified, removed ] = GitGutterGetHunkSummary()
    return printf('+%d ~%d -%d', added, modified, removed)
  endif
  return ''
endfunction

function! LightLineVimTex()
  let l:status = ''

  let vt_local = get(b:, 'vimtex_local', {})
  if empty(vt_local)
    let l:status .= ''
  else
    if get(vt_local, 'active')
      let l:status .= 'l'
    else
      let l:status .= 'm'
    endif
  endif

  if get(get(get(b:, 'vimtex', {}), 'viewer', {}), 'xwin_id')
    let l:status .= 'v'
  endif

  let l:compiler = get(get(b:, 'vimtex', {}), 'compiler', {})
  if !empty(l:compiler)
    if has_key(l:compiler, 'is_running') && b:vimtex.compiler.is_running()
      if get(l:compiler, 'continuous')
        let l:status .= 'c'
      else
        let l:status .= 'c₁'
      endif
    endif
  endif

  if !empty(l:status)
    let l:status = '{' . l:status . '}'
  endif
  return l:status
endfunction

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
endfunction

function! LightlineFileencoding()
  return winwidth(0) > 70 ? (&fenc !=# '' ? &fenc : &enc) : ''
endfunction
