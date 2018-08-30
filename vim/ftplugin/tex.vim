" this is mostly a matter of taste. but LaTeX looks good with just a bit
" of indentation.
setlocal sw=2
setlocal ts=2

" Add triggers to ycm for LaTeX-Box autocompletion
let g:ycm_semantic_triggers = {
\  'tex'  : ['{'],
\ }

" vimtex uses <localleader> on their default mappings
let maplocalleader=',' 

let g:vimtex_fold_enabled=1
let g:vimtex_fold_manual=1
let g:vimtex_compiler_latexmk={
  \   'callback': 0,
  \   'options': [
  \     '-pdfdvi'
  \   ]
  \ }

" Add custom surrounds
" Maps to u for underscore and o for overscore
let g:surround_117="_{\r}"
let g:surround_111="_{\r}"
let g:surround_101="\\begin{\1environment: \1}\r\\end{\1\1}"
let g:surround_99="\\\1command: \1{\r}"
