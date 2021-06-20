" Coc
setl formatexpr=CocAction('formatSelected')

" airbnb eslint compatible
setlocal expandtab
setlocal shiftwidth=4
setlocal tabstop=4

" jsdoc mappings
let g:jsdoc_default_mapping=0
let g:jsdoc_allow_input_prompt=1
let g:jsdoc_input_description=1
nnoremap <buffer> <leader>d :JsDoc<CR>

" let b:ale_fixers = ['prettier', 'eslint']
let b:ale_linters = ['eslint']
let b:ale_fixers = ['eslint']
let b:ale_fix_on_save = 1

let g:ale_javascript_eslint_use_global = 1
let g:ale_javascript_eslint_executable = 'eslint_d'
