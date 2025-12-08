local which_key = require("wf.builtin.which_key")
local register = require("wf.builtin.register")
local bookmark = require("wf.builtin.bookmark")
local buffer = require("wf.builtin.buffer")
local mark = require("wf.builtin.mark")

require("wf").setup()

-- Register
vim.keymap.set(
	"n",
	"<Space>wr",
	-- register(opts?: table) -> function
	-- opts?: option
	register(),
	{ noremap = true, silent = true, desc = "[wf.nvim] register" }
)

-- Bookmark
vim.keymap.set(
	"n",
	"<Space>wbo",
	-- bookmark(bookmark_dirs: table, opts?: table) -> function
	-- bookmark_dirs: directory or file paths
	-- opts?: option
	bookmark({
		nvim = "~/.config/nvim",
		zsh = "~/.zshrc",
	}),
	{ noremap = true, silent = true, desc = "[wf.nvim] bookmark" }
)

-- Buffer
vim.keymap.set(
	"n",
	"<Space>wbu",
	-- buffer(opts?: table) -> function
	-- opts?: option
	buffer(),
	{ noremap = true, silent = true, desc = "[wf.nvim] buffer" }
)

-- Mark
vim.keymap.set(
	"n",
	"'",
	-- mark(opts?: table) -> function
	-- opts?: option
	mark(),
	{ nowait = true, noremap = true, silent = true, desc = "[wf.nvim] mark" }
)

-- Which Key
local wk_map = {
	["<Leader>"] = "<Leader>",
	["<Leader>b"] = "buffers",
	["<Leader>h"] = "hunks",
	["<Leader>d"] = "dap",
	[require("settings").telesope_prefix] = "telescope",
}

for key, desc in pairs(wk_map) do
	vim.keymap.set(
		"n",
		key,
		-- mark(opts?: table) -> function
		-- opts?: option
		which_key({ text_insert_in_advance = key }),
		{ noremap = true, silent = true, desc = "[wf.nvim] which-key " .. desc }
	)
end
