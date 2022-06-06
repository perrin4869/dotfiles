dotfiles
========

# Dependencies

GNU [stow](https://www.gnu.org/software/stow/) is needed to install the dependencies onto your home directory.

Additionally, [npm](https://www.npmjs.com/) is needed to install the [coc](https://github.com/neoclide/coc.nvim) plugins (I may remove this in the future since native neovim lsp works better).

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

In order to build `spot`, [`libadwaita`](https://gitlab.gnome.org/GNOME/libadwaita) is necessary. This is not available on Slackware by default, it must be built from source for now.

Install `luacheck`:

	luarocks install luacheck --local
	luarocks install lanes --local

Other 3rd party dependencies to be installed by the OS dependency manager:
- `i3-gaps`
- `i3-status`
- `ranger`
- `pass`
- `pass-otp`
- `rofi`
- `rofi-pass`
- `pinentry-dmenu`
- `sxhkd`
- `blueman`
- `dunst`
- `xscreensaver`
- `udiskie`
- `redshift-gtk`
- `ibus`
- `fcitx5`
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

In Slackware:
- `sun-gtk`
