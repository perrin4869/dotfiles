dotfiles
========

# Dependencies

GNU [stow](https://www.gnu.org/software/stow/) is needed to install the dependencies onto your home directory.

To install:

```
make
make install
```

Other 3rd party dependencies to be installed by the OS dependency manager:
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
- `luarocks`
- `ripgrep`
- `bat`
- `fd`
- `yq`
- `spot`
- `zen`
- `difftastic`
- `joystickwake` (with optional `python-dbus-fast` and `python-xlib` on `X11`)
- `helvum`

In Slackware:
- `sun`

# zen

Here are two configs used in the zen browser, found in `~/.zen/{profile_dir}>/prefs.js`:

```
user_pref("browser.tabs.insertAfterCurrent", true)
user_pref("zen.theme.content-element-separation", 0);
user_pref("zen.view.experimental-force-window-controls-left", true);
```
