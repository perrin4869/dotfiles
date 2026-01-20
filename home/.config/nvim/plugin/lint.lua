local defer = require('defer')

-- explicitly user provided linters are explicitly enabled
local function explicitly_enabled(linter_name)
	if type(vim.g.linters_by_ft) ~= 'table' then
		return false
	end

	local fts = vim.split(vim.bo.filetype, '%.', { trimempty = true })
	return vim.iter(fts):any(function(ft)
		if type(vim.g.linters_by_ft[ft]) ~= 'table' then
			return false
		end
		return vim.tbl_contains(vim.g.linters_by_ft[ft], linter_name)
	end)
end

local function explicitly_disabled(linter_name)
	return vim.g['lint_enable_' .. linter_name] == false
end

local function add_root_marker(markers_by_tool, original_lint_fn)
	return function(...)
		local args = { ... }
		local linter = args[1]

		if type(linter) == 'table' and linter.name then
			local markers = markers_by_tool[linter.name]
			if markers then
				local root_markers = require('root_markers')
				local project_root, _ = require('project').get_project_root()

				-- if we are inside a project and that project does not have the required marker, abort by default
				if
					project_root
					and not explicitly_enabled(linter.name)
					and not root_markers.has_marker(0, project_root, markers)
				then
					return nil
				end
			end
		end

		return original_lint_fn(unpack(args))
	end
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

defer.deps('lint', 'mason')
defer.pack('lint', 'nvim-lint')
defer.on_load('lint', function()
	local markers = {
		luacheck = '.luacheckrc',
	}

	local lint = require('lint')

	lint.linters_by_ft = linters_by_ft
	lint.lint = add_root_marker(markers, lint.lint)
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
