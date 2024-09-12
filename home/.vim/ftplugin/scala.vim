" Metals diagnostics are displayed by coc.nvim
" let b:ale_linters = ['metals', 'sbtserver']
let b:ale_linters = ['sbtserver']
let b:ale_fixers = []
" Use nailgun to improve performance, using metals for now
" let b:ale_fixers = ['scalafmt']
" let b:ale_fix_on_save = 1

" use rg to search for lines that import the provided text,
" then on selection, append that text to the top of the file
function! s:insert_import(line)
	call append(2, a:line)
endfunction
