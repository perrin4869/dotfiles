-- vim.api.nvim_create_autocmd("BufEnter", {
--   group = vim.api.nvim_create_augroup("NvimTreeClose", {clear = true}),
--   pattern = "NvimTree_*",
--   callback = function()
--     local layout = vim.fn.winlayout()
--     if layout[1] == "leaf" and vim.bo[vim.api.nvim_win_get_buf(layout[2])].ft == "NvimTree" and layout[3] == nil then
--       vim.cmd("confirm quit")
--     end
--   end
-- })

vim.api.nvim_create_autocmd("QuitPre", {
	callback = function()
		local tree_wins = {}
		local floating_wins = {}
		local wins = vim.api.nvim_list_wins()
		for _, w in ipairs(wins) do
			local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
			if ft == "neo-tree" or ft == "neotest-summary" then
				table.insert(tree_wins, w)
			end
			if vim.api.nvim_win_get_config(w).relative ~= "" then
				table.insert(floating_wins, w)
			end
		end
		if 1 == #wins - #floating_wins - #tree_wins then
			-- save the session before closing the windows, otherwise the tree state does not get saved
			local persistence = require("persistence")
			if persistence.active() then
				persistence.save()
				persistence.stop()
			end

			-- Should quit, so we close all invalid windows.
			for _, w in ipairs(tree_wins) do
				vim.api.nvim_win_close(w, true)
			end
		end
	end,
})
