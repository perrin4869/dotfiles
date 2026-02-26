local defer = require('defer')

defer.on_load('persistence', function()
	require('persistence').setup()
end)
defer.pack('persistence', 'persistence.nvim')
defer.hook('persistence')
defer.on_event('persistence', 'BufReadPre')

local with = defer.with('persistence')

local load = with(function()
	require('persistence').load()
end)

local load_last = with(function()
	require('persistence').load({ last = true })
end)

local stop = with(function()
	require('persistence').stop()
end)

local map = require('map').create({
	mode = 'n',
	desc = 'persistence',
})

local prefix = '<leader>;' -- official docs use `<leader>q`, it conflicts with vim.diagnostic.setloclist
-- restore the session for the current directory
map(prefix .. 's', load, 'load')

-- restore the last session
map(prefix .. 'l', load_last, 'load_last')

-- stop Persistence => session won't be saved on exit
map(prefix .. 'd', stop, 'stop')
