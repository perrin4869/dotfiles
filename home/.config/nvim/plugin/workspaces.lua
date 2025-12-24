local pickers = require("pickers")
local persistence = require("persistence")

require("workspaces").setup({
	auto_open = true,
	hooks = {
		-- first argument is the workspace name
		open_pre = function(_, path)
			if persistence.active() then
				local cwd = vim.uv.cwd()
				if cwd and vim.fs.normalize(cwd) ~= vim.fs.normalize(path) then
					persistence.save()
				end
				persistence.stop()
			end
		end,
		open = function()
			persistence.start()
			if vim.uv.fs_stat(require("persistence").current()) ~= nil then
				persistence.load()

				local wins = vim.api.nvim_list_wins()
				for _, w in ipairs(wins) do
					local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
					if bufname:match("NvimTree_") ~= nil then
						require("nvim-tree.api").tree.toggle({ focus = false })
						break
					end
				end
			else
				pickers.project_files()
			end
		end,
	},
})
