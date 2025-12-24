local defer = require("defer")

defer.on_load("notify", function(notify)
	notify.setup({
		stages = "fade_in_slide_out",
		background_colour = "FloatShadow",
		timeout = 3000,
	})
end)
-- since noice also uses nvim-notify, add as a hook
defer.hook("notify")

local lazy_notify = function(...)
	return require("notify")(...)
end

-- luacheck:ignore 122
vim.notify = lazy_notify
vim.notify_once = lazy_notify
