local yall = require('yall')

local function explicitly_disabled(linter_name)
	return vim.g['lint_enable_' .. linter_name] == false
end

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
	javascript = { 'eslint_d', 'oxlint' },
	javascriptreact = { 'eslint_d', 'oxlint' },
	typescript = { 'eslint_d', 'oxlint' },
	typescriptreact = { 'eslint_d', 'oxlint' },
	json = { 'jsonlint' },
}
local linters_by_ft = vim.tbl_extend('force', default_linters_by_ft, vim.g.linters_by_ft or {})
local pattern = vim.tbl_keys(linters_by_ft)

-- eslint_d stays the default; oxlint only runs for projects configured for oxlint and not for eslint
local function oxlint_only(bufnr)
	local markers = require('root_markers').markers
	return vim.fs.root(bufnr, markers.eslint()) == nil and vim.fs.root(bufnr, markers.oxlint()) ~= nil
end
local use_linter = {
	eslint_d = function(bufnr)
		return not oxlint_only(bufnr)
	end,
	oxlint = oxlint_only,
}

yall.deps('lint', 'mason')
yall.pack('lint', 'nvim-lint')
yall.on_load('lint', function()
	local lint = require('lint')

	lint.linters_by_ft = linters_by_ft
	lint.lint = add_disable(lint.lint)

	-- upstream resolves node_modules and runs from nvim's cwd rather than the oxlint config's directory
	lint.linters.oxlint = function()
		local oxlint = require('lint.linters.oxlint')
		local root = vim.fs.root(0, require('root_markers').markers.oxlint())
		if not root then
			return oxlint
		end
		local bin = vim.fs.joinpath(root, 'node_modules', '.bin', 'oxlint')
		return vim.tbl_extend('force', oxlint, {
			cmd = vim.uv.fs_stat(bin) and bin or oxlint.cmd,
			cwd = root,
			args = { '--format', 'github', '--type-aware' },
		})
	end
end)

vim.api.nvim_create_autocmd('FileType', {
	group = vim.api.nvim_create_augroup('TryLint', {}),
	pattern = pattern,
	callback = function(args)
		vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged' }, {
			buffer = args.buf,
			callback = yall.with('lint')(function()
				require('lint').try_lint(nil, {
					filter = function(linter)
						local use = use_linter[linter.name]
						return not use or use(args.buf)
					end,
				})
			end),
		})
	end,
})
