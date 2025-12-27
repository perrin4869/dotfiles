local defer = require("defer")
defer.on_load("nvim-next", function()
	require("nvim-next").setup({
		default_mappings = {
			repeat_style = "original",
		},
		items = {
			require("nvim-next.builtins").f,
			require("nvim-next.builtins").t,
		},
	})
end)
defer.on_event("nvim-next", "BufEnter")
