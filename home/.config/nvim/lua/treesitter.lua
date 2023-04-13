local treesitter_install = require("nvim-treesitter.install")

local M = {}

local langs = {
  "typescript",
  "scala",
  "javascript",
  "bash",
  "c",
  "cpp",
  "css",
  "graphql",
  "haskell",
  "lua",
  "latex",
  "json",
  "jsonc",
  "regex",
  "svelte",
  "html",
  "yaml",
  "kotlin",
}

M.langs = langs
M.ensure_installed = function()
  treesitter_install.ensure_installed_sync(langs)
  treesitter_install.update({ with_sync = true })(langs)
end
M.print_langs = function() print(table.concat(langs, ' ') .. "\n") end

return M
