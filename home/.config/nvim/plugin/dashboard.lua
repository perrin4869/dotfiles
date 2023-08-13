require("dashboard").setup({
	config = {
		week_header = {
			enable = true,
		},
		footer = { "", " NVIM " .. tostring(vim.version()) },
	},
})

vim.api.nvim_create_autocmd("FileType", {
	desc = "Dashboard keymaps",
	pattern = "dashboard",
	group = vim.api.nvim_create_augroup("Dashboard_keymaps", { clear = true }),
	callback = function(opts)
		vim.keymap.set("n", "q", function()
			vim.cmd.bdelete()
		end, { buffer = opts.buf, silent = true, noremap = true, desc = "dashboard.exit" })
		vim.keymap.set("n", "i", function()
			vim.cmd.bdelete()
			vim.cmd.startinsert()
		end, { buffer = opts.buf, silent = true, noremap = true, desc = "dashboard.exit_and_edit" })
	end,
})
