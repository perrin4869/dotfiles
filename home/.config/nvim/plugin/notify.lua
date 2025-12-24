local defer = require("defer")

-- since noice also uses nvim-notify, add as a hook
defer.hook("notify", function()
	require("notify").setup({
		stages = "fade_in_slide_out",
		background_colour = "FloatShadow",
		timeout = 3000,
	})
end)

local lazy_notify = function(...)
	return require("notify")(...)
end

vim.notify = lazy_notify
vim.notify_once = lazy_notify
