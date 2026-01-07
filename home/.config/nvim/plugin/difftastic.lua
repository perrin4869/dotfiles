local defer = require("defer")

defer.on_load("difftastic-nvim", function()
	require("difftastic-nvim").setup()
end)
defer.pack("difftastic-nvim", "difftastic.nvim")
defer.very_lazy("difftastic-nvim")
