local project_files = require("project_files")
local persistence = require("persistence")

local function toggle_tree()
	require("nvim-tree.api").tree.toggle({ focus = false })
end

require("workspaces").setup({
	hooks = {
		open = function()
			if vim.fn.filereadable(persistence.get_current()) ~= 0 then
				persistence.load()
				toggle_tree()
			else
				toggle_tree()
				project_files()
			end
		end,
	},
})
