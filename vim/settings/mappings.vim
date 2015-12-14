" Easily exit insert mode
inoremap <C-l> <Esc>

" Convenience
nnoremap ; :

" Unmap the arrow keys
no <down> ddp
no <left> <Nop>
no <right> <Nop>
no <up> ddkP
ino <down> <Nop>
ino <left> <Nop>
ino <right> <Nop>
ino <up> <Nop>
vno <down> <Nop>
vno <left> <Nop>
vno <right> <Nop>
vno <up> <Nop>

"close current buffer with bufkill
nnoremap <C-c> :BD<CR> 
nnoremap <Leader>c :BD<CR> 

"make moving between splits easier
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

"I really hate that things don't auto-center
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap } }zz
nmap { {zz

"make mappings for display lines
"These mappings make it easy to move along long lines
vmap <M-j> gj
vmap <M-k> gk
vmap <M-4> g$
vmap <M-6> g^
vmap <M-0> g^
nmap <M-j> gj
nmap <M-k> gk
nmap <M-4> g$
nmap <M-6> g^
nmap <M-0> g^

"make moving between buffers easier
nnoremap <Tab> :bn<CR>
nnoremap <S-Tab> :bp<CR>

"folding
nnoremap <Space> za
vnoremap <Space> zf

"This unsets the "last search pattern" register by hitting return
nnoremap <silent> <backspace> :noh<CR>

"Make it easier to restart Ycm
nnoremap <F2> :YcmRestartServer<CR>


" let g:ycm_key_invoke_completion = '<C-s>' " Ctrl-suggest - doesn't work
" because C-s freezes the command line
let g:ycm_key_invoke_completion = '<C-h>'
" let g:ycm_key_list_select_completion = ['<C-j>']
" let g:ycm_key_list_previous_completion = ['<C-k>']
let g:ycm_key_list_select_completion = ['<Tab>']
let g:ycm_key_list_previous_completion = ['<S-Tab>']

" Ultisnips
" let g:UltiSnipsExpandTrigger="<Tab>"
" let g:UltiSnipsJumpForwardTrigger="<Tab>"
" let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-f>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

" Easymotion
"make sure the key to trigger easy motion is <leader> and not <leader><leader>
"as default
let g:EasyMotion_leader_key = '<Leader>'

" easymotion style search
" Gif config
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
map  n <Plug>(easymotion-next)
map  N <Plug>(easymotion-prev)

" Ctrlp options
let g:ctrlp_map = '<c-p>'

" skipit mappings

" Since S-Tab is not recognized in console mode map to another key
" <C-n> and <C-p> are used for navigating the pum forwards and backwards so
" they are not available
silent! imap <unique> <C-k> <Plug>SkipItForward
silent! imap <unique> <C-j> <Plug>SkipItBack
silent! imap <unique> <C-g>k <Plug>SkipAllForward
silent! imap <unique> <C-g>j <Plug>SkipAllBack

" easy-align mappings
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)
"
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Toggles

" <C-r> is by default used in insert mode for pasting registers so let's not
" meddle with that
imap <C-l> <C-o>:call ToggleRl()<CR>
 
func! ToggleRl()
	if &rl
		set norl
	else
		set rl
	end
endfunc

" Toggle rl
nmap ]r :set rl<CR>
nmap [r :set norl<CR>

" Simple Ag mapping
nmap <Leader>a :Ag 

" Bring up NERDTree on the current working directory (the current project)
nnoremap <Leader>n :NERDTreeToggle<CR> 
nnoremap <C-n> :NERDTreeFocus<CR> 

" Toggle relative numbers
nmap <Leader>r :call ToggleRnu()<CR>

func! ToggleRnu()
	if &rnu
		set nornu
	else
		set rnu
	end
endfunc

" Toggle undo tree
nmap <Leader>u :UndotreeToggle<cr>

" Toggle tagbar
nmap <Leader>t :TagbarToggle<CR>

" Unite toggle mappings

" The prefix key.
nnoremap [unite] <Nop>
nmap <Leader>u [unite]
" async requires vimproc to be installed
nnoremap [unite]f :Unite -start-insert file_rec/async<CR>
nnoremap [unite]g :Unite -start-insert grep:.<cr>
nnoremap [unite]b :Unite -start-insert buffer<cr>
nnoremap [unite]m :Unite file_mru<CR>
" show lines of current file
nnoremap [unite]l :Unite line<CR>
" search (like ack.vim/ag.vim)
nnoremap [unite]/ :Unite grep:.<CR>
" Yank (like yankring/yankstack)
let g:unite_source_history_yank_enable = 1
nnoremap [unite]y :Unite history/yank<CR>

nmap <Leader>f [unite]f
nmap <Leader>g [unite]g
