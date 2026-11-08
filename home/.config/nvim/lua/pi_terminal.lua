-- How pi shows up in a terminal's argv, kept out of plugin/pi.lua so the specs can check it without an editor.
local M = {}

-- 'pi' and '/path/to/pi' name pi; 'pi --continue' is how a session restore respawns it
---@param argv string[]|nil what nvim_get_chan_info() reports for the terminal's channel
---@return boolean
function M.matches(argv)
	local command = argv and argv[1]
	if not command then
		return false
	end
	return (command:match('([^/]+)$') or command) == 'pi'
end

return M
