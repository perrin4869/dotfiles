# Neotest Local Recipes (.nvim.lua)

This file catalogs various `neotest` configurations for specific project architectures. These recipes are intended to be copied into a `.nvim.lua` file at the project root.

---

## 1. Standard Node.js (Mocha)
**Structure:** All tests located in a root-level `test/` directory.

```lua
-- luacheck: globals vim
vim.g.test_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ':h')
vim.g.test_get_adapters = function(root)
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
end
```

Note: if `vim.g.test_root` is not set, we will default to using either the output of `require('project').get_project_root()` or `vim.fn.getcwd()` as fallbacks.

## 2. Monorepo Services (Mocha + NPM Workspaces)
**Structure:** `services/{service_name}/.../{file}.{spec|integration|e2e}.ts` **Behavior**: Maps `spec` to `unit` and executes the specific workspace script.

```lua
-- luacheck: globals vim
vim.g.test_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ':h')
vim.g.test_get_adapters = function(root)
	return {
		require("neotest-mocha")({
			is_test_file = require("neotest-mocha.util").create_test_file_extensions_matcher(
				{ "spec", "integration", "e2e" },
				{ "ts" }
			),
			command = function(path)
				local relpath = vim.fs.relpath(root, path)
				if not relpath then
					return
				end
				local test_type = relpath:match("%.([^%.]+)%.ts$")
				if not test_type then
					return
				end
				test_type = (test_type == "spec") and "unit" or test_type
				local parts = vim.split(relpath, "/", { trimempty = true })
				return "npm run test:" .. test_type .. " -w @services/" .. parts[2] .. " --"
			end,
			command_args = function(context)
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
end
```

## 3. Neovim Plugin (luarocks + busted + nlua)
**Structure:** `tests/.../{file}_spec.lua`, with locally installed `busted` and `nlua` via `luarocks` **Hint:** run `eval $(./luarocks path --lua-version 5.1 --no-bin) && luarocks test --local` in the root of the project to setup

```lua
-- luacheck: globals vim
vim.g.lazydev_enabled = false
vim.g.lint_enable_luacheck = false

-- Helper to run a command and return trimmed output
local function lr_cmd(arg)
	local cmd = string.format('luarocks path %s --lua-version 5.1', arg)
	return vim.fn.system(cmd):gsub('%s+', '') -- Run and remove whitespace/newlines
end

local rock_path = lr_cmd('--lr-path')
local rock_cpath = lr_cmd('--lr-cpath')

vim.g.test_get_adapters = function()
	return {
		require('neotest-busted')({
			busted_command = 'busted',
			busted_paths = { rock_path },
			busted_cpaths = { rock_cpath },
			no_nvim = true,
		}),
	}
end
```
