local defer = require("defer")

defer.on_load("persistence", function()
	require("persistence").setup()
end)
defer.pack("persistence", "persistence.nvim")
defer.hook("persistence")
defer.on_event("persistence", "BufReadPre")

local with_persistence = defer.with("persistence")
local call = defer.call

local map = require("config").create_map({
	mode = "n",
	desc = "persistence",
	rhs = function(args)
		if type(args) == "table" then
			return with_persistence(call(unpack(args)))
		else
			return with_persistence(call(args))
		end
	end,
})

local prefix = "<leader>q"
-- restore the session for the current directory
map(prefix .. "s", "load")

-- restore the last session
map(prefix .. "l", { "load", { last = true } }, "load_last")

-- stop Persistence => session won't be saved on exit
map(prefix .. "d", "stop")
