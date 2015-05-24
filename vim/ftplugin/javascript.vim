" jsdoc mappings
let g:jsdoc_default_mapping=0
let g:jsdoc_allow_input_prompt=1
let g:jsdoc_input_description=1
nnoremap <buffer> <Leader>d :JsDoc<CR>

let g:syntastic_javascript_checkers = ['jshint', 'jslint']
