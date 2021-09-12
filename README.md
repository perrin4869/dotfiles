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

[ale](https://github.com/dense-analysis/ale) is configured to use [eslint\_d](https://www.npmjs.com/package/eslint_d), so you need to install that globally to do javascript/typescript development:

	npm install -g eslint_d

The following language servers are setup in the neovim lsp config, and need to be installed in order to be used:

	npm install -g typescript typescript-language-server \
		vscode-css-languageserver-bin \
		vscode-html-languageserver-bin

In order to build `spot`, [`libhandy1`](https://gitlab.gnome.org/GNOME/libhandy) is necessary. This is not available on Slackware by default but it is available from [Slackers](https://slackware.pkgs.org/current/slackers/).

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

In Slackware:
- `sun-gtk`
