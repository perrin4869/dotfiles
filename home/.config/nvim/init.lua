vim.cmd.source('~/.vimrc')

-- This works by default on vim8
vim.opt.mouse = 'a'

vim.loader.enable()
-- nvim 0.5 undo files are incompatible with vim8
vim.opt.undodir = vim.fn.stdpath('data') .. '/undo'
