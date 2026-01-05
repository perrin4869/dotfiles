" Toggle tagbar
nmap <silent> <leader>tt <cmd>TagbarToggle<CR>

" <C-r> is by default used in insert mode for pasting registers so let's not
" meddle with that
imap <silent> <C-l> <cmd>call ToggleRl()<CR>
nmap <silent> <leader>tr <cmd>call ToggleRl()<CR>

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

nmap <silent> <leader>tp <cmd>call TogglePaste()<CR>

func! TogglePaste()
  if &paste
    set nopaste
  else
    set paste
  end
endfunc

nmap <silent> <leader>tq <cmd>call ToggleQuickFix()<CR>

function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction

nmap <silent> <leader>tl <cmd>call ToggleLocList()<CR>

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
