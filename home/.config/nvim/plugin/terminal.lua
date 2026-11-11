-- Make escape work in the Neovim terminal.
-- Esc is useful in zsh in vim-mode, so use <C-o> instead
-- <Esc><Esc> makes a single <Esc> be delayed, not ideal
require('map').map('t', '<C-o>', '<C-\\><C-n>')

-- autocmd TermOpen * startinsert
-- Prefer Neovim terminal insert mode to normal mode.
vim.api.nvim_create_autocmd('TermOpen', {
	pattern = '*',
	callback = function()
		vim.cmd('startinsert')
	end,
})
-- autocmd TermOpen * startinsert

-- A terminal emulator can lose a button release and then report every movement of the pointer as a drag with that
-- button held (Ghostty does, ghostty-org/ghostty#12078). A drag is not a movement, so Neovim answers it by leaving
-- terminal mode, and the terminal sits in normal mode while the pointer merely moves. The extra buttons mean nothing
-- inside a terminal, so swallow their drags before Neovim's terminal handling acts on them.
require('map').map('t', '<X1Drag>', '<Nop>')
require('map').map('t', '<X2Drag>', '<Nop>')
