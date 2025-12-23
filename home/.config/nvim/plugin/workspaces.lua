local project_files = require("project_files")
local persistence = require("persistence")

local function toggle_tree()
	require("nvim-tree.api").tree.toggle({ focus = false })
end

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
						toggle_tree()
						break
					end
				end
			else
				toggle_tree()
				project_files()
			end
		end,
	},
})
