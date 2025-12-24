local defer = require("defer")

defer.on_load("smear_cursor", function(smear_cursor)
	smear_cursor.enabled = true
end)
defer.on_event("smear_cursor", { "BufReadPost", "BufNewFile" })
