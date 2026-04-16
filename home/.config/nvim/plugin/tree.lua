local yall = require('yall')

yall.setup('neo-tree', {
	filesystem = {
		commands = {
			avante_add_files = yall.with('avante')(function(state)
				local node = state.tree:get_node()
				local filepath = node:get_id()
				local relative_path = require('avante.utils').relative_path(filepath)

				local sidebar = require('avante').get()

				local open = sidebar:is_open()
				-- ensure avante sidebar is open
				if not open then
					require('avante.api').ask()
					sidebar = require('avante').get()
				end

				sidebar.file_selector:add_selected_file(relative_path)

				-- remove neo tree buffer
				if not open then
					sidebar.file_selector:remove_selected_file('neo-tree filesystem [1]')
				end
			end),
		},
		window = {
			mappings = {
				['oa'] = 'avante_add_files',
			},
		},
	},
})
yall.pack('neo-tree', 'neo-tree.nvim')
yall.cmd('Neotree', 'neo-tree')

local map = require('map').create({
	mode = 'n',
	desc = 'neo-tree',
	rhs = function(args)
		return function()
			vim.cmd.Neotree(args)
		end
	end,
})

local prefix = '<leader>n'
map(vim.g.toggle_prefix .. 'n', 'toggle', 'toggle')
map(prefix .. 'n', 'focus', 'focus')
map(prefix .. 'f', 'reveal_file=%:p', 'focus-file')

-- ex bufname neo-tree filesystem [1]
require('restore').add_quitpre_ft('neo-tree')
require('restore').add_buf_match('neo%-tree filesystem', function()
	vim.cmd.Neotree('show')
end)
