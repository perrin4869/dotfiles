local map = require('map')

-- Each case declares the mappings and buffers it creates; after_each removes exactly those, so a case that fails
-- early cannot leave one behind for the next.
local registered = {}
local buffers = {}

before_each(function()
	registered = {}
	buffers = {}
end)

after_each(function()
	for _, entry in ipairs(registered) do
		pcall(vim.keymap.del, entry.mode, entry.lhs, entry.buffer and { buffer = entry.buffer } or {})
	end
	for _, buffer in ipairs(buffers) do
		pcall(vim.api.nvim_buf_delete, buffer, { force = true })
	end
end)

local function register(mode, lhs, buffer)
	registered[#registered + 1] = { mode = mode, lhs = lhs, buffer = buffer }
end

local function scratch_buffer()
	local buffer = vim.api.nvim_create_buf(false, true)
	buffers[#buffers + 1] = buffer
	return buffer
end

-- No child process here: these exercise `lua/map.lua` through the API the config uses, which the runner's own Neovim
-- can do.
describe('map.create', function()
	it('prefixes the description with the module', function()
		register('n', '<leader>mx')
		map.create({ desc = 'pi', desc_separator = ': ' })('n', '<leader>mx', function() end, 'do x')
		assert.equal('pi: do x', vim.fn.maparg('<leader>mx', 'n', false, true).desc)
	end)

	it('takes the description from a string mapping', function()
		register('n', '<leader>my')
		map.create()('n', '<leader>my', ':echo 1<cr>')
		assert.equal(':echo 1<cr>', vim.fn.maparg('<leader>my', 'n', false, true).desc)
	end)

	it('maps in the buffer it is given, and nowhere else', function()
		local original = vim.api.nvim_get_current_buf()
		local buffer = scratch_buffer()
		register('n', '<leader>mb', buffer)
		map.create({ buffer = buffer })('n', '<leader>mb', function() end, 'buffer only')
		vim.api.nvim_set_current_buf(buffer)
		assert.equal('buffer only', vim.fn.maparg('<leader>mb', 'n', false, true).desc)
		vim.api.nvim_set_current_buf(original)
		assert.is_nil(vim.fn.maparg('<leader>mb', 'n', false, true).desc)
	end)
end)
