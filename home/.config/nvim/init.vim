source ~/.vimrc

" This works by default on vim8
set mouse=a

" nvim 0.5 undo files are incompatible with vim8
let &undodir=stdpath("data") . "/undo"
