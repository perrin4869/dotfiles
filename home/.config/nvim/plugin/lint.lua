local defer = require('defer')

local function add_disable(original_lint_fn)
	return function(...)
		local args = { ... }
		local linter = args[1] -- The first argument is the linter table

		-- Check if we have a valid linter table with a name
		if type(linter) == 'table' and linter.name then
			local disable_var = 'lint_disable_' .. linter.name

			-- If the global variable is true, intercept and abort
			if vim.g[disable_var] == true then
				return nil
			end
		end

		-- Call the original function with all original arguments
		return original_lint_fn(unpack(args))
	end
end

local linters = {
	lua = { 'luacheck' },
	css = { 'stylelint' },
	javascript = { 'eslint_d' },
	javascriptreact = { 'eslint_d' },
	typescript = { 'eslint_d' },
	typescriptreact = { 'eslint_d' },
	json = { 'jsonlint' },
}
local pattern = vim.tbl_keys(linters)

defer.deps('lint', 'mason')
defer.pack('lint', 'nvim-lint')
defer.on_load('lint', function()
	require('lint').linters_by_ft = linters
	require('lint').lint = add_disable(require('lint').lint)
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
