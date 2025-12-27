local defer = require("defer")
local utils = require("utils")

defer.on_load("trouble", function()
	require("trouble").setup()
end)
defer.pack("trouble", "trouble.nvim")
defer.cmd("Trouble", "trouble")
local with_trouble = defer.with("trouble")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_trouble", { clear = true }),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local opts = { silent = true, buffer = args.buf }
		local get_opts = utils.create_get_opts(opts)

		vim.keymap.set(
			"n",
			"<leader>cs",
			with_trouble(defer.call("toggle", { mode = "symbols" })),
			get_opts({ desc = "trouble.symbols" })
		)
		vim.keymap.set(
			"n",
			"<leader>cl",
			with_trouble(defer.call("toggle", {
				mode = "lsp",
				win = { position = "right", size = { width = 0.3 } },
			})),
			get_opts({ desc = "trouble.lsp" })
		)
		vim.keymap.set(
			"n",
			"<leader>xr",
			with_trouble(defer.call("toggle", { mode = "lsp_references", focus = true })),
			get_opts({ desc = "trouble.lsp_references" })
		)
		vim.keymap.set(
			"n",
			"<leader>xi",
			with_trouble(defer.call("toggle", { mode = "lsp_implementations", focus = true })),
			get_opts({ desc = "trouble.lsp_implementations" })
		)
	end,
})

local get_opts = utils.create_get_opts({ silent = true })
vim.keymap.set(
	"n",
	"<leader>xx",
	with_trouble(defer.call("toggle", { mode = "diagnostics" })),
	get_opts({ desc = "trouble.workspace_diagnostics" })
)
vim.keymap.set(
	"n",
	"<leader>xX",
	with_trouble(defer.call("toggle", { mode = "diagnostics", filter = { buf = 0 } })),
	get_opts({ desc = "trouble.document_diagnostics" })
)
vim.keymap.set("n", "<leader>xL", with_trouble(defer.call("toggle", "loclist")), get_opts({ desc = "trouble.loclist" }))
vim.keymap.set("n", "<leader>xQ", with_trouble(defer.call("toggle", "qflist")), get_opts({ desc = "trouble.quickfix" }))
