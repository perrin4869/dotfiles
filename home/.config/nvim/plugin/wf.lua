local defer = require("defer")

defer.on_load("wf", function()
	require("wf").setup()
end)
local with_wf = defer.with("wf")

local map = require("config").create_map({
	mode = "n",
	desc = "[wf.nvim]",
	desc_separator = " ",
	rhs = function(rhs)
		return with_wf(rhs)
	end,
})

-- Register
local register = defer.lazy(function()
	return require("wf.builtin.register")()
end)
map(
	"<Space>wr",
	-- register(opts?: table) -> function
	-- opts?: option
	function(_, ...)
		return register()(...)
	end,
	"register"
)

local bookmark = defer.lazy(function()
	return require("wf.builtin.bookmark")({
		nvim = "~/.config/nvim",
		zsh = "~/.zshrc",
	})
end)
-- Bookmark
map(
	"<Space>wbo",
	-- bookmark(bookmark_dirs: table, opts?: table) -> function
	-- bookmark_dirs: directory or file paths
	-- opts?: option
	function(_, ...)
		return bookmark()(...)
	end,
	"bookmark"
)

-- Buffer
local buffer = defer.lazy(function()
	return require("wf.builtin.buffer")()
end)
map(
	"<Space>wbu",
	-- buffer(opts?: table) -> function
	-- opts?: option
	function(_, ...)
		return buffer()(...)
	end,
	"buffer"
)

-- Mark
local mark = defer.lazy(function()
	return require("wf.builtin.mark")()
end)
map(
	"'",
	-- mark(opts?: table) -> function
	-- opts?: option
	function(_, ...)
		return mark()(...)
	end,
	{ nowait = true, desc = "mark" }
)

-- Which Key
local wk_map = {
	["<Leader>"] = "<Leader>",
	["<Leader>b"] = "buffers",
	-- ["<Leader>c"] = "osc52",
	["<Leader>d"] = "dap",
	["<Leader>e"] = "execute", -- only lua and vim files
	["<Leader>g"] = "fugitive",
	["<Leader>h"] = "hunks",
	["<Leader>n"] = "neotree",
	["<Leader>t"] = "toggle",
	["<Leader>q"] = "persistence",
	["<Leader>."] = "execute",
	[require("pickers").prefix] = "telescope",
}

for key, desc in pairs(wk_map) do
	local cached = defer.lazy(function()
		return require("wf.builtin.which_key")({ text_insert_in_advance = key })
	end)
	map(
		key,
		-- mark(opts?: table) -> function
		-- opts?: option
		function()
			return cached()()
		end,
		"which-key " .. desc
	)
end
