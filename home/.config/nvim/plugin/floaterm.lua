local yall = require('yall')
yall.pack('floaterm')
yall.very_lazy('floaterm')
yall.setup('floaterm', {
	border = true,
	-- https://github.com/nvzone/floaterm/issues/35
	mappings = {
		term = function(buf)
			vim.keymap.set('n', '<ESC>', function()
				require('floaterm').toggle()
			end, { buffer = buf })
		end,
	},
})

local with = yall.with('floaterm')
local map = require('map').create({
	mode = { 'n', 't' },
	desc = 'floaterm',
})

local toggle = with(function()
	require('floaterm').toggle()
end)
local new_term = with(function()
	if not require('floaterm.state').terminals then
		require('floaterm').toggle()
		return
	end
	if vim.bo.ft ~= 'Floaterm' then
		require('floaterm').toggle()
	end
	require('floaterm.api').new_term()
end)
local cycle_term_bufs_prev = with(function()
	require('floaterm.api').cycle_term_bufs('prev')
end)
local cycle_term_bufs = with(function()
	require('floaterm.api').cycle_term_bufs()
end)
local delete_term = with(function()
	require('floaterm.api').delete_term()
end)

map('<M-t>', toggle, 'toggle')

map('<F6>', new_term, 'new_term')
map('<F7>', cycle_term_bufs_prev, 'cycle_prev')
map('<F8>', cycle_term_bufs, 'cycle_next')
map('<F12>', toggle, 'toggle')

map('<F9>', delete_term, 'delete_term')
