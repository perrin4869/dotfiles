local yall = require('yall')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		group = vim.api.nvim_create_augroup('Initialize_lazydev', {}),
		pattern = vim.lsp.config.lua_ls.filetypes,
		callback = function()
			vim.cmd.packadd('lazydev.nvim')
			-- vim.uv types come with $VIMRUNTIME (lua/uv/_meta.lua), which lazydev always adds
			require('lazydev').setup({})

			vim.lsp.enable('lua_ls')
		end,
	})
end)
