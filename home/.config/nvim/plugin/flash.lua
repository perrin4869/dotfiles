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

--- @param mode string|string[]
--- @param lhs string
--- @param rhs function
--- @param desc string
--- @param buf? integer
local function map(mode, lhs, rhs, desc, buf)
	local opts = { silent = true, desc = "flash." .. desc }
	if buf then
		opts.buffer = buf
	end
	vim.keymap.set(mode, lhs, rhs, opts)
end

map({ "n", "x", "o" }, "<leader>s", jump, "jump")
map("o", "r", remote, "remote")
map("c", "<C-s>", toggle, "toggle")

-- Treesitter logic
defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			-- duplicate functionality with tree-hopper
			map({ "n", "x", "o" }, "<leader>S", treesitter, "treesitter", args.buf)
			map({ "o", "x" }, "R", treesitter_search, "treesitter_search", args.buf)
		end,
	})
end)
