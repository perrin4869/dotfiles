local map = require('map').create({ buffer = true })

map('n', '<leader>l', function()
	vim.cmd('LivePreview start')
end, 'LivePreview start')

map('n', '<leader>L', function()
	vim.cmd('LivePreview close')
end, 'LivePreview stop')
