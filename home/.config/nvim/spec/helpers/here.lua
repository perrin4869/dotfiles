-- Specs find their fixtures relative to their own file, and that needs `debug.getinfo`, which only reports the chunk that
-- calls it. So each spec does its own `debug.getinfo` and hands the result here for the path arithmetic.
local M = {}

--- Directory holding the file that called `debug.getinfo`, `up` levels above it.
---@param info table  what `debug.getinfo(1, 'S')` returned
---@param up? integer
---@return string
function M.dir(info, up)
	local dir = vim.fn.fnamemodify(info.source:sub(2), ':p:h')
	return up and vim.fn.fnamemodify(dir, string.rep(':h', up)) or dir
end

return M
