local defer = require("defer")

defer.on_load("wf", function()
	require("wf").setup()
end)
local with_wf = defer.with("wf")

-- Register
local register = defer.lazy(function()
	return require("wf.builtin.register")()
end)
vim.keymap.set(
	"n",
	"<Space>wr",
	-- register(opts?: table) -> function
	-- opts?: option
	with_wf(function(_, ...)
		return register()(...)
	end),
	{ noremap = true, silent = true, desc = "[wf.nvim] register" }
)

local bookmark = defer.lazy(function()
	return require("wf.builtin.bookmark")({
		nvim = "~/.config/nvim",
		zsh = "~/.zshrc",
	})
end)
-- Bookmark
vim.keymap.set(
	"n",
	"<Space>wbo",
	-- bookmark(bookmark_dirs: table, opts?: table) -> function
	-- bookmark_dirs: directory or file paths
	-- opts?: option
	with_wf(function(_, ...)
		return bookmark()(...)
	end),
	{ noremap = true, silent = true, desc = "[wf.nvim] bookmark" }
)

-- Buffer
local buffer = defer.lazy(function()
	return require("wf.builtin.buffer")()
end)
vim.keymap.set(
	"n",
	"<Space>wbu",
	-- buffer(opts?: table) -> function
	-- opts?: option
	with_wf(function(_, ...)
		return buffer()(...)
	end),
	{ noremap = true, silent = true, desc = "[wf.nvim] buffer" }
)

-- Mark
local mark = defer.lazy(function()
	return require("wf.builtin.mark")()
end)
vim.keymap.set(
	"n",
	"'",
	-- mark(opts?: table) -> function
	-- opts?: option
	with_wf(function(_, ...)
		return mark()(...)
	end),
	{ nowait = true, noremap = true, silent = true, desc = "[wf.nvim] mark" }
)

-- Which Key
local wk_map = {
	["<Leader>"] = "<Leader>",
	["<Leader>b"] = "buffers",
	["<Leader>c"] = "osc52",
	["<Leader>d"] = "dap",
	["<Leader>h"] = "hunks",
	["<Leader>n"] = "neotree",
	["<Leader>t"] = "toggle",
	["<Leader>q"] = "persistence",
	[require("pickers").prefix] = "telescope",
}

for key, desc in pairs(wk_map) do
	local cached = defer.lazy(function()
		return require("wf.builtin.which_key")({ text_insert_in_advance = key })
	end)
	vim.keymap.set(
		"n",
		key,
		-- mark(opts?: table) -> function
		-- opts?: option
		with_wf(function()
			return cached()()
		end),
		{ noremap = true, silent = true, desc = "[wf.nvim] which-key " .. desc }
	)
end
