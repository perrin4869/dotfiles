local defer = require("defer")
-- very-lazy will fail to setup on the first opened buffer
defer.on_event(function()
	vim.cmd.packadd("vim-matchup")
end, { "BufReadPost", "BufNewFile" }, { name = "matchup" })
