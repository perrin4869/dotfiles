local defer = require("defer")

defer.pack("metals", "nvim-metals")
local with_metals = defer.with("metals")
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

	defer.on_postload("dap", function()
		metals.setup_dap()
	end)
	return config
end)

local group = vim.api.nvim_create_augroup("Initialize_metals", {})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "scala", "sbt", "java" },
	group = group,
	callback = with_metals(function(metals)
		metals.initialize_or_attach(metals_config())
	end),
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
		local metals = require("metals")
		local tvp = require("metals.tvp")

		local buffer = args.buf
		local map = require("map").create({
			mode = "n",
			buffer = buffer,
			desc = "metals",
		})

		local pickers = require("pickers")
		defer.on_postload("telescope", function()
			require("telescope").load_extension("metals")
		end)
		pickers.map(pickers.prefix .. "l", function(telescope)
			telescope.extensions.metals.commands()
		end, { desc = "metals.commands.telescope" })

		local prefix = "<leader>l"
		-- Toggle panel with Tree Views
		map(prefix .. "v", tvp.toggle_tree_view, "tree_view.toggle")
		-- Reveal current current class (trait or object) in Tree View 'metalsPackages'
		map(prefix .. "f", tvp.reveal_in_tree, "tree_view.reveal_in_tree")

		map(prefix .. "t", vim.cmd.MetalsSelectTestSuite, "select_test_suite")
		map(prefix .. "c", vim.cmd.MetalsSelectTestCase, "select_test_case")

		map(lsp.keymaps.organize_imports, metals.organize_imports, "organize_imports")
		vim.api.nvim_buf_create_user_command(buffer, "OR", metals.organize_imports, { nargs = 0 })
	end,
})
