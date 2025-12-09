-- General repeatable prev/next mapping with descriptions
return function(repeat_key, opts, action_prev, action_next)
	opts = opts or {}
	local timeout = opts.timeout or 1000
	---@type uv.uv_timer_t|nil
	local timer = nil

	local desc_repeat = opts.desc_repeat or ("Repeat last action with " .. repeat_key)

	local function unmap()
		pcall(vim.keymap.del, "n", repeat_key)
	end

	local function ensure_timer()
		if not timer or timer:is_closing() then
			timer = vim.loop.new_timer()
		else
			timer:stop()
		end

		---@cast timer uv.uv_timer_t
		timer:start(
			timeout,
			0,
			vim.schedule_wrap(function()
				unmap()

				if timer then
					pcall(timer.close, timer)
					timer = nil
				end
			end)
		)
	end

	local function map(direction)
		vim.keymap.set("n", repeat_key, function()
			if direction == "next" then
				action_next()
			else
				action_prev()
			end
			vim.schedule(ensure_timer)
		end, { silent = true, desc = desc_repeat, nowait = true })
		vim.schedule(ensure_timer)
	end

	-- Create prefix mappings with descriptions
	return function()
		map("prev")
		action_prev()
	end, function()
		map("next")
		action_next()
	end
end
