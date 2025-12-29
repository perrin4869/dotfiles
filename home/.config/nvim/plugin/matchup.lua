local defer = require("defer")
-- very-lazy will fail to setup on the first opened buffer
defer.on_load("matchup", function()
	vim.cmd.packadd("vim-matchup")
end)
defer.on_event("matchup", { "BufReadPost", "BufNewFile" })
