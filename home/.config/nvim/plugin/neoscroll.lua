local defer = require("defer")

defer.pack("neoscroll", "neoscroll.nvim")
defer.very_lazy("neoscroll")
defer.on_load("neoscroll", function()
	require("neoscroll").setup({
		duration_multiplier = 0.9,
		easing = "quintic",
	})
end)
