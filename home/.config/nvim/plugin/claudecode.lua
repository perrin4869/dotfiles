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

-- a naive session restore recreates the claude terminal as a dumb shell
-- buffer instead of a proper claudecode.nvim terminal, so close it and
-- reopen it properly instead.
-- match on the terminal's actual argv (not the bufname, which embeds the
-- cwd and could false-positive e.g. inside a directory named "claude-*")
require('restore').add_buf_match(function(bufnr)
	if vim.bo[bufnr].buftype ~= 'terminal' then
		return false
	end
	local ok, chan_info = pcall(vim.api.nvim_get_chan_info, vim.bo[bufnr].channel)
	if not ok or not chan_info.argv then
		return false
	end
	return vim.iter(chan_info.argv):any(function(a)
		return vim.fs.basename(a) == 'claude'
	end)
end, function()
	vim.cmd.ClaudeCodeOpen()
end)
