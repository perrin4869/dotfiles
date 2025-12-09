" Toggle undo tree
nmap <silent> gu <cmd>UndotreeToggle<CR>

" Toggle tagbar
nmap <silent> gT <cmd>TagbarToggle<CR>

" <C-r> is by default used in insert mode for pasting registers so let's not
" meddle with that
imap <silent> <C-l> <C-o>:call ToggleRl()<CR>

func! ToggleRl()
  if &rl
    set norl
  else
    set rl
  end
endfunc

" Toggle rl
nmap <silent> ]r <cmd>set rl<CR>
nmap <silent> [r <cmd>set norl<CR>

nmap <silent> <leader>p <cmd>call TogglePaste()<CR>

func! TogglePaste()
  if &paste
    set nopaste
  else
    set paste
  end
endfunc

" Toggle tagbar
nmap <silent> gws <cmd>call TagbarRemoveTrailingWhiteSpace()<CR>

func! TagbarRemoveTrailingWhiteSpace()
  if b:strip_trailing_whitespace_enabled
    let b:strip_trailing_whitespace_enabled=0
  else
    let b:strip_trailing_whitespace_enabled=1
  end
endfunc

nmap <silent> gq <cmd>call ToggleQuickFix()<CR>

function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction

nmap <silent> gl <cmd>call ToggleLocList()<CR>

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
