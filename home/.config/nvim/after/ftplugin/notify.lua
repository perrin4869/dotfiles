-- replace w with q to close the window instead of moving out of it
vim.keymap.set("n", "q", "<CMD>wincmd w<CR>", { silent = true, buffer = true })
