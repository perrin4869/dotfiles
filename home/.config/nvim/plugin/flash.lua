local defer = require("defer")

defer.on_load("flash", function()
	require("flash").setup({
		modes = { char = { enabled = false } },
	})
end)
local with_flash = defer.with("flash")

local jump = with_flash(defer.call("jump"))
local remote = with_flash(defer.call("remote"))
local toggle = with_flash(defer.call("toggle"))
local treesitter = with_flash(defer.call("treesitter"))
local treesitter_search = with_flash(defer.call("treesitter_search"))

local desc = "flash"
local map = require("config").create_map({
	desc = desc,
})

map({ "n", "x", "o" }, "<leader>s", jump, "jump")
map("o", "r", remote, "remote")
map("c", "<C-s>", toggle, "toggle")

-- Treesitter logic
defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			local map_buf = require("config").create_map({
				desc = desc,
				buffer = args.buf,
			})

			-- duplicate functionality with tree-hopper
			map_buf({ "n", "x", "o" }, "<leader>S", treesitter, "treesitter")
			map_buf({ "o", "x" }, "R", treesitter_search, "treesitter_search")
		end,
	})
end)
