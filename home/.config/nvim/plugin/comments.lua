local yall = require('yall')

-- sets up commenstring based on context via treesitter
-- you can test the functionality on a tsx file
yall.setup('ts-comments')
yall.pack('ts-comments', 'ts-comments.nvim')
yall.very_lazy('ts-comments')
