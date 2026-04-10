local yall = require('yall')

-- sets up commenstring based on context via treesitter
-- you can test the functionality on a tsx file
yall.on_load('ts-comments', function()
	require('ts-comments').setup()
end)
yall.pack('ts-comments', 'ts-comments.nvim')
yall.very_lazy('ts-comments')
