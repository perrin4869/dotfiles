function! ReturnHighlightTerm(group, term)
   " Store output of group to variable
   let output = execute('hi ' . a:group)

   " Find the term we're looking for
   return matchstr(output, a:term.'=\zs\S*')
endfunction

let s:bg0 = ReturnHighlightTerm('GruvboxBg0', 'guifg')
let s:bg1 = ReturnHighlightTerm('GruvboxBg1', 'guifg')
let s:bg2 = ReturnHighlightTerm('GruvboxBg2', 'guifg')
let s:bg4 = ReturnHighlightTerm('GruvboxBg4', 'guifg')
let s:fg1 = ReturnHighlightTerm('GruvboxFg1', 'guifg')
let s:fg4 = ReturnHighlightTerm('GruvboxFg4', 'guifg')

let s:yellow = ReturnHighlightTerm('GruvboxYellow', 'guifg')
let s:blue = ReturnHighlightTerm('GruvboxBlue', 'guifg')
let s:aqua = ReturnHighlightTerm('GruvboxAqua', 'guifg')
let s:orange = ReturnHighlightTerm('GruvboxOrange', 'guifg')
let s:red = ReturnHighlightTerm('GruvboxRed', 'guifg')
let s:green = ReturnHighlightTerm('GruvboxGreen', 'guifg')

let s:palette = {
    \ 'normal': {
    \   'left': [[s:bg0, s:fg4, 'bold'], [s:fg4, s:bg2]],
    \   'middle': [[s:fg4, s:bg1]],
    \   'right': [[s:bg0, s:fg4], [s:fg4, s:bg2]],
    \   'error': [[s:bg0, s:red]],
    \   'warning': [[s:bg0, s:yellow]]
    \ },
    \ 'insert': {
    \   'left': [[s:bg0, s:blue, 'bold'], [s:fg1, s:bg2]],
    \   'middle': [[s:fg4, s:bg1]],
    \   'right': [[s:bg0, s:blue], [s:fg1, s:bg2]]
    \ },
    \ 'inactive': {
    \   'left': [[s:bg4, s:bg1]],
    \   'middle': [[s:bg4, s:bg1]],
    \   'right': [[s:bg4, s:bg1], [s:bg4, s:bg1]]
    \ },
    \ 'terminal': {
    \   'left': [[s:bg0, s:green, 'bold'], [s:fg1, s:bg2]],
    \   'middle': [[s:fg4, s:bg1]],
    \   'right': [[s:bg0, s:green], [s:fg1, s:bg2]]
    \ },
    \ 'replace': {
    \   'left': [[s:bg0, s:aqua, 'bold'], [s:fg1, s:bg2]],
    \   'middle': [[s:fg4, s:bg1]],
    \   'right': [[s:bg0, s:aqua], [s:fg1, s:bg2]]
    \ },
    \ 'visual': {
    \   'left': [[s:bg0, s:orange, 'bold'], [s:bg0, s:bg4]],
    \   'middle': [[s:fg4, s:bg1]],
    \   'right': [[s:bg0, s:orange], [s:bg0, s:bg4]]
    \ },
    \ 'tabline': {
    \   'left': [[s:fg4, s:bg2]],
    \   'middle': [[s:bg0, s:bg4]],
    \   'right': [[s:bg0, s:orange]],
    \   'tabsel': [[s:bg0, s:fg4]]
    \ }
  \ }

let g:lightline#colorscheme#gruvbox#palette = lightline#colorscheme#fill(s:palette)
