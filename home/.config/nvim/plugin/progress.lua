local defer = require("defer")
defer.on_load("lsp-progress", function()
	require("lsp-progress").setup()
end)
