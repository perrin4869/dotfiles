local defer = require("defer")
defer.on_load("nvim-lightbulb", function(lightbulb)
	lightbulb.setup({
		autocmd = { enabled = true },
	})
end)
defer.on_event("nvim-lightbulb", "LspAttach")
