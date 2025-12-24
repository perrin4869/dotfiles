-- replace w with q to close the window instead of moving out of it
vim.keymap.set("n", "q", function()
	vim.cmd.wincmd("w")
end, { silent = true, buffer = true })
