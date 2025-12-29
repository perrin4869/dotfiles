local defer = require("defer")
local utils = require("utils")

local M = {}

local with_telescope = defer.with("telescope")

-- gg would be nice but then you can't jump to the top of the file
M.prefix = "<leader><leader>"
local get_opts = utils.create_get_opts({ noremap = true, silent = true })
M.map = function(lhs, rhs, opts)
	opts = opts or {}

	if type(rhs) == "function" then
		vim.keymap.set("n", lhs, with_telescope(rhs), get_opts({ desc = "telescope." .. opts.desc }))
	else
		vim.keymap.set(
			"n",
			lhs,
			with_telescope(function()
				require("telescope.builtin")[rhs]()
			end),
			get_opts({ desc = "telescope." .. rhs })
		)
	end
end

M.project_files = with_telescope(function()
	local opts = {} -- define here if you want to define something
	local ok = pcall(require("telescope.builtin").git_files, opts)
	if not ok then
		require("telescope.builtin").find_files(opts)
	end
end)

return M
