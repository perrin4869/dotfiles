require("treesj").setup({
	use_default_keymaps = false,
})

-- <Leader>s is used for flash.nvim
vim.keymap.set("n", "<leader>mm", require("treesj").toggle)
vim.keymap.set("n", "<leader>mj", require("treesj").join)
vim.keymap.set("n", "<leader>ms", require("treesj").split)
