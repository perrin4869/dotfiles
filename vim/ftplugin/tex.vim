" this is mostly a matter of taste. but LaTeX looks good with just a bit
" of indentation.
set sw=2

" Add triggers to ycm for LaTeX-Box autocompletion
let g:ycm_semantic_triggers = {
\  'tex'  : ['{'],
\ }

"suggested mappings
imap <buffer> [[     \begin{
imap <buffer> ]]     <Plug>LatexCloseCurEnv
nmap <buffer> <F5>   <Plug>LatexChangeEnv
vmap <buffer> <F7>   <Plug>LatexWrapSelection
vmap <buffer> <S-F7> <Plug>LatexEnvWrapSelection
imap <buffer> ((     \eqref{

let maplocalleader=','

map  <silent> <buffer> <C-f> :call LatexBox_JumpToNextBraces(0)<CR>
map  <silent> <buffer> <C-d> :call LatexBox_JumpToNextBraces(1)<CR>
imap <silent> <buffer> <C-f> <C-R>=LatexBox_JumpToNextBraces(0)<CR>
imap <silent> <buffer> <C-d> <C-R>=LatexBox_JumpToNextBraces(1)<CR>

let g:LatexBox_Folding=1
let g:LatexBox_latexmk_async=1
let g:LatexBox_latexmk_preview_continuously=1
let g:LatexBox_quickfix=2
let g:LatexBox_latexmk_options='-pdfdvi'

