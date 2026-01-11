# Neotest Local Recipes (.nvim.lua)

This file catalogs various `neotest` configurations for specific project architectures. These recipes are intended to be copied into a `.nvim.lua` file at the project root.

---

## 1. Standard Node.js (Mocha)
**Structure:** All tests located in a root-level `test/` directory.

```lua
-- luacheck: globals vim
require("test").setup(debug.getinfo(1, "S"), function(root)
	return {
		require("neotest-mocha")({
			is_test_file = function(path)
				local relpath = vim.fs.relpath(root, path)

				if type(relpath) ~= "string" then
					return false
				end

				return vim.startswith(relpath, "test/")
			end,
			command = "npm test --",
			command_args = function(context)
				-- The context contains:
				--   results_path: The file that json results are written to
				--   test_name: The exact name of the test; is empty for `file` and `dir` position tests.
				--   test_name_pattern: The generated pattern for the test
				--   path: The path to the test file
				--
				-- It should return a string array of arguments
				--
				-- Not specifying 'command_args' will use the defaults below
				local relpath = vim.fs.relpath(root, context.path)
				return {
					"--full-trace",
					"--reporter=json",
					"--reporter-options=output=" .. context.results_path,
					"--grep=" .. context.test_name_pattern,
					relpath or context.path,
				}
			end,
			env = { CI = true },
			cwd = function()
				return root
			end,
		}),
	}
end)
```
