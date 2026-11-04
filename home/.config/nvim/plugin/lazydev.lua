local yall = require('yall')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		group = vim.api.nvim_create_augroup('Initialize_lazydev', {}),
		pattern = vim.lsp.config.emmylua_ls.filetypes,
		callback = function()
			vim.cmd.packadd('lazydev.nvim')
			-- vim.uv types come with $VIMRUNTIME (lua/uv/_meta.lua), which lazydev always adds
			require('lazydev').setup({})

			-- emmylua_ls keeps the last non-null of its `Lua` and `emmylua` sections, and lazydev fills `Lua`
			vim.lsp.config('emmylua_ls', { settings = { emmylua = vim.NIL } })
			vim.lsp.enable('emmylua_ls')
		end,
	})
end)
