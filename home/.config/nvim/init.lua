vim.cmd.source('~/.vimrc')

-- This works by default on vim8
vim.opt.mouse = 'a'

vim.loader.enable()
require('vim._core.ui2').enable({
	enable = true,
	msg = {
		targets = 'msg',
	},
})
vim.opt.winborder = 'rounded'
vim.opt.completeopt:append('popup')

-- nvim 0.5 undo files are incompatible with vim8
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'
