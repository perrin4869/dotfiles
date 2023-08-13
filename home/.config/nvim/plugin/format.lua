local lsp_format = require("lsp-format")
local utils = require("utils")

local formatting_supported = function(client)
	return client.server_capabilities.documentFormattingProvider
		or client.server_capabilities.documentRangeFormattingProvider
end

lsp_format.setup()

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_format", {}),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		lsp_format.on_attach(client)

		local bufnr = args.buf
		local opts = { silent = true, buffer = bufnr }
		local get_opts = utils.create_get_opts(opts)

		-- Set some keybinds conditional on server capabilities
		if formatting_supported(client) then
			vim.keymap.set("n", "<leader>f", function()
				lsp_format.format({})
			end, get_opts({ desc = "lsp.format" }))
		end
	end,
})
