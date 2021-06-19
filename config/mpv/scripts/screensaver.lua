-- since 0.33 this is not used by default
-- unfortunately --stop-screensaver does not seem to work on i3wm
local utils = require 'mp.utils'
mp.add_periodic_timer(30, function()
    utils.subprocess({args={"xdg-screensaver", "reset"}})
end)
