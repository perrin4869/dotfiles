local yall = require('yall')

yall.on_load('flash', function()
	require('flash').setup({
		modes = { char = { enabled = false } },
	})
end)
local with = yall.with('flash')

local jump = with(function()
	require('flash').jump()
end)
local remote = with(function()
	require('flash').remote()
end)
local toggle = with(function()
	require('flash').toggle()
end)
local treesitter = with(function()
	require('flash').treesitter()
end)
local treesitter_search = with(function()
	require('flash').treesitter_search()
end)

local desc = 'flash'
local map = require('map').create({
	desc = desc,
})

map({ 'n', 'x', 'o' }, '<leader>s', jump, 'jump')
map('o', 'r', remote, 'remote')
map('c', '<C-s>', toggle, 'toggle')

-- Treesitter logic
yall.on_bufreadpre(function()
	vim.api.nvim_create_autocmd('FileType', {
		pattern = require('nvim-treesitter').get_installed(),
		callback = function(args)
			local map_buf = require('map').create({
				desc = desc,
				buffer = args.buf,
			})

			-- duplicate functionality with tree-hopper
			map_buf({ 'n', 'x', 'o' }, '<leader>S', treesitter, 'treesitter')
			map_buf({ 'o', 'x' }, 'R', treesitter_search, 'treesitter_search')
		end,
	})
end)
