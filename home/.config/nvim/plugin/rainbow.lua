local defer = require("defer")
defer.on_event(function()
	vim.cmd.packadd("rainbow-delimiters.nvim")
end, "BufEnter", { name = "rainbow-delimiters" })

vim.g.rainbow_delimiters = {
	strategy = {
		[""] = "rainbow-delimiters.strategy.global",
		vim = "rainbow-delimiters.strategy.local",
	},
	query = {
		[""] = "rainbow-delimiters",
		lua = "rainbow-blocks",
	},
	priority = {
		[""] = 110,
		lua = 210,
	},
	highlight = {
		"RainbowDelimiterRed",
		"RainbowDelimiterYellow",
		"RainbowDelimiterBlue",
		"RainbowDelimiterOrange",
		"RainbowDelimiterGreen",
		"RainbowDelimiterViolet",
		"RainbowDelimiterCyan",
	},
}
