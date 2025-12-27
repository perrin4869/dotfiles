local defer = require("defer")

defer.on_load("hlargs", function()
	require("hlargs").setup({
		disable = function(_, bufnr)
			if vim.b[bufnr].semantic_tokens then
				return true
			end

			local clients = vim.lsp.get_clients({ bufnr = bufnr })
			for _, c in pairs(clients) do
				local caps = c.server_capabilities
				if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
					-- cache languages that were already resolved
					vim.b[bufnr].semantic_tokens = true
					return vim.b[bufnr].semantic_tokens
				end
			end
		end,
	})
end)
defer.on_event("hlargs", { "BufReadPost", "BufNewFile" })

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_hlargs", {}),
	callback = function(args)
		local bufnr = args.buf
		if vim.b[bufnr].semantic_tokens then
			return
		end

		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local caps = client.server_capabilities
		if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
			vim.b[bufnr].semantic_tokens = true
			defer.require("hlargs").disable_buf(bufnr)
		end
	end,
})
