local M = {}

M.default_exts = { 'json', 'yaml', 'yml', 'toml' }
function M.get_root_markers(stem, exts)
	exts = exts or M.default_exts
	local markers = {}

	-- 1. Add standard dot-prefixed versions: .eslint, .eslintrc
	table.insert(markers, '.' .. stem)
	table.insert(markers, '.' .. stem .. 'rc')

	-- 2. Add extension variations: .eslintrc.js, .eslintrc.json, etc.
	for _, ext in ipairs(exts) do
		table.insert(markers, '.' .. stem .. 'rc.' .. ext)
	end

	-- 3. Add modern "config" style: eslint.config.js, eslint.config.ts, etc.
	for _, ext in ipairs(exts) do
		table.insert(markers, stem .. '.config.' .. ext)
	end

	return markers
end

--- detect a root marker in a given buffer
--- @param bufnr integer
--- @param root string
--- @param markers string[]
--- @return boolean
function M.has_marker(bufnr, root, markers)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == '' then
		return false
	end

	return #(
			vim.fs.find(markers, {
				upward = true,
				path = vim.fs.dirname(path),
				stop = vim.fs.dirname(root), -- find searches up until the stop path, exclusive, so we need to search the parent of the root
			})
		) > 0
end

local lazy = require('defer').lazy
M.markers = {
	eslint = lazy(function()
		return M.get_root_markers('eslint', vim.list_extend({ 'js', 'cjs', 'mjs', 'ts', 'mts' }, M.default_exts))
	end),
}

return M
