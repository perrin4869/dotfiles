set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

" This works by default on vim8
set mouse=a

" nvim 0.5 undo files are incompatible with vim8
set undodir=$HOME/.config/nvim/undo
