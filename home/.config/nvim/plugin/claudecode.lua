local yall = require('yall')
yall.pack('claudecode', 'claudecode.nvim')
yall.setup('claudecode')

vim
	.iter({
		'',
		'Focus',
		'SelectModel',
		'Add',
		'Send',
		'TreeAdd',
		'Status',
		'Start',
		'Stop',
		'Open',
		'Close',
		'DiffAccept',
		'DiffDeny',
		'CloseAllDiffs',
	})
	:each(function(cmd)
		yall.cmd('ClaudeCode' .. cmd, 'claudecode')
	end)

local map = require('map').create({ desc = 'cloudecode', desc_separator = ': ', mode = 'n' })
local prefix = '<leader>C'
map(prefix .. 'r', function()
	vim.cmd.ClaudeCode('--resume')
end, 'resume')
map(prefix .. 'b', function()
	vim.cmd.ClaudeCodeAdd('%')
end, 'focus')

map(vim.g.toggle_prefix .. 'c', function()
	vim.cmd.ClaudeCode()
end, 'toggle')
