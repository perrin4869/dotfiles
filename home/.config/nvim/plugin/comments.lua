local defer = require('defer')

-- sets up commenstring based on context via treesitter
-- you can test the functionality on a tsx file
defer.on_load('ts-comments', function()
	require('ts-comments').setup()
end)
defer.pack('ts-comments', 'ts-comments.nvim')
defer.very_lazy('ts-comments')
