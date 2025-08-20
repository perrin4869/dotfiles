vim.api.nvim_create_autocmd("FileType", {
	-- TODO: in nvim-treesitter 1.0 this is require("nvim-treesitter.config")
	pattern = require("nvim-treesitter").get_installed(),
	callback = function()
		vim.treesitter.start()
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
