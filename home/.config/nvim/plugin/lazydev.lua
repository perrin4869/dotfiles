local defer = require("defer")
defer.very_lazy(function()
	vim.api.nvim_create_autocmd("FileType", {
		once = true,
		group = vim.api.nvim_create_augroup("Initialize_lazydev", {}),
		pattern = vim.lsp.config.lua_ls.filetypes,
		callback = function()
			vim.cmd([[
			packadd lazydev.nvim
			packadd luvit-meta
		]])

			require("lazydev").setup({
				library = {
					-- Library items can be absolute paths
					-- "~/projects/my-awesome-lib",
					-- Or relative, which means they will be resolved as a plugin
					-- "LazyVim",
					-- When relative, you can also provide a path to the library in the plugin dir
					"luvit-meta/library", -- see below
				},
			})

			vim.lsp.enable("lua_ls")
		end,
	})
end)
