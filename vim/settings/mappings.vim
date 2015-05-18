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

" DelimitMate mappings

" Since S-Tab is not recognized in console mode map to another key
" <C-n> and <C-p> are used for navigating the pum forwards and backwards so
" they are not available
silent! imap <unique> <C-d> <Plug>delimitMateS-Tab

" Additional Ctrlp mapping
nmap <Leader>p <C-p>

" easy-align mappings
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)
"
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Simple Ag mapping
nmap <Leader>a :Ag 

" Toggles
imap <C-r> <c-o>:call ToggleRl()<cr>
 
func! ToggleRl()
	if &rl
		set norl
	else
		set rl
	end
endfunc

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
