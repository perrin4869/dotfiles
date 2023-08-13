local tc = require("nvim-treeclimber")

-- Keymaps
vim.keymap.set("n", "<leader>k", tc.show_control_flow, {})
vim.keymap.set({ "x", "o" }, "i.", tc.select_current_node, { desc = "select current node" })
vim.keymap.set({ "x", "o" }, "a.", tc.select_expand, { desc = "select parent node" })
vim.keymap.set(
	{ "n", "x", "o" },
	"<M-e>",
	tc.select_forward_end,
	{ desc = "select and move to the end of the node, or the end of the next node" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"<M-b>",
	tc.select_backward,
	{ desc = "select and move to the begining of the node, or the beginning of the next node" }
)

vim.keymap.set({ "n", "x", "o" }, "<M-[>", tc.select_siblings_backward, {})
vim.keymap.set({ "n", "x", "o" }, "<M-]>", tc.select_siblings_forward, {})
vim.keymap.set(
	{ "n", "x", "o" },
	"<M-g>",
	tc.select_top_level,
	{ desc = "select the top level node from the current position" }
)
vim.keymap.set({ "n", "x", "o" }, "<M-h>", tc.select_backward, { desc = "select previous node" })
vim.keymap.set({ "n", "x", "o" }, "<M-j>", tc.select_shrink, { desc = "select child node" })
vim.keymap.set({ "n", "x", "o" }, "<M-k>", tc.select_expand, { desc = "select parent node" })
vim.keymap.set({ "n", "x", "o" }, "<M-l>", tc.select_forward, { desc = "select the next node" })
vim.keymap.set({ "n", "x", "o" }, "<M-L>", tc.select_grow_forward, { desc = "Add the next node to the selection" })
vim.keymap.set({ "n", "x", "o" }, "<M-H>", tc.select_grow_backward, { desc = "Add the next node to the selection" })
