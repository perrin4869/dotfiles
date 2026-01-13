local M = {}

---@type table<string, boolean>
local fts = {}
---@type table<string, fun(): nil>
local matches = {}

--- @param ft string
function M.ft(ft)
	return fts[ft]
end

--- @param ft string
function M.add_quitpre_ft(ft)
	fts[ft] = true
end

--- @param match string
--- @param restore fun(): nil
function M.add_buf_match(match, restore)
	matches[match] = restore
end

--- @return Iter
function M.get_buf_matches()
	return vim.iter(matches)
end

return M
