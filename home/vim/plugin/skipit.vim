" Since S-Tab is not recognized in console mode map to another keyB
" <C-n> and <C-p> are used for navigating the pum forwards and backwards so
" they are not available
silent! imap <unique> <C-j> <Plug>(SkipItForward)
silent! imap <unique> <C-k> <Plug>(SkipItBack)
silent! imap <unique> <C-g>j <Plug>(SkipAllForward)
silent! imap <unique> <C-g>k <Plug>(SkipAllBack)
