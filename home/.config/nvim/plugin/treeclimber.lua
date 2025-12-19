require("nvim-treeclimber").setup({})

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		vim.keymap.set(
			"n",
			"<leader>k",
			"<Plug>(treeclimber-show-control-flow)",
			{ buffer = args.buf, desc = "treeclimber-show-control-flow" }
		)
		vim.keymap.set(
			{ "x", "o" },
			"i.",
			"<Plug>(treeclimber-select-current-node)",
			{ buffer = args.buf, desc = "treeclimber-select-current-node" }
		)
		vim.keymap.set(
			{ "x", "o" },
			"a.",
			"<Plug>(treeclimber-select-expand)",
			{ buffer = args.buf, desc = "treeclimber-select-expand" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-e>",
			"<Plug>(treeclimber-select-forward-end)",
			{ buffer = args.buf, desc = "treeclimber-select-forward-end" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-b>",
			"<Plug>(treeclimber-select-backward)",
			{ buffer = args.buf, desc = "treeclimber-select-backward" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-h>",
			"<Plug>(treeclimber-select-previous)",
			{ buffer = args.buf, desc = "treeclimber-select-previous" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-j>",
			"<Plug>(treeclimber-select-shrink)",
			{ buffer = args.buf, desc = "treeclimber-select-shrink" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-k>",
			"<Plug>(treeclimber-select-parent)",
			{ buffer = args.buf, desc = "treeclimber-select-parent" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-l>",
			"<Plug>(treeclimber-select-next)",
			{ buffer = args.buf, desc = "treeclimber-select-next" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-L>",
			"<Plug>(treeclimber-select-grow-forward)",
			{ buffer = args.buf, desc = "treeclimber-select-grow-forward" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-H>",
			"<Plug>(treeclimber-select-grow-backward)",
			{ buffer = args.buf, desc = "treeclimber-select-grow-backward" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-[>",
			"<Plug>(treeclimber-select-siblings-backward)",
			{ buffer = args.buf, desc = "treeclimber-select-siblings-backward" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-]>",
			"<Plug>(treeclimber-select-siblings-forward)",
			{ buffer = args.buf, desc = "treeclimber-select-siblings-forward" }
		)
		vim.keymap.set(
			{ "n", "x", "o" },
			"<M-g>",
			"<Plug>(treeclimber-select-top-level)",
			{ buffer = args.buf, desc = "treeclimber-select-top-level" }
		)
	end,
})
