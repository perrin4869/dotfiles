local config = require("lspconfig")
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

		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, get_opts({ desc = "lsp.declaration" }))
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, get_opts({ desc = "lsp.definition" }))
		vim.keymap.set("n", "K", vim.lsp.buf.hover, get_opts({ desc = "lsp.hover" }))
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, get_opts({ desc = "lsp.implementation" }))
		vim.keymap.set("n", "gk", vim.lsp.buf.signature_help, get_opts({ desc = "lsp.signature_help" }))
		vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, get_opts({ desc = "lsp.signature_help" }))
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
		vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, get_opts({ desc = "lsp.type_definition" }))
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, get_opts({ desc = "lsp.rename" }))
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, get_opts({ desc = "lsp.code_action" }))
		vim.keymap.set("n", "gr", vim.lsp.buf.references, get_opts({ desc = "lsp.references" }))
		-- buf_set_keymap('n', '<leader>ds', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
		-- buf_set_keymap('n', '<leader>ws', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
		-- https://www.reddit.com/r/neovim/comments/pdiflv/search_workspace_symbols/
		vim.keymap.set(
			"n",
			"<leader>ds",
			require("telescope.builtin").lsp_document_symbols,
			get_opts({ desc = "telescope.lsp_document_symbols" })
		)
		vim.keymap.set(
			"n",
			"<leader>ws",
			require("telescope.builtin").lsp_dynamic_workspace_symbols,
			get_opts({ desc = "telescope.lsp_dynamic_workspace_symbols" })
		)
		-- https://github.com/nvim-telescope/telescope.nvim/issues/964
		-- uses dynamic because most language servers return an empty list on an empty query

		if client ~= nil and client.server_capabilities.inlayHintProvider then
			vim.keymap.set("n", "<leader>i", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
			end, { silent = true, buffer = bufnr, desc = "lsp.inlayhints.toggle" })
			-- this is too verbose, so do not enable this by default
			-- vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		if client ~= nil and client.server_capabilities.codeLensProvider then
			vim.api.nvim_create_augroup("lsp_codelens", { clear = false })
			vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_codelens" })
			vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
				group = "lsp_codelens",
				buffer = bufnr,
				callback = vim.lsp.codelens.refresh,
			})

			vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, get_opts({ desc = "lsp.codelens.run" }))
		end
	end,
})

-- luacheck: push ignore 122
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	virtual_text = false,
	signs = true,
	update_in_insert = false,
})
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = utils.border,
})
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
	border = utils.border,
})
-- luacheck: pop

require("mason").setup({
	registries = {
		"file:" .. vim.fs.joinpath(vim.fn.stdpath("data"), "mason-registry"),
	},
})
require("mason-lspconfig").setup({ automatic_installation = true })

local capabilities = lsp.capabilities

config.bashls.setup({ capabilities = capabilities })
config.vimls.setup({ capabilities = capabilities })
config.html.setup({ capabilities = capabilities })
config.kotlin_language_server.setup({ capabilities = capabilities })

config.cssls.setup({
	capabilities = capabilities,
	settings = {
		css = {
			validate = false,
		},
		less = {
			validate = true,
		},
		scss = {
			validate = true,
		},
	},
})

config.jsonls.setup({
	capabilities = capabilities,
	commands = {
		Format = {
			function()
				vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line("$"), 0 })
			end,
		},
	},
})
config.sqlls.setup({
	capabilities = capabilities,
	cmd = { "sql-language-server", "up", "--method", "stdio" },
})

vim.api.nvim_create_autocmd("FileType", {
	once = true,
	pattern = "lua",
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
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	once = true,
	pattern = "lua",
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
	end,
})

config.lua_ls.setup({
	settings = {
		Lua = {
			completion = {
				callSnippet = "Replace",
			},
		},
	},
})

vim.api.nvim_create_autocmd("FileType", {
	once = true,
	pattern = "typescript",
	callback = function()
		vim.cmd([[
			packadd nvim-vtsls
		]])
	end,
})

config.vtsls.setup({
	capabilities = capabilities,
	settings = {
		typescript = {
			inlayHints = {
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
			referencesCodeLens = {
				enabled = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
		},
		javascript = {
			inlayHints = {
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
			referencesCodeLens = {
				enabled = true,
			},
		},
	},
})

require("ccls").setup()
config.ccls.setup({ capabilities = capabilities })
