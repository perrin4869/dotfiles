-- General repeatable prev/next mapping with descriptions
local function make_unimpaired_pair(repeat_key, action_prev, action_next, opts)
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

local next_move = require("nvim-next.move")

-- buffers
local prev_buffers, next_buffers = next_move.make_repeatable_pair(make_unimpaired_pair("b", function()
	vim.cmd("bprevious")
end, function()
	vim.cmd("bnext")
end, { desc = "Repeat buffer prev/next with 'b'" }))
vim.keymap.set("n", "[b", prev_buffers, { silent = true, desc = "Go to previous buffer" })
vim.keymap.set("n", "]b", next_buffers, { silent = true, desc = "Go to next buffer" })

local prev_diag, next_diag = next_move.make_repeatable_pair(make_unimpaired_pair("d", function()
	vim.diagnostic.jump({ count = -vim.v.count1 })
end, function()
	vim.diagnostic.jump({ count = vim.v.count1 })
end, { desc_repeat = "Repeat diagnostic prev/next with 'd'" }))
vim.keymap.set("n", "[d", prev_diag, { silent = true, desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]d", next_diag, { silent = true, desc = "Go to next diagnostic" })
