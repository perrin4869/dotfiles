local utils = require("utils")

local enabled = true

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		typescript = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		-- Use a sub-list to run only the first available formatter
		json = { { "prettierd", "prettier" } },
		["*"] = { "trim_trailing_whitespace" },
	},
	formatters = {
		trim_trailing_whitespace = {
			command = "sed",
			args = "'s/[ \t]*$//'",
		},
	},
	format_after_save = function(bufnr)
		if not enabled then
			return false
		end

		return {
			async = true,
			lsp_fallback = true,
			bufnr = bufnr,
		}
	end,
})

local function format()
	require("conform").format({
		async = true,
		lsp_fallback = true,
	})
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
