vim.api.nvim_create_autocmd("FileType", {
	once = true,
	pattern = vim.lsp.config.ccls.filetypes,
	callback = function()
		require("ccls").setup()

		vim.lsp.enable("ccls")
	end,
})
