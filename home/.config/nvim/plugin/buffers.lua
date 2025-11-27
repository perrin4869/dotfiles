-- Temporary mapping of `b` that extends the expiry each press
local timeout = 600 -- ms
---@type uv.uv_timer_t|nil
local timer = nil

local function unmap()
	-- remove temporary mapping if present; ignore errors
	pcall(vim.keymap.del, "n", "b")
end

local function ensure_timer()
	if not timer or timer:is_closing() then
		timer = vim.loop.new_timer()
	end

	-- we've ensured that timer is not null
	---@cast timer uv.uv_timer_t

	-- stop in case it's running
	pcall(timer.stop, timer)
	-- start a one-shot timer; when it fires, restore original `b`
	timer:start(
		timeout,
		0,
		vim.schedule_wrap(function()
			unmap()
			-- close the timer to free resources
			pcall(timer.close, timer)
			timer = nil
		end)
	)
end

local function map(direction)
	-- ensure any previous temp mapping removed (safety)
	unmap()

	-- create mapping
	vim.keymap.set("n", "b", function()
		-- perform action
		if direction == "next" then
			vim.cmd("bnext")
		else
			vim.cmd("bprevious")
		end

		ensure_timer()
	end, { silent = true })

	ensure_timer()
end

-- prefix mappings
vim.keymap.set("n", "[b", function()
	vim.cmd("bprevious")
	map("prev")
end, { silent = true })

vim.keymap.set("n", "]b", function()
	vim.cmd("bnext")
	map("next")
end, { silent = true })
