local defer = require("defer")
defer.on_load("close_buffers", function()
	require("close_buffers").setup({
		filetype_ignore = {}, -- Filetype to ignore when running deletions
		file_glob_ignore = {}, -- File name glob pattern to ignore when running deletions (e.g. '*.md')
		file_regex_ignore = {}, -- File name regex pattern to ignore when running deletions (e.g. '.*[.]md')
		preserve_window_layout = { "this", "nameless" }, -- Types of deletion that should preserve the window layout
		next_buffer_cmd = nil, -- Custom function to retrieve the next buffer when preserving window layout
	})
end)
defer.pack("close_buffers", "close-buffers.nvim")
defer.cmd("BDelete", "close_buffers")
defer.cmd("BWipeout", "close_buffers")
defer.hook("close_buffers")

--- @param lhs string
--- @param type string
local function map(lhs, type)
	vim.keymap.set("n", lhs, function()
		require("close_buffers").delete({ type = type })
	end, { silent = true, noremap = true, desc = "close_buffers." .. type })
end

map("<leader><bs>", "this")
map("<leader><c-h>", "hidden") -- <C-BS> sends <C-h>
