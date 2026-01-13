local defer = require("defer")

defer.pack("neotest")
defer.on_bufreadpre("neotest", { nested = true })
defer.on_load("neotest", function()
	require("neotest").setup({})
end)

defer.pack("neotest-mocha")
defer.deps("neotest", { "neotest-mocha" })

---@type Defer.With<neotest>
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

map(
	"<leader>to",
	with_neotest(function(neotest)
		neotest.output_panel.toggle()
	end),
	"attach"
)

local restore = require("restore")
restore.add_quitpre_ft("neotest-summary")
restore.add_buf_match("Neotest Summary", function()
	defer.on_postload("neotest", function()
		require("neotest").summary.toggle()
	end)
end)
restore.add_quitpre_ft("neotest-output-panel")
restore.add_buf_match("Neotest Output Panel", function()
	defer.on_postload("neotest", function()
		require("neotest").output_panel.toggle()
	end)
end)
