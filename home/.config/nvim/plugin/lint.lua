require("lint").linters_by_ft = {
	lua = { "luacheck" },
	css = { "stylelint" },
	javascript = { "eslint_d" },
	javascriptreact = { "eslint_d" },
	typescript = { "eslint_d" },
	typescriptreact = { "eslint_d" },
	json = { "jsonlint" },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
	callback = function()
		require("lint").try_lint()
	end,
})
