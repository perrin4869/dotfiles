local utils = require("utils")

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		typescript = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		-- Use a sub-list to run only the first available formatter
		json = { { "prettierd", "prettier" } },
		scala = {},
		["*"] = { "trim_whitespace" },
	},
})

local function format()
	require("conform").format({ lsp_fallback = true })
end

local function format_write()
	require("conform").format({
		lsp_fallback = true,
	}, vim.cmd.write)
end

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)
vim.keymap.set("n", "<leader>f", format, get_opts({ desc = "conform.format" }))
vim.keymap.set("n", "<leader>F", format_write, get_opts({ desc = "conform.format_write" }))

local function enable_autoformat()
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("FormatAutogroup", {}),
		callback = format_write,
	})
end

local function disable_autoformat()
	vim.api.nvim_clear_autocmds({ group = "FormatAutogroup" })
end

enable_autoformat()

vim.api.nvim_create_user_command("FormatEnable", enable_autoformat, {})
vim.api.nvim_create_user_command("FormatDisable", disable_autoformat, {})
vim.api.nvim_create_user_command("FormatToggle", function()
	local enabled = #vim.api.nvim_get_autocmds({ group = "FormatAutogroup" }) > 0
	if enabled then
		disable_autoformat()
	else
		enable_autoformat()
	end
end, {})
