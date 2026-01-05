local defer = require("defer")
defer.deps("lint", "meson")
defer.on_load("lint", function()
	require("lint").linters_by_ft = {
		lua = { "luacheck" },
		css = { "stylelint" },
		javascript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		typescript = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		json = { "jsonlint" },
	}
end)
defer.pack("lint", "nvim-lint")

-- BufEnter is probably overkill
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged" }, {
	callback = defer.with("lint")(defer.call("try_lint")),
})
