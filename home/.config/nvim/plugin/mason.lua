local defer = require("defer")

defer.on_load("mason", function(mason)
	mason.setup({
		registries = {
			"file:" .. vim.fs.joinpath(vim.fn.stdpath("data"), "mason-registry"),
		},
	})
end)
defer.cmd("MasonInstall", "mason")
defer.hook("mason")
defer.very_lazy("mason")
