local defer = require("defer")

defer.on_load("substitute", function()
	require("substitute").setup()
end)
defer.pack("substitute", "substitute.nvim")
local with = defer.with("substitute")
local call = defer.call

local map = require("config").create_map({
	desc = "substitute",
	rhs = function(fname)
		return with(call(fname))
	end,
})

local prefix = "<leader>r"
map("n", prefix .. "", "operator")
map("n", prefix .. "r", "line")
map("n", prefix .. "R", "eol")
map("x", prefix .. "", "visual")
