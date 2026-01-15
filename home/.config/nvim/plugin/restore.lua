vim.api.nvim_create_autocmd('QuitPre', {
	callback = function()
		local restore_wins = {}
		local ignore_wins = {}
		local floating_wins = {}
		-- consider also trying vim.fn.winlayout()
		local wins = vim.api.nvim_list_wins()
		for _, w in ipairs(wins) do
			local bufnr = vim.api.nvim_win_get_buf(w)
			local ft = vim.bo[bufnr].filetype
			-- ignore empty buffers (no name and no ft)
			if require('restore').ft(ft) then
				table.insert(restore_wins, w)
			elseif ft == '' and vim.api.nvim_buf_get_name(bufnr) == '' then
				table.insert(ignore_wins, w)
			elseif vim.api.nvim_win_get_config(w).relative ~= '' then
				table.insert(floating_wins, w)
			end
		end
		if 1 == #wins - #floating_wins - #restore_wins - #ignore_wins then
			-- save the session before closing the windows, otherwise the tree state does not get saved
			local persistence = require('persistence')
			if persistence.active() then
				persistence.save()
				persistence.stop()
			end

			-- Should quit, so we close all invalid windows.
			for _, w in ipairs(restore_wins) do
				vim.api.nvim_win_close(w, true)
			end
		end
	end,
})
