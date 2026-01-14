local defer = require("defer")

defer.on_load("trouble", function()
	require("trouble").setup()
end)
defer.pack("trouble", "trouble.nvim")
defer.cmd("Trouble", "trouble")
local with_trouble = defer.with("trouble")

local map = require("map").create({
	mode = "n",
	desc = "trouble",
	rhs = function(args)
		return with_trouble(defer.call("toggle", args))
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_trouble", { clear = true }),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		---@param lhs string
		---@param opts string|table
		---@param desc string
		local function map_lsp(lhs, opts, desc)
			map(lhs, opts, { desc = desc, buffer = args.buf })
		end

		map_lsp("<leader>cs", { mode = "symbols" }, "symbols")
		map_lsp("<leader>cl", {
			mode = "lsp",
			win = { position = "right", size = { width = 0.3 } },
		}, "lsp")
		map_lsp("<leader>xr", { mode = "lsp_references", focus = true }, "lsp_references")
		map_lsp("<leader>xi", { mode = "lsp_implementations", focus = true }, "lsp_implementations")
	end,
})

local prefix = "<leader>x"
map(prefix .. "x", { mode = "diagnostics" }, "workspace_diagnostics")
map(prefix .. "X", { mode = "diagnostics", filter = { buf = 0 } }, "document_diagnostics")
map(prefix .. "L", "loclist", "loclist")
map(prefix .. "Q", "qflist", "quickfix")
