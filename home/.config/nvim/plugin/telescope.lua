local defer = require("defer")

local utils = require("utils")
local pickers = require("pickers")

defer.on_load("telescope", function()
	local telescope = require("telescope")
	telescope.setup({
		pickers = {
			find_files = { hidden = true },
		},
	})

	-- Load extensions only after telescope itself is initialized
	local extensions = { "fzf", "neoclip", "file_browser", "workspaces", "git_grep" }
	for _, ext in ipairs(extensions) do
		telescope.load_extension(ext)
	end
end)
defer.pack("telescope", "telescope.nvim")
defer.cmd("Telescope", "telescope")

-- Mappings.
local get_opts = utils.create_get_opts({ noremap = true, silent = true })

vim.keymap.set("n", "<C-p>", pickers.project_files, get_opts({ desc = "project_files" }))

local prefix = pickers.prefix

-- nvim-lua/kickstart.nvim uses <leader>s, but it conflicts with flash.nvim (easymotion)
pickers.map(prefix .. "f", "find_files")
pickers.map(prefix .. "j", "current_buffer_fuzzy_find")
pickers.map(prefix .. "h", "help_tags")
pickers.map(prefix .. "t", "tags")
pickers.map(prefix .. "s", "grep_string")
pickers.map(prefix .. "r", "live_grep")
pickers.map(prefix .. "k", "keymaps")
pickers.map(prefix .. "a", "autocommands")

pickers.map("<leader><CR>", "buffers")
pickers.map("<leader>?", "oldfiles")

pickers.map(prefix .. "o", function()
	require("telescope.builtin").tags({ only_current_buffer = true })
end, { desc = "tags" })
pickers.map(prefix .. "c", function(telescope)
	telescope.extensions.neoclip.default()
end, { desc = "neoclip" })
pickers.map(prefix .. "t", function(telescope)
	telescope.extensions.file_browser.file_browser()
end, { desc = "file_browser" })
pickers.map(prefix .. "w", function(telescope)
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

pickers.map(prefix .. "p", git_grep_conditional, { desc = "git_grep" })
pickers.map(prefix .. "gb", "git_branches")
pickers.map(prefix .. "gc", "git_commits")
pickers.map(prefix .. "gs", "git_status")
