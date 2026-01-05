local defer = require("defer")

defer.on_load("smear_cursor", function()
	require("smear_cursor").enabled = true
end)
defer.very_lazy("smear_cursor")
