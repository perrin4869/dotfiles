dotfiles
========

# Dependencies

GNU [stow](https://www.gnu.org/software/stow/) is needed to install the dependencies onto your home directory.

To install:

```
make
make install
```

The following language servers are setup in the neovim lsp config, and need to be installed in order to be used:

	npm install --location=global typescript typescript-language-server \
		vscode-css-languageserver-bin \
		vscode-html-languageserver-bin \
		vscode-langservers-extracted \
		vim-language-server \
		sql-language-server

Install `luacheck`:

	luarocks install luacheck --local
	luarocks install lanes --local

Other 3rd party dependencies to be installed by the OS dependency manager:
- `i3-gaps`
- `i3status`
- `i3lock`
- `ranger`
- `pass`
- `pass-otp`
- `rofi`
- `rofi-pass`
- `sxhkd`
- `blueman`
- `dunst`
- `xscreensaver`
- `udiskie`
- `redshift-gtk`
- `ibus`
- `fcitx5`
- `fcitx5-mozc`
- `picom`
- `maim`
- `playerctl`
- `noto-emoji`
- `zathura`
- `alacritty`
- `kitty`
- `urxvt`
- `ripgrep`
- `bat`
- `fd`
- `luarocks`
- `spot`

In Slackware:
- `sun`
