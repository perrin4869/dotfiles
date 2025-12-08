" Since S-Tab is not recognized in console mode map to another keyB
silent! imap <unique> <C-n> <Plug>(SkipItForward)
silent! imap <unique> <C-p> <Plug>(SkipItBack)
silent! imap <unique> <C-g>n <Plug>(SkipAllForward)
silent! imap <unique> <C-g>p <Plug>(SkipAllBack)
