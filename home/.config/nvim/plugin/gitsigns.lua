local defer = require("defer")

defer.on_load("gitsigns", function()
	require("gitsigns").setup({
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns

			local map = require("map").create({
				desc = "gitsigns",
				buffer = bufnr,
			})

			local next_integrations = require("nvim-next.integrations")
			local nngs = next_integrations.gitsigns(gs)

			-- Navigation
			map("n", "]c", function()
				if vim.wo.diff then
					return "]c"
				end
				vim.schedule(function()
					-- gs.next_hunk()
					nngs.next_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "next_hunk" })

			map("n", "[c", function()
				if vim.wo.diff then
					return "[c"
				end
				vim.schedule(function()
					nngs.prev_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "prev_hunk" })

			-- Actions
			map("n", "<leader>hs", gs.stage_hunk, "stage_hunk")
			map("n", "<leader>hr", gs.reset_hunk, "reset_hunk")

			map("v", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "stage_hunk")

			map("v", "<leader>hr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "reset_hunk")

			map("n", "<leader>hS", gs.stage_buffer, "stage_buffer")
			map("n", "<leader>hR", gs.reset_buffer, "reset_buffer")
			map("n", "<leader>hp", gs.preview_hunk, "preview_hunk")
			map("n", "<leader>hi", gs.preview_hunk_inline, "preview_hunk_inline")

			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, "blame_line")

			map("n", "<leader>hd", gs.diffthis, "diffthis")

			map("n", "<leader>hD", function()
				gs.diffthis("~")
			end, "diffthis_~")

			map("n", "<leader>hQ", function()
				gs.setqflist("all")
			end, "setqflist_all")
			map("n", "<leader>hq", gs.setqflist, "setqflist")

			map("n", "<leader>tb", gs.toggle_current_line_blame, "toggle_current_line_blame")
			map("n", "<leader>tw", gs.toggle_word_diff, "toggle_word_diff")

			-- Text object
			map({ "o", "x" }, "ih", gs.select_hunk, "select_hunk")
		end,
	})
end)
defer.pack("gitsigns", "gitsigns.nvim")
defer.on_bufreadpost("gitsigns")
