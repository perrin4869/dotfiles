local defer = require('defer')
defer.pack('floaterm')
defer.very_lazy('floaterm')
defer.on_load('floaterm', function()
	require('floaterm').setup({
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
end)

local call = defer.call
local with_floaterm = defer.with('floaterm')
local with_floaterm_api = function(cb)
	return defer.with('floaterm')(function()
		cb(require('floaterm.api'))
	end)
end

local map = require('map').create({
	mode = { 'n', 't' },
	desc = 'floaterm',
})

map('<M-t>', with_floaterm(call('toggle')), 'toggle')

map(
	'<F6>',
	with_floaterm(function(floaterm)
		if not require('floaterm.state').terminals then
			floaterm.toggle()
			return
		end
		if vim.bo.ft ~= 'Floaterm' then
			floaterm.toggle()
		end
		require('floaterm.api').new_term()
	end),
	'new_term'
)
map('<F7>', with_floaterm_api(call('cycle_term_bufs', 'prev')), 'cycle_prev')
map('<F8>', with_floaterm_api(call('cycle_term_bufs')), 'cycle_next')
map('<F12>', with_floaterm(call('toggle')), 'toggle')

map('<F9>', with_floaterm_api(call('delete_term')), 'delete_term')
