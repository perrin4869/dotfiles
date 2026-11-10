-- vim: ft=lua tw=80

max_comment_line_length = 180

-- lua-types declares globals for the type checker; it is never run
exclude_files = { 'home/.local/share/', 'home/.vim/undo', 'home/.vim/pack', 'home/.config/nvim/lua-types' }

-- busted provides these to specs, which run under nlua
files['home/.config/nvim/spec/'] = {
	std = '+busted',
}

-- Rerun tests only if their modification time changed.
cache = true

-- Global objects defined by the C code
read_globals = {
	'vim',
}

globals = {
	'vim.g',
	'vim.b',
	'vim.w',
	'vim.o',
	'vim.bo',
	'vim.wo',
	'vim.go',
	'vim.env',
	'vim.opt',
	'vim.opt_local',
}
