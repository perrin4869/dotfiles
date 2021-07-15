" Set lexima mappings manually since they conflict with <CR>
let g:lexima_no_default_rules = 1

" Manually sets the mappings
call lexima#set_default_rules()
" https://github.com/cohama/lexima.vim/issues/65
call lexima#insmode#map_hook('before', '<CR>', '')
