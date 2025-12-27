local defer = require("defer")

defer.on_load("nvim-surround", function(surround)
	surround.setup({})
end, "nvim-surround")
defer.very_lazy("nvim-surround")
