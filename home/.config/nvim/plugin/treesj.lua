local defer = require("defer")

defer.on_load("treesj", function(tsj)
	tsj.setup({
		use_default_keymaps = false,
	})
end) -- "treesj")

local with_tsj = defer.with("treesj")

local toggle = with_tsj(function(t)
	t.toggle()
end)
local join = with_tsj(function(t)
	t.join()
end)
local split = with_tsj(function(t)
	t.split()
end)

vim.api.nvim_create_autocmd("FileType", {
	pattern = require("nvim-treesitter").get_installed(),
	callback = function(args)
		local opts = { buffer = args.buf, silent = true }

		vim.keymap.set("n", "<leader>mm", toggle, vim.tbl_extend("force", opts, { desc = "treesj.toggle" }))
		vim.keymap.set("n", "<leader>mj", join, vim.tbl_extend("force", opts, { desc = "treesj.join" }))
		vim.keymap.set("n", "<leader>ms", split, vim.tbl_extend("force", opts, { desc = "treesj.split" }))
	end,
})
