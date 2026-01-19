local defer = require('defer')

local function add_root_marker(linter_map, original_lint_fn)
	return function(...)
		local args = { ... }
		local linter = args[1]

		if type(linter) == 'table' and linter.name then
			local markers = linter_map[linter.name]
			if markers then
				local project_root, _ = require('project').get_project_root()
				local buf_path = vim.api.nvim_buf_get_name(0)

				if project_root and buf_path ~= '' then
					local found = vim.fs.find(markers, {
						upward = true,
						path = vim.fs.dirname(buf_path),
						stop = vim.fs.dirname(project_root), -- find searches up until the stop path, exclusive, so we need to search the parent of the root
					})

					-- Abort if we are in a project but no config file is found
					if #found == 0 then
						return nil
					end
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
	local root_markers = {
		luacheck = '.luacheckrc',
	}

	require('lint').linters_by_ft = linters
	require('lint').lint = add_disable(add_root_marker(root_markers, require('lint').lint))
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
