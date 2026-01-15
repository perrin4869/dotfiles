-- since 0.33 this is not used by default
-- unfortunately --stop-screensaver does not seem to work on i3wm

-- inspired by https://gist.github.com/crazygolem/a7d3a2d3c0cee5d072c0cbbbdee69286

local mp = require('mp')
local msg = require('mp.msg')
local utils = require('mp.utils')

local timer

local function handle_inhibit(_, value)
	if value == true then
		timer:kill() -- stop will remember the elapsed time
	else
		timer:resume()
	end
end

mp.observe_property('stop-screensaver', 'bool', function(_, enable)
	if enable then
		if not timer then
			timer = mp.add_periodic_timer(30, function()
				utils.subprocess({ args = { 'xdg-screensaver', 'reset' } })
			end)
		end

		mp.observe_property('pause', 'bool', handle_inhibit)
		msg.debug('inhibit handling on')
	else
		if timer then
			timer:kill()
			timer = nil
		end

		mp.unobserve_property('pause', 'bool', handle_inhibit)
		msg.debug('inhibit handling off')
	end
end)
