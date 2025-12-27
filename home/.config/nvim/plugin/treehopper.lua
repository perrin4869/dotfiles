local defer = require("defer")
defer.on_load("tsht", "nvim-treehopper")
defer.on_event(function()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = require("nvim-treesitter").get_installed(),
		callback = function(args)
			-- duplicate functionality with flash.treesitter
			vim.keymap.set("o", "m", function()
				defer.ensure("tsht").nodes()
			end, { silent = true, buffer = args.buf, desc = "treehopper.nodes" })

			vim.keymap.set(
				"x",
				"m",
				-- ":<C-u>lua require('tsht').nodes()<CR>",
				function()
					vim.cmd.normal({ "!gv" })
					defer.ensure("tsht").nodes()
				end,
				{ silent = true, noremap = true, buffer = args.buf, desc = "treehopper.nodes" }
			)
		end,
	})
end, "BufEnter", { name = "treesitter-treehopper" })

-- omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
-- xnoremap <silent> m :lua require('tsht').nodes()<CR>
