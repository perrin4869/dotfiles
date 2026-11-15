local M = {}

---@type table<string, boolean>
local fts = { qf = true }
---@alias restore.matcher string|fun(bufnr: integer, bufname: string): boolean
---@type table<restore.matcher, fun(): nil>
local matches = {}

--- @param ft string
function M.add_quitpre_ft(ft)
	fts[ft] = true
end

--- @param ft string
function M.ft(ft)
	return fts[ft]
end

--- @param match restore.matcher a Lua pattern matched against bufname, or a predicate given (bufnr, bufname)
--- @param restore (fun(): nil)|nil
function M.add_buf_match(match, restore)
	matches[match] = restore or function() end
end

--- @param program string
--- @return fun(bufnr: integer): boolean # whether the buffer is a terminal running `program`
function M.terminal(program)
	return function(bufnr)
		if vim.bo[bufnr].buftype ~= 'terminal' then
			return false
		end
		local ok, chan_info = pcall(vim.api.nvim_get_chan_info, vim.bo[bufnr].channel)
		if not ok or not chan_info.argv then
			return false
		end
		-- a session restore respawns it through 'shell' ({ 'zsh', '-c', '/path/to/claude --resume' })
		return vim.tbl_contains(chan_info.argv, function(arg)
			return vim.fs.basename(vim.split(arg, ' ')[1]) == program
		end, { predicate = true })
	end
end

--- restore opened windows
function M.restore()
	local wins = vim.api.nvim_list_wins()
	local remaining = #wins
	for _, w in ipairs(wins) do
		local bufnr = vim.api.nvim_win_get_buf(w)
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		if
			-- Nvim 0.12 annotates Iter:any without its predicate
			---@diagnostic disable-next-line: redundant-parameter
			not vim.iter(matches):any(function(m, r)
				local is_match
				if type(m) == 'function' then
					is_match = m(bufnr, bufname)
				else
					is_match = bufname:match(m) ~= nil
				end
				if is_match then
					vim.api.nvim_win_close(w, true)
					vim.api.nvim_buf_delete(bufnr, { force = true })
					remaining = remaining - 1
					r()
					return true
				end
				return false
			end)
			--- do not restore empty buffers (no bufname and no filetype)
			and bufname == ''
			and vim.bo[bufnr].filetype == ''
			and remaining > 1 -- do not try to close the main window
		then
			vim.api.nvim_win_close(w, true)
			vim.api.nvim_buf_delete(bufnr, { force = true })
			remaining = remaining - 1
		end
	end
end

return M
