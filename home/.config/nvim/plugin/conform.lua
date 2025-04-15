local utils = require("utils")

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		typescript = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		-- Use a sub-list to run only the first available formatter
		json = { "prettierd", "prettier", stop_after_first = true },
		kotlin = { lsp_format = "never" },
		["_"] = { "trim_whitespace", lsp_format = "prefer" },
	},
	default_format_opts = {
		lsp_format = "fallback",
		async = true,
	},
	format_after_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat or vim.bo[bufnr].readonly then
			return
		end

		return {
			bufnr = bufnr,
		}
	end,
})

local function format()
	require("conform").format()
end

local function toggle_autoformat(args)
	if args and args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = not (vim.b.disable_autoformat == nil and false or vim.b.disable_autoformat)
	else
		vim.g.disable_autoformat = not (vim.g.disable_autoformat == nil and false or vim.g.disable_autoformat)
	end
end

local function enable_autoformat()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end

local function disable_autoformat(args)
	if args and args.bang then
		-- FormatDisable! will disable formatting just for this buffer
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)
vim.keymap.set("n", "<leader>ff", format, get_opts({ desc = "conform.format" }))
vim.keymap.set("n", "<leader>ft", toggle_autoformat, get_opts({ desc = "conform.toggle_autoformat" }))

vim.api.nvim_create_user_command("FormatEnable", enable_autoformat, { desc = "Re-enable autoformat-on-save" })
vim.api.nvim_create_user_command(
	"FormatDisable",
	disable_autoformat,
	{ desc = "Disable autoformat-on-save", bang = true }
)
vim.api.nvim_create_user_command("FormatToggle", toggle_autoformat, { desc = "Toggle autoformat-on-save", bang = true })
