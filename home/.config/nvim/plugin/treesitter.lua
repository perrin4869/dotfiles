-- cache for per-language indent availability
local indent_cache = {}

local function has_indent(ft)
	local lang = vim.treesitter.language.get_lang(ft)
	if lang ~= nil and indent_cache[lang] == nil then
		indent_cache[lang] = vim.treesitter.query.get(lang, "indents") ~= nil
	end
	return indent_cache[lang]
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		vim.treesitter.start()
		vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo[0][0].foldmethod = "expr"

		-- scala for example doesn't have indents yet
		-- https://github.com/nvim-treesitter/nvim-treesitter/tree/42fc28ba918343ebfd5565147a42a26580579482/queries/scala
		if has_indent(vim.bo[args.buf].ft) then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end

		-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
		vim.opt_local.foldlevelstart = 99
	end,
})
