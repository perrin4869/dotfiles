local M = {}

local installed = nil
function M.get_installed()
	if not installed then
		installed = { 'sh' }
		vim.list_extend(installed, require('nvim-treesitter').get_installed())
	end
	return installed
end

return M
