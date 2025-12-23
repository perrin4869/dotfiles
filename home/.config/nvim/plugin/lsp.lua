local lsp = require("lsp")
local utils = require("utils")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_general", { clear = true }),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufnr = args.buf

		vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })

		-- Mappings.
		local opts = { silent = true, buffer = bufnr }
		local get_opts = utils.create_get_opts(opts)

		local signature_help = function()
			vim.lsp.buf.signature_help({ border = utils.border })
		end

		local hover = function()
			vim.lsp.buf.hover({ border = utils.border })
		end

		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, get_opts({ desc = "lsp.declaration" }))
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, get_opts({ desc = "lsp.definition" }))
		vim.keymap.set("n", "K", hover, get_opts({ desc = "lsp.hover" }))
		vim.keymap.set("n", "gk", signature_help, get_opts({ desc = "lsp.signature_help" }))
		vim.keymap.set(
			"n",
			"<leader>wa",
			vim.lsp.buf.add_workspace_folder,
			get_opts({ desc = "lsp.add_workspace_folder" })
		)
		vim.keymap.set(
			"n",
			"<leader>wr",
			vim.lsp.buf.remove_workspace_folder,
			get_opts({ desc = "lsp.remove_workspace_folder" })
		)
		vim.keymap.set("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, get_opts({ desc = "lsp.list_workspace_folders" }))
		-- buf_set_keymap('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
		-- buf_set_keymap('n', '<leader>ws', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
		-- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
		local pickers = require("pickers")
		pickers.map("<leader>ds", "lsp_document_symbols", { prefix = false })
		pickers.map("<leader>ws", "lsp_dynamic_workspace_symbols", { prefix = false })
		-- https://github.com/nvim-telescope/telescope.nvim/issues/964
		-- uses dynamic because most language servers return an empty list on an empty query

		if client ~= nil then
			vim.diagnostic.config({
				underline = true,
				virtual_text = false,
				virtual_lines = { current_line = true },
				signs = true,
				update_in_insert = false,
			}, vim.lsp.diagnostic.get_namespace(client.id))
		end

		if client ~= nil and client.server_capabilities.inlayHintProvider then
			vim.keymap.set("n", "<leader>i", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
			end, { silent = true, buffer = bufnr, desc = "lsp.inlayhints.toggle" })
			-- this is too verbose, so do not enable this by default
			-- vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		if client ~= nil and client:supports_method("textDocument/codeLens", { bufnr = bufnr }) then
			local group = vim.api.nvim_create_augroup("lsp_codelens", { clear = false })
			vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
			-- https://github.com/LunarVim/LunarVim/pull/2600
			vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
				group = group,
				buffer = bufnr,
				callback = function()
					vim.lsp.codelens.refresh({ bufnr = bufnr })
				end,
			})

			vim.keymap.set("n", "grc", vim.lsp.codelens.run, get_opts({ desc = "lsp.codelens.run" }))
		end
	end,
})

require("mason").setup({
	registries = {
		"file:" .. vim.fs.joinpath(vim.fn.stdpath("data"), "mason-registry"),
	},
})

vim.lsp.config("*", {
	capabilities = lsp.capabilities,
})

vim.lsp.enable({
	"bashls",
	"vimls",
	"html",
	"kotlin_lsp",
	"cssls",
	"jsonls",
	"sqlls",
})
