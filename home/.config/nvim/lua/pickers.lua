local defer = require('defer')

local M = {}

local with_telescope = defer.with('telescope')

-- gg would be nice but then you can't jump to the top of the file
M.prefix = '<leader><leader>'
--- map a new picker
M.map = require('map').create({
	mode = 'n',
	desc = 'telescope',
	rhs = function(rhs)
		if type(rhs) == 'function' then
			return with_telescope(rhs)
		else
			return with_telescope(function()
				require('telescope.builtin')[rhs]()
			end)
		end
	end,
})

M.project_files = with_telescope(function()
	local opts = {} -- define here if you want to define something
	local ok = pcall(require('telescope.builtin').git_files, opts)
	if not ok then
		require('telescope.builtin').find_files(opts)
	end
end)

return M
