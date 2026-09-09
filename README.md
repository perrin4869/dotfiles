# Dotfiles

## Dependencies

Several components included in this repository require local build toolchains to be available on the system. The primary build-time dependencies are:

- `make`
- [`stow`](https://www.gnu.org/software/stow/) — used to install configuration files into the home directory via symbolic links
- `clang` (required for `ccls`)
- `gcc` (required for `mpv-mpris`, `fzy`)
- `rust` (required for `atuin`, `difftastic_nvim`)
- `nodejs` (required for `eslint_d`, `vim-jsdoc` and multiple tools installed via `mason`)
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
- `gh` (used for git credential authentication over HTTPS)
- `joystickwake` (optionally requires `python-dbus-fast` and `python-xlib` when running under X11)
- `helvum`
- `logrotate`
- `cron`

### Slackware-specific

On Slackware systems, the following additional dependency is optional:

- `sun`

### Backlight control (acpilight)

[`acpilight`](https://gitlab.com/wavexx/acpilight) (`deps/acpilight`, built like `xwinwrap`) provides a backward-compatible `xbacklight` replacement that controls brightness via `/sys/class/backlight` instead of X11's RandR `Backlight` property, so it works for laptop panels the RandR property was never wired up for, and it's driven by a redshift hook ([`home/.config/redshift/hooks/backlight`](home/.config/redshift/hooks/backlight)) that dims the display along with the day/night cycle.

Controlling an external/desktop monitor's brightness this way additionally requires the **`ddcci-driver-linux`** kernel module, which exposes DDC/CI-controlled monitors under `/sys/class/backlight/ddcci*` (the same interface as a native panel), so the same hook script works unmodified on both a laptop (native panel) and a desktop (DDC/CI monitor):

- **Arch Linux**: AUR package `ddcci-driver-linux-dkms` (or `-git` for newer kernels)
- **Slackware**: [`ddcci-driver-linux`](https://slackbuilds.org/repository/15.0/system/ddcci-driver-linux/) on SlackBuilds.org

Two things the build here deliberately does *not* automate, since they require root and are one-time system setup rather than per-user dotfiles (udev rules in particular are inherently system-wide -- there's no per-user rules directory or per-user udev daemon, so this can't be moved into the unprivileged `home`/stow flow no matter what):

- **Registering each monitor's DDC/CI device**, since `ddcci-driver-linux` doesn't autodetect monitors on its own -- it needs the main device (address `0x37`) added manually per i2c bus. Add to `/etc/rc.d/rc.local` (bus resolved dynamically per DRM connector, since i2c adapter numbers aren't guaranteed stable across reboots/driver updates; adjust the `card0-*` glob to match which GPU your monitors are on):
  ```sh
  /sbin/modprobe ddcci-backlight

  for conn in /sys/class/drm/card0-*/; do
    [ "$(cat "$conn/status" 2>/dev/null)" = "connected" ] || continue
    ddc_link="$conn/ddc"
    [ -e "$ddc_link" ] || continue
    ddc_bus=$(basename "$(readlink -f "$ddc_link")")
    bus_num=${ddc_bus#i2c-}
    [ -e "/sys/bus/ddcci/devices/ddcci$bus_num" ] && continue
    echo ddcci 0x37 > "/sys/bus/i2c/devices/$ddc_bus/new_device" 2>/dev/null
  done
  ```
- **Installing acpilight's udev rule** so `xbacklight` can write to `/sys/class/backlight` without root:
  ```sh
  sudo install -vCDt /etc/udev/rules.d deps/acpilight/90-backlight.rules
  sudo udevadm trigger -s backlight -c add
  ```
  (also requires your user to be in the `video` group)

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

### uBlock Origin Filters

Custom uBlock Origin filters ("My filters") are declared in [`home/.mozilla/native-messaging-hosts/uBlock0@raymondhill.net.json`](home/.mozilla/native-messaging-hosts/uBlock0@raymondhill.net.json), which `stow` links to `~/.mozilla/native-messaging-hosts/uBlock0@raymondhill.net.json`. This is Firefox's [managed storage](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/storage/managed) native-manifest mechanism (requires uBlock Origin 1.33.0+): on startup, uBlock reads this file and applies `data.toOverwrite.filters` to its own "My filters" pane, so no manual dashboard/import step is required in either browser profile. Because `Vendor=Mozilla` in Zen's `application.ini`, Zen shares the same `~/.mozilla/native-messaging-hosts` directory as regular Firefox, so this applies to any Mozilla-vendor profile with uBlock Origin installed.

Notes:
- A full browser restart is required to pick up changes to this file.
- `toOverwrite` fully replaces the "My filters" pane content on every launch, so any filters added manually through the uBlock UI will be reverted on restart — treat this file as the source of truth and edit it instead.
