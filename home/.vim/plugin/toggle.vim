" Toggle undo tree
nmap gu :UndotreeToggle<CR>

" Toggle tagbar
nmap gT :TagbarToggle<CR>

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

nmap ,p :call TogglePaste()<CR>

func! TogglePaste()
  if &paste
    set nopaste
  else
    set paste
  end
endfunc

" Toggle tagbar
nmap <silent> gws :call TagbarRemoveTrailingWhiteSpace()<CR>

func! TagbarRemoveTrailingWhiteSpace()
  if b:strip_trailing_whitespace_enabled
    let b:strip_trailing_whitespace_enabled=0
  else
    let b:strip_trailing_whitespace_enabled=1
  end
endfunc

nmap gq :call ToggleQuickFix()<CR>

function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction

nmap gl :call ToggleLocList()<CR>

function! ToggleLocList()
    if empty(filter(getwininfo(), 'v:val.loclist'))
      if len(getloclist(0)) == 0
        echohl ErrorMsg
        echo "Location List is Empty."
        return
      endif

      lopen
    else
      lclose
    endif
endfunction
