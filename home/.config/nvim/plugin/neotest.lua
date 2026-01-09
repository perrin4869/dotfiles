local defer = require("defer")

defer.pack("neotest")
defer.very_lazy("neotest")
defer.on_load("neotest", function()
	require("neotest").setup({})
end)

defer.pack("neotest-mocha")
defer.deps("neotest-mocha", "neotest")

-- leave
local with_neotest = defer.with("neotest")

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = "neotest." .. desc, silent = true, noremap = true })
end

map(
	"<leader>ii",
	with_neotest(function(neotest)
		neotest.run.run()
	end),
	"run"
)

map(
	"<leader>if", -- entire file
	with_neotest(function(neotest)
		neotest.run.run(vim.fn.expand("%"))
	end),
	"run_file"
)

map(
	"<leader>id",
	with_neotest(function(neotest)
		neotest.run.run({ strategy = "dap" })
	end),
	"run_dap"
)

map(
	"<leader>is",
	with_neotest(function(neotest)
		neotest.run.stop()
	end),
	"stop"
)

map(
	"<leader>ia",
	with_neotest(function(neotest)
		neotest.run.attach()
	end),
	"attach"
)

map(
	"<leader>ts",
	with_neotest(function(neotest)
		neotest.summary.toggle()
	end),
	"attach"
)
