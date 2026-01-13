local defer = require("defer")

local M = {}

local with_telescope = defer.with("telescope")

-- gg would be nice but then you can't jump to the top of the file
M.prefix = "<leader><leader>"
--- map a new picker
--- @param lhs string
--- @param rhs function|string
--- @param opts nil|{ desc: string }
M.map = function(lhs, rhs, opts)
	opts = opts or {}
	local desc = opts.desc or rhs
	opts = { noremap = true, silent = true, desc = "telescope." .. desc }

	if type(rhs) == "function" then
		vim.keymap.set("n", lhs, with_telescope(rhs), opts)
	else
		vim.keymap.set(
			"n",
			lhs,
			with_telescope(function()
				require("telescope.builtin")[rhs]()
			end),
			opts
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
