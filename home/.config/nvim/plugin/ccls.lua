local defer = require("defer")
defer.on_load("ccls", function()
	vim.api.nvim_create_autocmd("FileType", {
		once = true,
		pattern = vim.lsp.config.ccls.filetypes,
		callback = function()
			vim.cmd.packadd("ccls.nvim")
			require("ccls").setup()

			vim.lsp.enable("ccls")
		end,
	})
end)
defer.on_event("ccls", { "BufReadPre", "BufNewFile" })
