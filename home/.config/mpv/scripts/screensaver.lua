-- since 0.33 this is not used by default
-- unfortunately --stop-screensaver does not seem to work on i3wm
require 'mp.options'
local options = {
    enabled = true,
}
read_options(options, "inhibit")

if options.enabled then
  local utils = require 'mp.utils'
  local timer = mp.add_periodic_timer(30, function()
      utils.subprocess({args={"xdg-screensaver", "reset"}})
  end)

  mp.observe_property("pause", "bool", function(name, value)
      if value == true then
        timer:kill() -- stop will remember the elapsed time
      else
        timer:resume()
      end
  end)
end
