"Here go all my mappings:

let mapleader=','

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
nmap <Leader>c :BD<CR>

"move easily between buffers
nnoremap <Leader>n :bn<CR>
nnoremap <Leader>p :bp<CR>

"move back to NERDTree easily (assuming it's the top left window)
nnoremap gn <C-w>t

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

"make moving between buffers easier
nnoremap <Tab> :bn<CR>
nnoremap <S-Tab> :bp<CR>

"allow deleting characters in insert mode (simulating <Del>)
"<C-o> allows you to execute one command in normal mode before returning to
"insert mode
imap <C-d> <C-o>x

" easier motions in insert-mode
" imap <C-j> <C-o>j
" imap <C-k> <C-o>k
" imap <C-h> <C-o>h
" imap <C-l> <C-o>l
" Support normal copy of text into clipboard in gui mode
vmap <C-c> "+y<Esc>l
vmap <C-x> "+d<Esc>l
imap <C-v> <Esc>"+pa

" ctrl-a selects all the text
nmap <C-a> <Esc>ggVGi

"automatically start editing bracket blocks
imap <C-l> {}<Esc>i<CR><Esc>O

"folding
nnoremap <Space> za
vnoremap <Space> zf

"This unsets the "last search pattern" register by hitting return
nnoremap <silent> <CR> :noh<CR>

" ycm
" let g:ycm_key_invoke_completion = '<C-s>' " Ctrl-suggest - doesn't work
" because C-s freezes the command line
let g:ycm_key_invoke_completion = '<C-h>'
" let g:ycm_key_list_select_completion = ['<C-j>']
" let g:ycm_key_list_previous_completion = ['<C-k>']
let g:ycm_key_list_select_completion = ['<Tab>']
let g:ycm_key_list_previous_completion = ['<S-Tab>']

"make ycm play nice with ultisnips
" let g:UltiSnipsExpandTrigger="<Tab>"
" let g:UltiSnipsJumpForwardTrigger="<Tab>"
" let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

"make sure the key to trigger easy motion is <leader> and not <leader><leader>
"as default
let g:EasyMotion_leader_key = '<Leader>'

