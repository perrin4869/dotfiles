-- Only what the test tooling needs: the config runs straight out of home/.config/nvim, and `luarocks test` with
-- `luarocks init --local` keeps busted and nlua in ./.luarocks instead of installing them system-wide.
rockspec_format = '3.0'
package = 'dotfiles'
version = 'scm-1'
description = {
	summary = 'Personal dotfiles',
	homepage = 'https://github.com/perrin4869/dotfiles',
	license = 'MIT',
}
dependencies = {
	'lua ~> 5.1',
}
test_dependencies = {
	'busted',
	'nlua',
}
source = {
	url = 'git://github.com/perrin4869/dotfiles',
}
build = {
	type = 'builtin',
}
