local defer = require("defer")

defer.on_load("nvim-treesitter-textobjects", function()
	require("nvim-treesitter-textobjects").setup({
		select = {
			-- Automatically jump forward to textobj, similar to targets.vim
			lookahead = true,
			-- You can choose the select mode (default is charwise 'v')
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * method: eg 'v' or 'o'
			-- and should return the mode ('v', 'V', or '<c-v>') or a table
			-- mapping query_strings to modes.
			selection_modes = {
				["@parameter.outer"] = "v", -- charwise
				["@function.outer"] = "V", -- linewise
				["@class.outer"] = "<c-v>", -- blockwise
			},
			-- If you set this to `true` (default is `false`) then any textobject is
			-- extended to include preceding or succeeding whitespace. Succeeding
			-- whitespace has priority in order to act similarly to eg the built-in
			-- `ap`.
			--
			-- Can also be a function which gets passed a table with the keys
			-- * query_string: eg '@function.inner'
			-- * selection_mode: eg 'v'
			-- and should return true of false
			include_surrounding_whitespace = false,
		},
		move = {
			-- whether to set jumps in the jumplist
			set_jumps = true,
		},
	})
end)
defer.on_bufreadpost("nvim-treesitter-textobjects")

defer.on_bufreadpre(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			local next_move = require("nvim-next.move")
			local move = require("nvim-treesitter-textobjects.move")

			local map = require("map").create({
				desc = "textobjects",
				buffer = args.buf,
			})

			-- keymaps
			-- You can use the capture groups defined in `textobjects.scm`
			map({ "x", "o" }, "af", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end, "select.@function.outer")
			map({ "x", "o" }, "if", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end, "select.@function.inner")
			map({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end, "select.@class.outer")
			map({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end, "select.@class.inner")
			-- You can also use captures from other query groups like `locals.scm`
			map({ "x", "o" }, "as", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
			end, "select.@local.scope")

			-- keymaps
			map("n", "<leader>a", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
			end, "swap.next.@parameter.inner")
			map("n", "<leader>A", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
			end, "swap.previous.@parameter.outer")

			-- https://alpha2phi.medium.com/neovim-101-tree-sitter-usage-fa3e8bed921a
			local swap_objects = {
				p = "@parameter.inner",
				f = "@function.outer",
				c = "@class.outer",
			}

			for key, obj in pairs(swap_objects) do
				map("n", string.format("<A-n><A-%s>", key), function()
					require("nvim-treesitter-textobjects.swap").swap_next(obj)
				end, string.format("swap.next.%s", obj))
				map("n", string.format("<A-p><A-%s>", key), function()
					require("nvim-treesitter-textobjects.swap").swap_previous(obj)
				end, string.format("swap.previous.%s", obj))
			end

			local prev_func_start, next_func_start = next_move.make_repeatable_pair(function()
				move.goto_previous_start("@function.outer", "textobjects")
			end, function()
				move.goto_next_start("@function.outer", "textobjects")
			end)

			local prev_class_start, next_class_start = next_move.make_repeatable_pair(function()
				move.goto_previous_start("@class.outer", "textobjects")
			end, function()
				move.goto_next_start("@class.outer", "textobjects")
			end)

			local prev_func_end, next_func_end = next_move.make_repeatable_pair(function()
				move.goto_previous_end("@function.outer", "textobjects")
			end, function()
				move.goto_next_end("@function.outer", "textobjects")
			end)

			local prev_class_end, next_class_end = next_move.make_repeatable_pair(function()
				move.goto_previous_end("@class.outer", "textobjects")
			end, function()
				move.goto_next_end("@class.outer", "textobjects")
			end)

			local next_loop = next_move.make_forward_repeatable_move(function()
				move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
			end, function()
				move.goto_previous_start({ "@loop.inner", "@loop.outer" }, "textobjects")
			end)

			local next_scope = next_move.make_forward_repeatable_move(function()
				move.goto_next_start("@local.scope", "locals")
			end, function()
				move.goto_previous_start("@local.scope", "locals")
			end)

			local next_fold = next_move.make_forward_repeatable_move(function()
				move.goto_next_start("@fold", "folds")
			end, function()
				move.goto_previous_start("@fold", "folds")
			end)

			-- keymaps
			-- You can use the capture groups defined in `textobjects.scm`
			map({ "n", "x", "o" }, "]m", next_func_start, "move.next_start.@function.outer")
			map({ "n", "x", "o" }, "]]", next_class_start, "move.next_start.@class.outer")
			-- You can also pass a list to group multiple queries.
			map({ "n", "x", "o" }, "]o", next_loop, "move.next_start.@loop.inner")
			-- You can also use captures from other query groups like `locals.scm` or `folds.scm`
			map({ "n", "x", "o" }, "]s", next_scope, "move.next_start.@local.scope")
			map({ "n", "x", "o" }, "]z", next_fold, "move.next_start.@fold")

			map({ "n", "x", "o" }, "]M", next_func_end, "move.next_end.@function.outer")
			map({ "n", "x", "o" }, "][", next_class_end, "move.next_end.@class.outer")

			map({ "n", "x", "o" }, "[m", prev_func_start, "move.previous_start.@function.outer")
			map({ "n", "x", "o" }, "[[", prev_class_start, "move.previous_start.@class.outer")

			map({ "n", "x", "o" }, "[M", prev_func_end, "move.previous_end.@function.outer")
			map({ "n", "x", "o" }, "[]", prev_class_end, "move.previous_end.@class.outer")

			-- the next one conflicts with next/prev diagnostics
			--
			-- Go to either the start or the end, whichever is closer.
			-- Use if you want more granular movements
			-- map({ "n", "x", "o" }, "]d", function()
			-- 	move.goto_next("@conditional.outer", "textobjects")
			-- end, "move.next.@conditional.outer")
			-- map({ "n", "x", "o" }, "[d", function()
			-- 	move.goto_previous("@conditional.outer", "textobjects")
			-- end, "move.previous.@conditional.outer")
		end,
	})
end)
