local defer = require("defer")
local function setup(refactoring)
	refactoring.setup()
end
defer.on_load("refactoring", setup, "refactoring.nvim")
defer.hook("refactoring", setup, "refactoring.nvim")
defer.cmd("Refactor", "refactoring")
