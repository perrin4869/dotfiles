
" Add vim commands, mappings, functions, etc for this source
"
" Eg:

let g:current_dir = "~/websites/coddress"
exec 'cd ' . g:current_dir

" make html snippets available when editting php files
autocmd FileType php UltiSnipsAddFiletypes php.html
au BufRead *.php set ft=php.html
au BufNewFile *.php set ft=php.html

" From http://mwop.net/blog/134-exuberant-ctags-with-PHP-in-Vim.html
" The file paths in the index are created relative to the tags file; this was
" important, because if this wasn't provided, vim was unable to jump to the
" file, as it couldn't find it.
" --PHP-kinds=+cf tells it to index classes and functions.

" Autogenerate tags using taggatron
let g:tagcommands = {
\	"php" : {
\		"tagfile" :  ".php.tags",
\		"args" : "-R --exclude=\"\.git\" --totals=yes --tag-relative=yes --PHP-kinds=+cf ",
\		"cmd" : "ctags",
\		"filesappend" : "**"
\	},
\	"javascript" : {
\		"tagfile" : ".js.tags",
\		"args" : "-R --exclude=\"\.git\"",
\		"filesappend" : "**",
\		"cmd" : "ctags"
\	}
\}

" for debugging purposes uncomment:
" let g:taggatron_verbose = 1

" For omnicomplete
" When the option is a comma separated list, a comma is added, unless the value was empty.
set tags+=~/websites/dotcore_repository.com/.php.tags
set tags+=~/websites/dotcore_repository.com/.js.tags

" If using NERDTree:
exec 'NERDTree ' . g:current_dir
