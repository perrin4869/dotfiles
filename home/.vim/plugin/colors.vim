" Coloring options
"make sure that vimrc is initiated in 256 colors mode

set t_Co=256

" Not supported by urxvt without true colors
if $COLORTERM =~? 'truecolor$' || $COLORTERM =~? '24bit$'
  set termguicolors
endif

" https://groups.google.com/forum/#!msg/vim_dev/afPqwAFNdrU/nqh6tOM87QUJ
" TODO: investigate why this setting is required to come before the
" colorscheme in terminal vim
set background=dark

" Disabled by default for terminals without italics support
" In slackware, rxvt-unicode-256color supports italics
let g:gruvbox_italic=1
colo gruvbox

" Override default colors

" make background-color transparent
hi Normal ctermbg=none

" htmlTagName links to htmlStatement links to Statement
hi Statement ctermbg=none ctermfg=202

" Settinigs for vim in the terminal with truecolor, but not on gvim
if !has("gui_running")
  hi Normal guibg=NONE
  hi Statement guibg=NONE
endif

" current line
hi CursorLine ctermbg=17
