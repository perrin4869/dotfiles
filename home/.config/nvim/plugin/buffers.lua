local defer = require('defer')
defer.on_load('close_buffers', function()
	require('close_buffers').setup({
		filetype_ignore = {}, -- Filetype to ignore when running deletions
		file_glob_ignore = {}, -- File name glob pattern to ignore when running deletions (e.g. '*.md')
		file_regex_ignore = {}, -- File name regex pattern to ignore when running deletions (e.g. '.*[.]md')
		preserve_window_layout = { 'this', 'nameless' }, -- Types of deletion that should preserve the window layout
		next_buffer_cmd = nil, -- Custom function to retrieve the next buffer when preserving window layout
	})
end)
defer.pack('close_buffers', 'close-buffers.nvim')
defer.cmd('BDelete', 'close_buffers')
defer.cmd('BWipeout', 'close_buffers')

defer.very_lazy(function()
	local function safe_jump_back()
		local jumplist, cur_idx = unpack(vim.fn.getjumplist())

		-- cur_idx is 0-indexed. The previous jump is at cur_idx - 1.
		-- We use +1 because Lua tables are 1-indexed.
		local prev_jump_idx = cur_idx -- This points to the entry before current in 1-indexing

		if prev_jump_idx > 0 then
			local prev_jump = jumplist[prev_jump_idx]
			local bufnr = prev_jump.bufnr

			-- Check if the buffer is valid and loaded in Neovim
			if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
				vim.cmd.normal({ vim.api.nvim_replace_termcodes('<C-o>', true, false, true), bang = true })
			end
		end
	end

	local map = require('map').create({
		mode = 'n',
		desc = 'close_buffers',
		rhs = function(type)
			return defer.with('close_buffers')(function(close_buffers)
				if type == 'this' and #vim.fn.getbufinfo({ buflisted = 1 }) == 1 then
					vim.cmd('q')
				end
				close_buffers.delete({ type = type })
				if type == 'this' then
					safe_jump_back()
				end
			end)
		end,
	})

	map('<leader><bs>', 'this')
	map('<leader><c-h>', 'hidden') -- <C-BS> sends <C-h>
end)

defer.very_lazy(function()
	local next_move = require('nvim-next.move')

	local function cokeline_or_buf(cokeline_focus_direction, bufcmd)
		return function()
			if package.loaded['cokeline'] then
				require('cokeline.mappings').by_step('focus', cokeline_focus_direction)
			else
				vim.cmd(bufcmd)
			end
		end
	end

	-- buffers
	local prev_buffers, next_buffers = require('trigger').trigger(
		'b',
		next_move.make_repeatable_pair(cokeline_or_buf(-1, 'bprevious'), cokeline_or_buf(1, 'bnext'))
	)

	local map = require('map').map
	map('n', '[b', prev_buffers, 'Go to previous buffer')
	map('n', ']b', next_buffers, 'Go to next buffer')
end)
