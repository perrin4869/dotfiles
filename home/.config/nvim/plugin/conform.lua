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
		["*"] = { "trim_whitespace" },
	},
})

local function get_lsp_fallback(bufnr)
	local ft = vim.bo[bufnr or 0].filetype

	-- local always_use_lsp = not ft:match("^typescript") and not ft:match("^javascript")
	local always_use_lsp = ft:match("scala")
	return always_use_lsp and "always" or true
end

local function format(args)
	local bufnr = args and args.buf

	require("conform").format({
		lsp_fallback = get_lsp_fallback(bufnr),
		async = true,
		bufnr = bufnr,
	})
end

local saving = false
local function format_write(args)
	if saving then
		return
	end
	local bufnr = args and args.buf

	require("conform").format({
		lsp_fallback = get_lsp_fallback(bufnr),
		async = true,
		bufnr = bufnr,
	}, function(err)
		if not err then
			saving = true
			vim.cmd.update()
			saving = false
		end
	end)
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
