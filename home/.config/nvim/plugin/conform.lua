local utils = require("utils")

local enabled = true

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "eslint_d", lsp_format = "never" },
		javascriptreact = { "eslint_d", lsp_format = "never" },
		typescript = { "eslint_d", lsp_format = "never" },
		typescriptreact = { "eslint_d", lsp_format = "never" },
		-- Use a sub-list to run only the first available formatter
		json = { "prettierd", "prettier", stop_after_first = true },
		kotlin = {}, -- disable lsp formatting
		["*"] = { "trim_whitespace" },
	},
	default_format_opts = {
		lsp_format = "last",
		async = true,
	},
	format_after_save = function(bufnr)
		if not enabled or vim.bo[bufnr].readonly then
			return false
		end

		return {
			bufnr = bufnr,
		}
	end,
})

local function format()
	require("conform").format()
end

local function toggle_autoformat()
	enabled = not enabled
end

local function enable_autoformat()
	enabled = true
end

local function disable_autoformat()
	enabled = false
end

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)
vim.keymap.set("n", "<leader>ff", format, get_opts({ desc = "conform.format" }))
vim.keymap.set("n", "<leader>ft", toggle_autoformat, get_opts({ desc = "conform.toggle_autoformat" }))

vim.api.nvim_create_user_command("FormatEnable", enable_autoformat, {})
vim.api.nvim_create_user_command("FormatDisable", disable_autoformat, {})
vim.api.nvim_create_user_command("FormatToggle", toggle_autoformat, {})
