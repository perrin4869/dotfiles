-- Utilities for creating configurations
local utils = require("utils")

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup({
	-- Enable or disable logging
	logging = true,
	-- Set the log level
	log_level = vim.log.levels.WARN,
	-- All formatter configurations are opt-in
	filetype = {
		-- Formatter configurations for filetype "lua" go here
		-- and will be executed in order
		lua = {
			-- "formatter.filetypes.lua" defines default configurations for the
			-- "lua" filetype
			require("formatter.filetypes.lua").stylua,
		},
		javascript = { require("formatter.filetypes.javascript").eslint_d },
		javascriptreact = { require("formatter.filetypes.javascriptreact").eslint_d },
		typescript = { require("formatter.filetypes.typescript").eslint_d },
		typescriptreact = { require("formatter.filetypes.typescriptreact").eslint_d },
		json = { require("formatter.filetypes.json").prettier },

		-- Use the special "*" filetype for defining formatter configurations on
		-- any filetype
		["*"] = {
			-- "formatter.filetypes.any" defines default configurations for any
			-- filetype
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
	},
})

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)
vim.keymap.set("n", "<leader>f", vim.cmd.Format, get_opts({ desc = "formatter.format" }))
vim.keymap.set("n", "<leader>F", vim.cmd.FormatWrite, get_opts({ desc = "formatter.format" }))

vim.api.nvim_create_autocmd("BufWritePost", {
	group = vim.api.nvim_create_augroup("FormatAutogroup", {}),
	callback = function()
		vim.cmd.FormatWrite()
	end,
})
