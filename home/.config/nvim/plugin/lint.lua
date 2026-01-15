local defer = require('defer')

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
