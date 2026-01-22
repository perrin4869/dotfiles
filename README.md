# Dotfiles

## Dependencies

Several components included in this repository require local build toolchains to be available on the system. The primary build-time dependencies are:

- `make`
- [`stow`](https://www.gnu.org/software/stow/) — used to install configuration files into the home directory via symbolic links
- `clang` (required for `ccls`)
- `gcc` (required for `mpv-mpris`, `fzy`)
- `rust` (required for `atuin`, `difftastic_nvim`)
- `nodejs` (required for `eslint_d` and multiple tools installed via `mason`)
- `luarocks` (required for multiple tools installed via `mason`)
- `yq` (used internally by `mason`)

In addition, the following third-party system dependencies are assumed to be present and are configured by default as either desktop applications or TUI applications:

- `xrandr`
- `xrdb`
- `i3`
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
- `wezterm`
- `ghostty`
- `urxvt`
- `ripgrep`
- `bat`
- `fd`
- `spot`
- `zen`
- `difftastic`
- `joystickwake` (optionally requires `python-dbus-fast` and `python-xlib` when running under X11)
- `helvum`

### Slackware-specific

On Slackware systems, the following additional dependency is optional:

- `sun`

## Installation

To build all required components and install the configuration files into the home directory, run the following commands:

```sh
make
make install
```

## Zen Browser Configuration

The following preferences are used by the Zen browser and are expected to be defined in:

```
~/.zen/{profile_dir}/prefs.js
```

```js
user_pref("browser.tabs.insertAfterCurrent", true);
user_pref("zen.theme.content-element-separation", 0);
user_pref("zen.view.experimental-force-window-controls-left", true);
```
