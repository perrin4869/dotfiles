local metals = require("metals")
local handlers = require("metals.handlers")
local tvp = require("metals.tvp")
local lsp = require("lsp")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_metals", {}),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil or client.name ~= "metals" then
			return
		end

		local bufnr = args.buf
		local opts = { noremap = true, silent = true, buffer = bufnr }

		-- Toggle panel with Tree Views
		vim.keymap.set("n", "gtv", tvp.toggle_tree_view, opts)
		-- Reveal current current class (trait or object) in Tree View 'metalsPackages'
		vim.keymap.set("n", "gtf", tvp.reveal_in_tree, opts)

		vim.keymap.set("n", "<leader><leader>m", require("telescope").extensions.metals.commands, opts)
		vim.keymap.set("n", "gtt", "<cmd>MetalsSelectTestSuite<cr>", opts)
		vim.keymap.set("n", "gtc", "<cmd>MetalsSelectTestCase<cr>", opts)

		vim.keymap.set("n", "<leader>o", metals.organize_imports, opts)
		vim.api.nvim_buf_create_user_command(bufnr, "OR", metals.organize_imports, { nargs = 0 })

		metals.setup_dap()
	end,
})

local metals_config = metals.bare_config()
metals_config.capabilities = lsp.capabilities
metals_config.init_options.statusBarProvider = "on"
metals_config.handlers = {
	["metals/status"] = function(...)
		handlers["metals/status"](...)
		vim.fn["lightline#update"]()
	end,
}
metals_config.settings = {
	useGlobalExecutable = true,
	verboseCompilation = true,
	enableSemanticHighlighting = true,
	superMethodLensesEnabled = true,
	testUserInterface = "Test Explorer",
	defaultBspToBuildTool = true,
	enableBestEffort = true,
	inlayHints = {
		byNameParameters = { enable = true },
		hintsInPatternMatch = { enable = true },
		implicitArguments = { enable = true },
		implicitConversions = { enable = true },
		inferredTypes = { enable = true },
		typeParameters = { enable = true },
	},
}

metals.initialize_or_attach(metals_config)
