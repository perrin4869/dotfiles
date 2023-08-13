require("dashboard").setup({
	config = {
		week_header = {
			enable = true,
		},
		footer = { "", " NVIM " .. tostring(vim.version()) },
	},
})

