local yall = require('yall')
yall.deps('ccls', 'lspconfig')
yall.on_load('ccls', function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		pattern = vim.lsp.config.ccls.filetypes,
		callback = function()
			vim.cmd.packadd('ccls.nvim')
			require('ccls').setup()

			vim.lsp.enable('ccls')
		end,
	})
end)
yall.on_bufreadpre('ccls')
