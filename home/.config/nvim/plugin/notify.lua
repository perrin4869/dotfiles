local yall = require('yall')

yall.setup('notify', {
	stages = 'fade_in_slide_out',
	background_colour = 'FloatShadow',
	timeout = 3000,
})
-- since noice also uses nvim-notify, add as a hook
yall.hook('notify')

local lazy_notify = function(...)
	return require('notify')(...)
end

-- luacheck:ignore 122
vim.notify = lazy_notify
vim.notify_once = lazy_notify
