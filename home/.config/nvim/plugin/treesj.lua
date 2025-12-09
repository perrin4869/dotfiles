require("treesj").setup({
	use_default_keymaps = false,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		-- <Leader>s is used for flash.nvim
		vim.keymap.set("n", "<leader>mm", require("treesj").toggle, { buffer = args.buf, desc = "treesj.toggle" })
		vim.keymap.set("n", "<leader>mj", require("treesj").join, { buffer = args.buf, desc = "treesj.join" })
		vim.keymap.set("n", "<leader>ms", require("treesj").split, { buffer = args.buf, desc = "treesj.split" })
	end,
})
