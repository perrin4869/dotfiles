vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local defer = require("defer")
local utils = require("utils")

defer.on_load("nvim-tree.api", function(api)
	require("nvim-tree").setup({
		on_attach = function(bufnr)
			local function opts(desc)
				return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
			end

			-- default mappings
			api.config.mappings.default_on_attach(bufnr)

			-- custom mappings
			vim.keymap.set("n", "<C-t>", api.tree.change_root_to_parent, opts("Up"))
			vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
		end,
	})
end)
defer.hook("nvim-tree.api")

local opts = { noremap = true, silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set("n", "<leader>nn", function()
	require("nvim-tree.api").tree.toggle()
end, get_opts({ desc = "nvim-tree.toggle" }))
vim.keymap.set("n", "<leader>nf", function()
	require("nvim-tree.api").tree.find_file({ focus = true, open = true })
end, get_opts({ desc = "nvim-tree.find_file" }))

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
			local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
			if bufname:match("NvimTree_") ~= nil then
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
