local trouble = require("trouble")
local utils = require("utils")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspAttach_trouble", { clear = true }),
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		local opts = { silent = true, buffer = args.buf }
		local get_opts = utils.create_get_opts(opts)

		vim.keymap.set("n", "<leader>xd", function()
			trouble.toggle("diagnostics")
		end, get_opts({ desc = "trouble.document_diagnostics" }))
		vim.keymap.set("n", "gR", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({ mode = "lsp_references", focus = true })
		end, get_opts({ desc = "trouble.lsp_references" }))
		vim.keymap.set("n", "gi", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({ mode = "lsp_implementations", focus = true })
		end, get_opts({ desc = "trouble.lsp_implementations" }))
		vim.keymap.set("n", "<leader>l", function()
			---@diagnostic disable-next-line: missing-fields
			trouble.toggle({
				mode = "lsp",
				win = { position = "right", size = { width = 0.3 } },
			})
		end, get_opts({ desc = "trouble.lsp_references" }))
	end,
})

local get_opts = utils.create_get_opts({ silent = true })
vim.keymap.set("n", "<leader>xx", trouble.toggle, get_opts({ desc = "trouble.toggle" }))
vim.keymap.set("n", "<leader>xf", trouble.focus, get_opts({ desc = "trouble.focus" }))
vim.keymap.set("n", "<leader>xw", function()
	trouble.toggle("workspace_diagnostics")
end, get_opts({ desc = "trouble.workspace_diagnostics" }))
vim.keymap.set("n", "<leader>xl", function()
	trouble.toggle("loclist")
end, get_opts({ desc = "trouble.loclist" }))
vim.keymap.set("n", "<leader>xq", function()
	trouble.toggle("quickfix")
end, get_opts({ desc = "trouble.quickfix" }))
