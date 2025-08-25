-- vim: ft=lua tw=80

exclude_files = { "home/.local/share/", "home/.vim/undo", "home/.vim/pack" }

-- Rerun tests only if their modification time changed.
cache = true

-- Global objects defined by the C code
read_globals = {
	"vim",
}

globals = {
	"vim.g",
	"vim.b",
	"vim.w",
	"vim.o",
	"vim.bo",
	"vim.wo",
	"vim.go",
	"vim.env",
	"vim.opt",
	"vim.opt_local",
}
