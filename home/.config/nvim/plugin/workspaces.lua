local project_files = require("project_files")
local persistence = require("persistence")

local function toggle_tree()
	require("nvim-tree.api").tree.toggle({ focus = false })
end

require("workspaces").setup({
	hooks = {
		open = function()
			if vim.uv.fs_stat(require("persistence").current()) ~= nil then
				-- force the current session file to reload since cwd has changed
				-- maybe send a PR for a persistence.set_current()
				persistence.stop()
				persistence.start()

				persistence.load()
				toggle_tree()
			else
				toggle_tree()
				project_files()
			end
		end,
	},
})
