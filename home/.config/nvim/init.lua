vim.cmd.source('~/.vimrc')

-- This works by default on vim8
vim.opt.mouse = 'a'

vim.loader.enable()
-- nvim 0.5 undo files are incompatible with vim8
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'

-- Local, untracked package root for plugins under development: symlink or
-- clone a plugin into site-local/pack/dev/{start,opt}/<name> to load it the
-- same way as the managed plugins under pack/default/{start,opt}.
-- Set NVIM_NO_LOCAL_PLUGINS to skip this for a single session.
if vim.env.NVIM_NO_LOCAL_PLUGINS == nil then
	vim.opt.packpath:append(vim.fn.stdpath('data') .. '/site-local')
end
