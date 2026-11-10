-- Specs declare the mappings and buffers they create; the cleaning phase removes exactly those, so a case that fails
-- early cannot leave one behind for the next. The hooks are registered by the spec, because a required module runs
-- outside the environment where busted exports before_each and after_each.
local M = {}

local mappings = {}
local buffers = {}

function M.reset()
	mappings = {}
	buffers = {}
end

function M.clean()
	for _, entry in ipairs(mappings) do
		pcall(vim.keymap.del, entry.mode, entry.lhs, entry.buffer and { buffer = entry.buffer } or {})
	end
	for _, buffer in ipairs(buffers) do
		pcall(vim.api.nvim_buf_delete, buffer, { force = true })
	end
end

--- @param mode string
--- @param lhs string
--- @param buffer? integer
function M.mapping(mode, lhs, buffer)
	mappings[#mappings + 1] = { mode = mode, lhs = lhs, buffer = buffer }
end

--- @return integer buffer
function M.buffer()
	local buffer = vim.api.nvim_create_buf(false, true)
	buffers[#buffers + 1] = buffer
	return buffer
end

return M
