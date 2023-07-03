local notify = require('notify')

notify.setup{
  stages = 'fade_in_slide_out',
  background_colour = 'FloatShadow',
  timeout = 3000,
}

-- luacheck:ignore 122
vim.notify = notify
vim.notify_once = notify
