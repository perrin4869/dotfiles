local lazy = require('defer').lazy
local M = {}

--- @type Defer.Lazy<uv.uv_timer_t>
local timer = lazy(function()
	return vim.uv.new_timer()
end)
local cache = {} -- Stores original mappings keyed by the repeat_key

---Restores the original mapping for a specific key
---@param key string
local function restore(key)
	local map = cache[key]
	if map == nil then
		return
	end

	if map ~= false then
		local opts = {
			silent = map.silent == 1,
			expr = map.expr == 1,
			nowait = map.nowait == 1,
			noremap = map.noremap == 1,
			desc = map.desc,
			buffer = map.buffer,
		}
		if map.callback then
			vim.keymap.set('n', key, map.callback, opts)
		else
			vim.keymap.set('n', key, map.rhs, opts)
		end
	else
		pcall(vim.keymap.del, 'n', key)
	end
	cache[key] = nil
end

---Activates the sticky repeat for the primary key
---@param key string
---@param action function
---@param timeout number
local function activate_sticky(key, action, timeout)
	timer():stop()

	-- 1. Cache current mapping if we haven't already
	if cache[key] == nil then
		local arg = vim.fn.maparg(key, 'n', false, true)
		if next(arg) ~= nil then
			cache[key] = arg
		else
			cache[key] = false
		end
	end

	-- 2. Create the temporary override
	vim.keymap.set('n', key, function()
		action()
		activate_sticky(key, action, timeout)
	end, { silent = true, nowait = true, desc = 'Sticky repeat: ' .. key })

	-- 3. Set timer to restore original state
	timer():start(
		timeout,
		0,
		vim.schedule_wrap(function()
			restore(key)
		end)
	)
end

---Wraps actions to trigger sticky repetition
---@param key string The key to override (e.g., 'b')
---@param action_prev function
---@param action_next function
---@param timeout? number Defaults to 1000ms
---@return function action_prev, function action_next
function M.trigger(key, action_prev, action_next, timeout)
	timeout = timeout or 1000

	local wrapped_prev = function()
		local res = action_prev()
		activate_sticky(key, action_prev, timeout)
		return res
	end

	local wrapped_next = function()
		local res = action_next()
		activate_sticky(key, action_next, timeout)
		return res
	end

	return wrapped_prev, wrapped_next
end

return M
