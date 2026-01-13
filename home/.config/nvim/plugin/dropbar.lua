local defer = require("defer")
defer.pack("dropbar", "dropbar.nvim")
defer.on_bufreadpre("dropbar")

local pick = defer.with("dropbar")(function()
	require("dropbar.api").pick()
end)
require("config").map("n", "<leader>o", pick, "dropbar.pick")
