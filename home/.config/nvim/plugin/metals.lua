local defer = require("defer")

local metals_config = defer.lazy(function()
	local lsp = require("lsp")
	local metals = require("metals")
	local handlers = require("metals.handlers")

	local config = metals.bare_config()
	config.capabilities = lsp.get_capabilities()
	config.init_options.statusBarProvider = "on"
	config.handlers = {
		["metals/status"] = function(...)
			handlers["metals/status"](...)
			require("lualine").refresh()
		end,
	}
	config.settings = {
		useGlobalExecutable = true,
		verboseCompilation = true,
		enableSemanticHighlighting = true,
		superMethodLensesEnabled = true,
		-- enables using MetalsSelectTestSuite and MetalsSelectTestCase
		-- but deactivates code lenses for test classes.
		-- testUserInterface = "Test Explorer",
		defaultBspToBuildTool = true,
		enableBestEffort = true,
		inlayHints = {
			namedParameters = { enable = true },
			byNameParameters = { enable = true },
			hintsInPatternMatch = { enable = true },
			implicitArguments = { enable = true },
			implicitConversions = { enable = true },
			inferredTypes = { enable = true },
			typeParameters = { enable = true },
			hintsXRayMode = { enable = true },
			closingLabels = { enable = true },
		},
	}

	metals.setup_dap()
	return config
end)

local group = vim.api.nvim_create_augroup("Initialize_metals", {})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "scala", "sbt", "java" },
	group = group,
	callback = function()
		require("metals").initialize_or_attach(metals_config())
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil or client.name ~= "metals" then
			return
		end

		local lsp = require("lsp")
		local utils = require("utils")
		local metals = require("metals")
		local tvp = require("metals.tvp")

		local buffer = args.buf
		local opts = { noremap = true, silent = true, buffer = buffer }
		local get_opts = utils.create_get_opts(opts)

		local pickers = require("pickers")
		pickers.map(pickers.prefix .. "m", function(telescope)
			telescope.extensions.metals.commands()
		end, { desc = "metals.commands.telescope" })

		-- Toggle panel with Tree Views
		vim.keymap.set("n", "<leader>tv", tvp.toggle_tree_view, get_opts({ desc = "metals.tree_view.toggle" }))
		-- Reveal current current class (trait or object) in Tree View 'metalsPackages'
		vim.keymap.set("n", "<leader>tf", tvp.reveal_in_tree, get_opts({ desc = "metals.tree_view.reveal_in_tree" }))

		vim.keymap.set(
			"n",
			"<leader>tt",
			vim.cmd.MetalsSelectTestSuite,
			get_opts({ desc = "metals.select_test_suite" })
		)
		vim.keymap.set("n", "<leader>tc", vim.cmd.MetalsSelectTestCase, get_opts({ desc = "metals.select_test_case" }))

		vim.keymap.set(
			"n",
			lsp.keymaps.organize_imports,
			metals.organize_imports,
			get_opts({ desc = "metals.organize_imports" })
		)
		vim.api.nvim_buf_create_user_command(buffer, "OR", metals.organize_imports, { nargs = 0 })
	end,
})
