vim.api.nvim_create_user_command('OsvLaunch', function()
	require('osv').launch({ port = 8086 })
end, { desc = 'Launch osv' })

vim.api.nvim_create_user_command('OsvStop', require('osv').stop, { desc = 'Stop osv' })

local map = require('map').create({
	desc = 'execute lua',
	desc_separator = ' ',
	buffer = true,
})
local prefix = '<leader>.'
map('n', prefix .. 'x', function()
	vim.cmd('.source')
end, 'lua')
map('n', prefix .. 'X', function()
	vim.cmd('source %')
end, 'file')
map('x', prefix, function()
	vim.cmd("'<'>source")
end, 'visual')
