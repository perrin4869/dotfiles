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
	javascript = { 'eslint_d' },
	javascriptreact = { 'eslint_d' },
	typescript = { 'eslint_d' },
	typescriptreact = { 'eslint_d' },
	json = { 'jsonlint' },
}
local linters_by_ft = vim.tbl_extend('force', default_linters_by_ft, vim.g.linters_by_ft or {})
local pattern = vim.tbl_keys(linters_by_ft)

local js_filetypes = { javascript = true, javascriptreact = true, typescript = true, typescriptreact = true }
-- eslint_d stays the default; oxlint is the fallback for projects that only configure oxlint
local function js_linters(bufnr)
	local root_markers = require('root_markers')
	if vim.fs.root(bufnr, root_markers.markers.eslint()) then
		return nil
	end
	local oxlint_root = vim.fs.root(bufnr, root_markers.markers.oxlint())
	if oxlint_root then
		return { 'oxlint' }, { cwd = oxlint_root }
	end
	return nil
end

yall.deps('lint', 'mason')
yall.pack('lint', 'nvim-lint')
yall.on_load('lint', function()
	local lint = require('lint')

	lint.linters_by_ft = linters_by_ft
	lint.lint = add_disable(lint.lint)

	-- upstream only looks for node_modules in nvim's cwd, not next to the oxlint config
	lint.linters.oxlint = vim.tbl_extend('force', require('lint.linters.oxlint'), {
		cmd = function()
			local root = vim.fs.root(0, require('root_markers').markers.oxlint())
			local bin = root and vim.fs.joinpath(root, 'node_modules', '.bin', 'oxlint')
			return bin and vim.uv.fs_stat(bin) and bin or 'oxlint'
		end,
		args = { '--format', 'github', '--type-aware' },
	})
end)

vim.api.nvim_create_autocmd('FileType', {
	group = vim.api.nvim_create_augroup('TryLint', {}),
	pattern = pattern,
	callback = function(args)
		vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged' }, {
			buffer = args.buf,
			callback = yall.with('lint')(function()
				if js_filetypes[vim.bo[args.buf].filetype] then
					require('lint').try_lint(js_linters(args.buf))
				else
					require('lint').try_lint()
				end
			end),
		})
	end,
})
