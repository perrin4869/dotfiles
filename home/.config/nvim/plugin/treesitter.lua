vim.api.nvim_create_autocmd("FileType", {
	-- TODO: in nvim-treesitter 1.0 this is require("nvim-treesitter.config")
	pattern = require("nvim-treesitter").get_installed(),
	callback = function()
		vim.treesitter.start()
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.bo.foldmethod = "expr"
		-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
		vim.bo.foldlevelstart = 99
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
