vim.api.nvim_create_autocmd("FileType", {
	-- TODO: in nvim-treesitter 1.0 this is require("nvim-treesitter.config")
	pattern = require("nvim-treesitter.info").installed_parsers(),
	callback = function()
		vim.treesitter.start()
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.bo.foldmethod = "expr"
		-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
		vim.bo.foldlevelstart = 99
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

-- https://alpha2phi.medium.com/neovim-101-tree-sitter-usage-fa3e8bed921a
local swap_next, swap_prev = (function()
	local swap_objects = {
		p = "@parameter.inner",
		f = "@function.outer",
		c = "@class.outer",
	}

	local n, p = {}, {}
	for key, obj in pairs(swap_objects) do
		n[string.format("<A-n><A-%s>", key)] = obj
		p[string.format("<A-p><A-%s>", key)] = obj
	end

	return n, p
end)()

require("nvim-treesitter.configs").setup({
	-- ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
	-- This is handled by the Makefile
	matchup = {
		enable = true, -- mandatory, false will disable the whole extension
	},
	endwise = {
		enable = true,
	},
	textobjects = {
		select = {
			enable = true,

			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,

			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		swap = {
			enable = true,
			swap_next = swap_next,
			swap_previous = swap_prev,
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = { query = "@class.outer", desc = "Next class start" },
				--
				-- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
				["]o"] = "@loop.*",
				-- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
				--
				-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
				-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and
				-- indent.scm.
				["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
				["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
	},
})
