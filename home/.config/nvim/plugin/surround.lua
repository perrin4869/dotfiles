local defer = require("defer")

defer.on_load("nvim-surround", function()
	require("nvim-surround").setup({})
end)
defer.pack("nvim-surround", "nvim-surround")
defer.very_lazy("nvim-surround")
