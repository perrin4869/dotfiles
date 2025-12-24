local defer = require("defer")
defer.on_event(function()
	vim.api.nvim_create_autocmd("FileType", {
		once = true,
		pattern = vim.lsp.config.ccls.filetypes,
		callback = function()
			vim.cmd.packadd("ccls.nvim")
			require("ccls").setup()

			vim.lsp.enable("ccls")
		end,
	})
end, { "BufReadPre", "BufNewFile" }, { name = "ccls" })
