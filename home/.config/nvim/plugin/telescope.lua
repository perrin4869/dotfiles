local defer = require("defer")

local utils = require("utils")
local pickers = require("pickers")

defer.on_load("telescope", function(telescope)
	telescope.setup({
		pickers = {
			find_files = { hidden = true },
		},
	})

	-- Load extensions only after telescope itself is initialized
	local extensions = { "fzf", "dap", "neoclip", "file_browser", "workspaces", "git_grep" }
	for _, ext in ipairs(extensions) do
		telescope.load_extension(ext)
	end
end, "telescope.nvim")
defer.cmd("Telescope", "telescope")

-- Mappings.
local get_opts = utils.create_get_opts({ noremap = true, silent = true })

vim.keymap.set("n", "<C-p>", pickers.project_files, get_opts({ desc = "project_files" }))

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with flash.nvim (easymotion)
pickers.map("f", "find_files")
pickers.map("j", "current_buffer_fuzzy_find")
pickers.map("h", "help_tags")
pickers.map("t", "tags")
pickers.map("d", "grep_string")
pickers.map("r", "live_grep")
pickers.map("k", "keymaps")
pickers.map("a", "autocommands")

pickers.map("<leader><CR>", "buffers", { prefix = false })
pickers.map("<leader>?", "oldfiles", { prefix = false })

pickers.map("o", function()
	require("telescope.builtin").tags({ only_current_buffer = true })
end, { desc = "tags" })
pickers.map("c", function(telescope)
	telescope.extensions.neoclip.default()
end, { desc = "neoclip" })
pickers.map("t", function(telescope)
	telescope.extensions.file_browser.file_browser()
end, { desc = "file_browser" })
pickers.map("w", function(telescope)
	telescope.extensions.workspaces.workspaces()
end, { desc = "workspaces" }) -- r for ripgrep

-- git
local git_grep_conditional = function()
	-- if called outside a git directory it returns a non-zero exit code
	vim.fn.system(string.format("git -C %s rev-parse --show-toplevel", vim.fn.expand("%:p:h")))
	if vim.v.shell_error == 0 then
		require("git_grep").live_grep()
	else
		require("telescope.builtin").live_grep()
	end
end

pickers.map("p", git_grep_conditional, { desc = "git_grep" })
pickers.map("b", "git_branches")
pickers.map("g", "git_commits")
pickers.map("s", "git_status")
