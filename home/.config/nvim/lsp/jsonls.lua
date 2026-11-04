return {
	commands = {
		Format = {
			function()
				vim.lsp.buf.format()
			end,
		},
	},
}
