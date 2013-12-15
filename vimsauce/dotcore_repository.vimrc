
" Add vim commands, mappings, functions, etc for this source
"
" Eg:

let g:current_dir = "~/websites/dotcore_repository.com"
exec 'cd ' . g:current_dir

" If using NERDTree:
exec 'NERDTree ' . g:current_dir

" From http://mwop.net/blog/134-exuberant-ctags-with-PHP-in-Vim.html
" The file paths in the index are created relative to the tags file; this was
" important, because if this wasn't provided, vim was unable to jump to the
" file, as it couldn't find it.
" --PHP-kinds=+cf tells it to index classes and functions.
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

" When the option is a comma separated list, a comma is added, unless the value was empty.
set tags+=~/websites/dotcore_repository.com/.php.tags

" for debugging purposes uncomment:
" let g:taggatron_verbose = 1

