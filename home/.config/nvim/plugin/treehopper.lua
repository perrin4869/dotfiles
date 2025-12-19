vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		-- duplicate functionality with flash.treesitter
		vim.keymap.set("o", "m", require("tsht").nodes, { silent = true, buffer = args.buf, desc = "treehopper.nodes" })

		vim.keymap.set(
			"x",
			"m",
			-- ":<C-u>lua require('tsht').nodes()<CR>",
			function()
				vim.cmd.normal({ "!gv" })
				require("tsht").nodes()
			end,
			{ silent = true, noremap = true, buffer = args.buf, desc = "treehopper.nodes" }
		)
	end,
})

-- omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
-- xnoremap <silent> m :lua require('tsht').nodes()<CR>
