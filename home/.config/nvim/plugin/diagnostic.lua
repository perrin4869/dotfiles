local util = require("utils")

local opts = { noremap = true, silent = true }
local get_opts = util.create_get_opts(opts)

vim.diagnostic.config({
	float = { border = util.border },
	virtual_text = { current_line = true },
})

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, get_opts({ desc = "diagnostic.open_float" }))
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, get_opts({ desc = "diagnostic.setloclist" }))

-- This is nicer than having virtual text
-- https://www.reddit.com/r/neovim/comments/nr4y45/issue_with_diagnostics/
vim.api.nvim_create_autocmd("CursorHold", {
	callback = function()
		vim.diagnostic.open_float({ focusable = false })
	end,
})
