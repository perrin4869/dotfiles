-- Make escape work in the Neovim terminal.
-- Esc is useful in zsh in vim-mode, so use <C-o> instead
-- <Esc><Esc> makes a single <Esc> be delayed, so not ideal
require('map').map('t', '<C-o>', '<C-\\><C-n>')

-- autocmd TermOpen * startinsert
-- Prefer Neovim terminal insert mode to normal mode.
vim.api.nvim_create_autocmd('TermOpen', {
	pattern = '*',
	callback = function()
		vim.cmd.startinsert()
	end,
})
-- autocmd TermOpen * startinsert
