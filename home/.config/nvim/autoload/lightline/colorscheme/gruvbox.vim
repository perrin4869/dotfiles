let s:theme = v:lua.require("gruvbox.groups").setup(v:lua.require("gruvbox").config)

let s:bg0 = s:theme.GruvboxBg0.fg
let s:bg1 = s:theme.GruvboxBg1.fg
let s:bg2 = s:theme.GruvboxBg2.fg
let s:bg4 = s:theme.GruvboxBg4.fg
let s:fg1 = s:theme.GruvboxFg1.fg
let s:fg4 = s:theme.GruvboxFg4.fg

let s:yellow = s:theme.GruvboxYellow.fg
let s:blue = s:theme.GruvboxBlue.fg
let s:aqua = s:theme.GruvboxAqua.fg
let s:orange = s:theme.GruvboxOrange.fg
let s:red = s:theme.GruvboxRed.fg
let s:green = s:theme.GruvboxGreen.fg

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
