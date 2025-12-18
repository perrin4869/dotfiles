require("gitsigns").setup({
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

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
		end, { expr = true, desc = "gitsigns.next_hunk" })

		map("n", "[c", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(function()
				nngs.prev_hunk()
			end)
			return "<Ignore>"
		end, { expr = true, desc = "gitsigns.prev_hunk" })

		-- Actions
		map("n", "<leader>hs", gs.stage_hunk, { desc = "gitsigns.stage_hunk" })
		map("n", "<leader>hr", gs.reset_hunk, { desc = "gitsigns.reset_hunk" })
		map("v", "<leader>hs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "gitsigns.stage_hunk" })
		map("v", "<leader>hr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "gitsigns.reset_hunk" })
		map("n", "<leader>hS", gs.stage_buffer, { desc = "gitsigns.stage_buffer" })
		map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "gitsigns.undo_stage_hunk" })
		map("n", "<leader>hR", gs.reset_buffer, { desc = "gitsigns.reset_buffer" })
		map("n", "<leader>hp", gs.preview_hunk, { desc = "gitsigns.preview_hunk" })
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, { desc = "gitsigns.blame_line" })
		-- official is <leader>tb, conflicts with <leader>t from FloatTerm
		map("n", "<leader>htb", gs.toggle_current_line_blame, { desc = "gitsigns.toggle_current_line_blame" })
		map("n", "<leader>hd", gs.diffthis, { desc = "gitsigns.diffthis" })
		map("n", "<leader>hD", function()
			gs.diffthis("~")
		end, { desc = "gitsigns.diffthis_~" })
		-- official is <leader>td, conflicts with <leader>t from FloatTerm
		map("n", "<leader>htd", gs.toggle_deleted, { desc = "gitsigns.toggle_deleted" })

		-- Text object
		map({ "o", "x" }, "ih", gs.select_hunk, { desc = "gitsigns.select_hunk" })
	end,
})
