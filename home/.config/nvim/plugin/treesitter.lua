vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function()
		vim.treesitter.start()
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
		vim.opt_local.foldlevelstart = 99
	end,
})
