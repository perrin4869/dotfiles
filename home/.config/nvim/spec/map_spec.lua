local map = require('map')
local cleanup = require('helpers/cleanup')

before_each(cleanup.reset)
after_each(cleanup.clean)

-- No child process here: these exercise `lua/map.lua` through the API the config uses, which the runner's own Neovim
-- can do.
describe('map.create', function()
	it('prefixes the description with the module', function()
		cleanup.mapping('n', '<leader>mx')
		map.create({ desc = 'pi', desc_separator = ': ' })('n', '<leader>mx', function() end, 'do x')
		assert.equal('pi: do x', vim.fn.maparg('<leader>mx', 'n', false, true).desc)
	end)

	it('takes the description from a string mapping', function()
		cleanup.mapping('n', '<leader>my')
		map.create()('n', '<leader>my', ':echo 1<cr>')
		assert.equal(':echo 1<cr>', vim.fn.maparg('<leader>my', 'n', false, true).desc)
	end)

	it('maps in the buffer it is given, and nowhere else', function()
		local original = vim.api.nvim_get_current_buf()
		local buffer = cleanup.buffer()
		cleanup.mapping('n', '<leader>mb', buffer)
		map.create({ buffer = buffer })('n', '<leader>mb', function() end, 'buffer only')
		vim.api.nvim_set_current_buf(buffer)
		assert.equal('buffer only', vim.fn.maparg('<leader>mb', 'n', false, true).desc)
		vim.api.nvim_set_current_buf(original)
		assert.is_nil(vim.fn.maparg('<leader>mb', 'n', false, true).desc)
	end)
end)
