local defer = require('defer')

local function add_disable(original_lint_fn)
	return function(...)
		local args = { ... }
		local linter = args[1] -- The first argument is the linter table

		if type(linter) == 'table' and linter.name and explicitly_disabled(linter.name) then
			return nil
		end

		-- Call the original function with all original arguments
		return original_lint_fn(unpack(args))
	end
end

local default_linters_by_ft = {
	lua = { 'luacheck' },
	css = { 'stylelint' },
	javascript = { 'eslint_d' },
	javascriptreact = { 'eslint_d' },
	typescript = { 'eslint_d' },
	typescriptreact = { 'eslint_d' },
	json = { 'jsonlint' },
}
local linters_by_ft = vim.tbl_extend('force', default_linters_by_ft, vim.g.linters_by_ft or {})
local pattern = vim.tbl_keys(linters_by_ft)

defer.deps('lint', 'mason')
defer.pack('lint', 'nvim-lint')
defer.on_load('lint', function()
	local lint = require('lint')

	lint.linters_by_ft = linters_by_ft
	lint.lint = add_disable(lint.lint)
end)

vim.api.nvim_create_autocmd('FileType', {
	group = vim.api.nvim_create_augroup('TryLint', {}),
	pattern = pattern,
	callback = function(args)
		vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged' }, {
			buffer = args.buf,
			callback = defer.with('lint')(defer.call('try_lint')),
		})
	end,
})
