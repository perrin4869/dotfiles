local yall = require('yall')
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		once = true,
		group = vim.api.nvim_create_augroup('Initialize_lazydev', {}),
		pattern = (vim.lsp.config --[[@as table<string, vim.lsp.Config>]])['emmylua_ls'].filetypes,
		callback = function()
			vim.cmd.packadd('lazydev.nvim')
			-- vim.uv types come with $VIMRUNTIME (lua/uv/_meta.lua), which lazydev always adds; the rest is for specs,
			-- so it loads on their words or on the module they require rather than in every Lua file
			local spec = vim.fn.stdpath('config') .. '/spec'
			require('lazydev').setup({
				library = {
					{ path = spec .. '/libs/yo-dawg.nvim/lua', mods = { 'yo-dawg' } },
					{ path = spec .. '/libs/busted/library', words = { 'describe' } },
					{ path = spec .. '/libs/luassert/library', words = { 'assert' } },
					{ path = spec .. '/types', words = { 'assert' } },
				},
			})

			-- emmylua_ls keeps the last non-null of its `Lua` and `emmylua` sections, and lazydev fills `Lua`
			vim.lsp.config('emmylua_ls', { settings = { emmylua = vim.NIL } })
			vim.lsp.enable('emmylua_ls')
		end,
	})
end)
