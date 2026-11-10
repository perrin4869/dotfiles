-- yo-dawg is installed in the checkout's pack dir like any other plugin; the runner starts with `-u NONE`, so the pack
-- path has to be added before `packadd` can find it
vim.opt.packpath:prepend(vim.fn.getcwd() .. '/home/.local/share/nvim/site')
vim.cmd.packadd('yo-dawg.nvim')
