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

local map = require('map').create({ desc = 'cloudecode', desc_separator = ': ' })
local prefix = '<leader>C'
local claude = function(cmd, args)
	if type(cmd) == 'table' then
		args = cmd
		cmd = ''
	else
		cmd = cmd or ''
		args = args or {}
	end

	return function()
		vim.cmd['ClaudeCode' .. cmd](unpack(args))
	end
end
map('n', prefix .. 'c', claude(), 'toggle')
map('n', prefix .. 'f', claude('Focus'), 'focus')
map('n', prefix .. 'r', claude({ '--resume' }), 'resume')
map('n', prefix .. 'C', claude({ '--continue' }), 'continue')
map('n', prefix .. 'm', claude('SelectModel'), 'select_model')
map('n', prefix .. 'b', claude('Add', { '%' }), 'add_current_buffer')
map('v', prefix .. 's', claude('Send'), 'send')
map('n', prefix .. 'a', claude('DiffAccept'), 'accept_diff')
map('n', prefix .. 'd', claude('DiffDeny'), 'deny_diff')

vim.api.nvim_create_autocmd('FileType', {
	group = vim.api.nvim_create_augroup('claudecode_mappings', { clear = true }),
	pattern = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw', 'snacks_picker_list' },
	callback = function(args)
		map('n', prefix .. 's', claude('TreeAdd'), { desc = 'add_file', buffer = args.buf })
	end,
})

map('n', vim.g.toggle_prefix .. 'c', function()
	vim.cmd.ClaudeCode()
end, 'toggle')
