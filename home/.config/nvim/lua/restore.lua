local M = {}

---@type table<string, boolean>
local fts = { qf = true }
---@type table<string, fun(): nil>
local matches = {}

--- @param ft string
function M.add_quitpre_ft(ft)
	fts[ft] = true
end

--- @param ft string
function M.ft(ft)
	return fts[ft]
end

--- @param match string
--- @param restore fun(): nil
function M.add_buf_match(match, restore)
	matches[match] = restore
end

--- restore opened windows
function M.restore()
	local wins = vim.api.nvim_list_wins()
	for _, w in ipairs(wins) do
		local bufnr = vim.api.nvim_win_get_buf(w)
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		if
			not vim.iter(matches):any(function(m, r)
				if bufname:match(m) ~= nil then
					vim.api.nvim_win_close(w, true)
					vim.api.nvim_buf_delete(bufnr, { force = true })
					r()
					return true
				end
				return false
			end)
			--- do not restore empty buffers (no bufname and no filetype)
			and bufname == ''
			and vim.bo[bufnr].filetype == ''
		then
			vim.api.nvim_win_close(w, true)
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end
end

return M
