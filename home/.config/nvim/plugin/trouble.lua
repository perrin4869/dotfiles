local trouble = require("trouble")
local utils = require("utils")

local was_setup = false
local function ensure_setup()
	if was_setup then
		return
	end
	trouble.setup()
	was_setup = true
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_trouble", { clear = true }),
	callback = function(args)
		ensure_setup()

		if not (args.data and args.data.client_id) then
			return
		end

		local opts = { silent = true, buffer = args.buf }
		local get_opts = utils.create_get_opts(opts)

		vim.keymap.set("n", "<leader>cs", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({ mode = "symbols" })
		end, get_opts({ desc = "trouble.symbols" }))
		vim.keymap.set("n", "<leader>cl", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({
				mode = "lsp",
				win = { position = "right", size = { width = 0.3 } },
			})
		end, get_opts({ desc = "trouble.lsp" }))

		vim.keymap.set("n", "<leader>xr", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({ mode = "lsp_references", focus = true })
		end, get_opts({ desc = "trouble.lsp_references" }))
		vim.keymap.set("n", "<leader>xi", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({ mode = "lsp_implementations", focus = true })
		end, get_opts({ desc = "trouble.lsp_implementations" }))
	end,
})

local get_opts = utils.create_get_opts({ silent = true })
vim.keymap.set("n", "<leader>xx", function()
	---@diagnostic disable-next-line: missing-fields
	trouble.toggle({ mode = "diagnostics" })
end, get_opts({ desc = "trouble.workspace_diagnostics" }))
vim.keymap.set("n", "<leader>xX", function()
	---@diagnostic disable-next-line: missing-fields
	trouble.toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, get_opts({ desc = "trouble.document_diagnostics" }))
vim.keymap.set("n", "<leader>xL", function()
	trouble.toggle("loclist")
end, get_opts({ desc = "trouble.loclist" }))
vim.keymap.set("n", "<leader>xQ", function()
	trouble.toggle("qflist")
end, get_opts({ desc = "trouble.quickfix" }))
