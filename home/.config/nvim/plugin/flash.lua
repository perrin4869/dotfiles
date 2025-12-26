local defer = require("defer")
local utils = require("utils")

defer.on_load("flash", function(flash)
	flash.setup({
		modes = { char = { enabled = false } },
	})
end)
local with_flash = defer.with("flash")

local jump = with_flash(defer.call("jump"))
local remote = with_flash(defer.call("remote"))
local toggle = with_flash(defer.call("toggle"))
local treesitter = with_flash(defer.call("treesitter"))
local treesitter_search = with_flash(defer.call("treesitter_search"))

local opts = { silent = true }
local get_opts = utils.create_get_opts(opts)

vim.keymap.set({ "n", "x", "o" }, "<leader>s", jump, get_opts({ desc = "flash.jump" }))
vim.keymap.set("o", "r", remote, get_opts({ desc = "flash.remote" }))
vim.keymap.set("c", "<C-s>", toggle, get_opts({ desc = "flash.toggle" }))

-- Treesitter logic
defer.on_event(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			-- duplicate functionality with tree-hopper
			vim.keymap.set(
				{ "n", "x", "o" },
				"<leader>S",
				treesitter,
				get_opts({ buffer = args.buf, desc = "flash.treesitter" })
			)

			vim.keymap.set(
				{ "o", "x" },
				"R",
				treesitter_search,
				get_opts({ buffer = args.buf, desc = "flash.treesitter_search" })
			)
		end,
	})
end, "BufEnter", { name = "treesitter-flash" })
