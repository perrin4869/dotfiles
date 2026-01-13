local defer = require("defer")

defer.on_load("persistence", function()
	require("persistence").setup()
end)
defer.pack("persistence", "persistence.nvim")
defer.hook("persistence")
defer.on_event("persistence", "BufReadPre")

local with_persistence = defer.with("persistence")
local call = defer.call

--- @param lhs string
--- @param args string|table
--- @param desc? string
local function map(lhs, args, desc)
	local rhs
	if type(args) == "table" then
		rhs = with_persistence(call(unpack(args)))
	else
		desc = desc or args
		rhs = with_persistence(call(args))
	end
	vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = "persistence." .. desc })
end

local prefix = "<leader>q"
-- restore the session for the current directory
map(prefix .. "s", "load")

-- restore the last session
map(prefix .. "l", { "load", { last = true } }, "load_last")

-- stop Persistence => session won't be saved on exit
map(prefix .. "d", "stop")
