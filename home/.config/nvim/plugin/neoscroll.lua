local yall = require('yall')

yall.pack('neoscroll', 'neoscroll.nvim')
yall.very_lazy('neoscroll')
yall.setup('neoscroll', {
	duration_multiplier = 0.9,
	easing = 'quintic',
})

-- karb94/neoscroll.nvim#124: a move_cursor=false scroll mid-animation skips the unhide, so the hidden guicursor gets saved as the original. Drop once fixed upstream.
yall.on_postload('neoscroll', function()
	local scroll = require('neoscroll.scroll')
	local hidden = 'a:NeoscrollHiddenCursor'
	local hide_cursor, tear_down = scroll.hide_cursor, scroll.tear_down
	function scroll:hide_cursor()
		if vim.o.guicursor ~= hidden then
			hide_cursor(self)
		end
	end
	function scroll:tear_down()
		tear_down(self)
		self:unhide_cursor()
	end
end)
