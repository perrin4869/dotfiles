" lightline-bufferline requires this
set showtabline=2

let g:lightline = {}

let g:lightline.colorscheme = g:colors_name " help colorscheme
let g:lightline.active = {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitgutter', 'gitbranch' ],
      \             [ 'lsp', 'metals' ],
      \             [ 'vimtex', 'gutentags' ],
      \             [ 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'lineinfo' ],
      \              [ 'percent' ],
      \              [ 'fileformat', 'fileencoding', 'filetype' ],
      \              [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_infos', 'linter_ok' ]],
      \ }
let g:lightline.component = {
      \   'lineinfo': ' %3l:%-2v'
      \ }
let g:lightline.component_function = {
      \   'gitbranch': 'LightLineFugitive',
      \   'gitgutter': 'LightLineGitGutter',
      \   'lsp': 'LightLineLsp',
      \   'metals': 'LightLineMetals',
      \   'vimtex': 'LightLineVimTex',
      \   'gutentags': 'gutentags#statusline',
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
  let _ = FugitiveHead()
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

augroup MyGutentagsStatusLineRefresher
  autocmd!
  autocmd User GutentagsUpdating call lightline#update()
  autocmd User GutentagsUpdated call lightline#update()
augroup END

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
endfunction

function! LightlineFileencoding()
  return winwidth(0) > 70 ? (&fenc !=# '' ? &fenc : &enc) : ''
endfunction
