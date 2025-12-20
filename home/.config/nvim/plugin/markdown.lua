vim.g.render_markdown_config = {
	completions = { lsp = { enabled = true } },
}

vim.api.nvim_create_autocmd("FileType", {
	once = true,
	group = vim.api.nvim_create_augroup("Initialize_render_markdown", {}),
	pattern = "markdown",
	callback = function()
		vim.cmd.packadd("render-markdown.nvim")
	end,
})
