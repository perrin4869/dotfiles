" Toggle strip trailing whitespace
nmap <silent> <leader>ts <cmd>call ToggleRemoveTrailingWhiteSpace()<CR>

func! TagbarRemoveTrailingWhiteSpace()
  if b:strip_trailing_whitespace_enabled
    let b:strip_trailing_whitespace_enabled=0
  else
    let b:strip_trailing_whitespace_enabled=1
  end
endfunc
