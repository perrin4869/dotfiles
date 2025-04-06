vim.keymap.set("n", "<Space>p", function()
	vim.cmd("LivePreview start")
end, { noremap = true, buffer = true, silent = true, desc = "LivePreview start" })

vim.keymap.set("n", "<Space>P", function()
	vim.cmd("LivePreview close")
end, { noremap = true, buffer = true, silent = true, desc = "LivePreview stop" })
