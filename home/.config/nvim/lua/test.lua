local defer = require("defer")
local M = {}

--- setup neotest for individual projects, via .nvim.lua
--- the first argument is meant to be called with `debug.getinfo(1, "S")`
--- @param info debuginfo
--- @param get_adapters fun(root: string): neotest.Adapter[]
M.setup = function(info, get_adapters)
	local fname = info.source:sub(2)
	local root = vim.fn.fnamemodify(fname, ":h")

	defer.on_postload("neotest", function()
		require("neotest").setup_project(root, {
			adapters = get_adapters(root),
		})
	end)
end

return M
