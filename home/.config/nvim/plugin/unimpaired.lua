-- General repeatable prev/next mapping with descriptions
local function repeatable_unimpaired(prev_mapping, next_mapping, repeat_key, action_prev, action_next, opts)
	opts = opts or {}
	local timeout = opts.timeout or 1000
	---@type uv.uv_timer_t|nil
	local timer = nil

	local desc_prev = opts.desc_prev or ("Repeatable prev for " .. prev_mapping)
	local desc_next = opts.desc_next or ("Repeatable next for " .. next_mapping)
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
		end, { silent = true, desc = desc_repeat })
		vim.schedule(ensure_timer)
	end

	-- Create prefix mappings with descriptions
	vim.keymap.set("n", prev_mapping, function()
		map("prev")
		action_prev()
	end, { silent = true, desc = desc_prev })

	vim.keymap.set("n", next_mapping, function()
		map("next")
		action_next()
	end, { silent = true, desc = desc_next })
end

-- buffers
repeatable_unimpaired("[b", "]b", "b", function()
	vim.cmd("bprevious")
end, function()
	vim.cmd("bnext")
end, {
	desc_prev = "Go to previous buffer",
	desc_next = "Go to next buffer",
	desc_repeat = "Repeat buffer prev/next with 'b'",
})

repeatable_unimpaired("[d", "]d", "d", function()
	vim.diagnostic.jump({ count = -vim.v.count1 })
end, function()
	vim.diagnostic.jump({ count = vim.v.count1 })
end, {
	desc_prev = "Go to previous diagnostic",
	desc_next = "Go to next diagnostic",
	desc_repeat = "Repeat diagnostic prev/next with 'd'",
})
