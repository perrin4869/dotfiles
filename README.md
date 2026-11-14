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
- `neomutt` (built with notmuch; on Slackware `USENOTMUCH=yes`)
- `isync`
- `msmtp` (Gmail needs `oauthbearer` among the methods `msmtp --version` lists)
- `notmuch`
- `cyrus-sasl-xoauth2` (lets mbsync log in to Gmail with OAuth2)
- `lynx` (renders HTML mail in neomutt)

### Slackware-specific

On Slackware systems, the following additional dependency is optional:

- `sun`

## Installation

To build all required components and install the configuration files into the home directory, run the following commands:

```sh
make
make install
```

## Development

Install [`pre-commit`](https://pre-commit.com/) (`pipx install pre-commit`), then set up the git hook once per clone:

```sh
make prepare
```

It runs `luacheck` and `stylua --check` on staged Lua files, the same checks as the `lint` job in CI.

## Mail

`mbsync` mirrors every account into `~/.local/share/mail/<account>` every five minutes from cron (`mail-sync`), `notmuch` indexes it, `neomutt` reads it, and `msmtp` sends. The account configs hold addresses, so they stay out of the repo; the templates below go in `~/.config`.

### Credentials

All mail secrets are encrypted to a dedicated GPG key, whose passphrase is kept in the main (YubiKey) pass store. `mail-credential <command>` unlocks that key in gpg-agent and then runs the command, so the first sync after boot or login asks for one YubiKey touch, with a notification saying what for, and every later sync or send needs none. A passphrase preset into gpg-agent lasts until the agent restarts or `max-cache-ttl` runs out (ten days here). `gpg-agent.conf` already allows presetting.

1. Create the key, with a passphrase, and keep that passphrase in pass:
   ```sh
   gpg --quick-gen-key 'Mail credentials <mail-credentials@localhost>' default default never
   pass insert gpg/mail-credentials
   ```
2. Create the mail credentials store, encrypted to that key:
   ```sh
   PASSWORD_STORE_DIR=~/.local/share/mail-credentials pass init mail-credentials@localhost
   ```
3. For each password-based IMAP account, store the password on a single line:
   ```sh
   mail-credential pass insert imap/example.com
   ```

### Gmail

[`oama`](https://github.com/pdobsan/oama) (installed by `make`) keeps the OAuth2 tokens, GPG-encrypted to the same key, and renews the hourly access token on its own.

1. In Google Cloud, create a project (the calendar one works), set the OAuth consent screen to External, add yourself as a test user, and publish it **In production**: a Testing app's refresh token expires after seven days.
2. Create a Desktop OAuth client and store it:
   ```sh
   mail-credential pass insert -m google-oauth-client   # client_id=... and client_secret=... lines
   ```
3. Authorize, which opens the browser:
   ```sh
   mail-credential oama authorize google you@gmail.com
   ```

### Templates

`~/.config/isyncrc`:

```
IMAPAccount gmail
Host imap.gmail.com
User you@gmail.com
AuthMechs XOAUTH2
PassCmd "mail-credential oama access you@gmail.com"
TLSType IMAPS

IMAPStore gmail-remote
Account gmail

MaildirStore gmail-local
Path ~/.local/share/mail/gmail/
Inbox ~/.local/share/mail/gmail/INBOX
SubFolders Verbatim

# All Mail keeps archived mail locally; labelled mail is stored once per label and notmuch merges the copies
Channel gmail
Far :gmail-remote:
Near :gmail-local:
Patterns * ![Gmail]/Important ![Gmail]/Starred
Create Both
Expunge Both
SyncState *

IMAPAccount example
Host imap.example.com
User you@example.com
PassCmd "mail-credential pass show imap/example.com"
TLSType IMAPS

IMAPStore example-remote
Account example

MaildirStore example-local
Path ~/.local/share/mail/example/
Inbox ~/.local/share/mail/example/INBOX
SubFolders Verbatim

Channel example
Far :example-remote:
Near :example-local:
Patterns *
Create Both
Expunge Both
SyncState *
```

`~/.config/msmtp/config`:

```
defaults
auth on
tls on
port 587
logfile ~/.local/state/msmtp.log

account gmail
host smtp.gmail.com
from you@gmail.com
user you@gmail.com
auth oauthbearer
passwordeval mail-credential oama access you@gmail.com

account example
host smtp.example.com
from you@example.com
user you@example.com
passwordeval mail-credential pass show imap/example.com

account default : gmail
```

`~/.config/notmuch/default/config` (`mail-sync` indexes only once this exists):

```
[database]
path=/home/you/.local/share/mail

[user]
name=Your Name
primary_email=you@gmail.com
other_email=you@example.com

[new]
tags=unread;inbox;
ignore=.mbsyncstate;.mbsyncstate.journal;.mbsyncstate.new;.uidvalidity

[maildir]
synchronize_flags=true
```

`~/.config/neomutt/accounts/1-gmail.muttrc`, and one such file per account (the first one sorted sets the start-up mailbox):

```
set spool_file = "+gmail/INBOX"
named-mailboxes "Gmail" "+gmail/INBOX" "Gmail sent" "+gmail/[Gmail]/Sent Mail"
# Gmail files sent mail itself, so no record
folder-hook gmail/ 'set from = "you@gmail.com" record = "" postponed = "+gmail/[Gmail]/Drafts" trash = "+gmail/[Gmail]/Trash"'
```

Once `~/.config/isyncrc` exists, run `mail-sync` once by hand for the first full download; cron takes over from there.

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

### Backlight control (acpilight)

[`acpilight`](https://gitlab.com/wavexx/acpilight) provides a backward-compatible `xbacklight` replacement that controls brightness via `/sys/class/backlight` instead of X11's RandR `Backlight` property, so it works for laptop panels the RandR property was never wired up for, and it's driven by a redshift hook ([`home/.config/redshift/hooks/backlight`](home/.config/redshift/hooks/backlight)) that dims the display along with the day/night cycle.

Controlling an external/desktop monitor's brightness this way additionally requires the **`ddcci-driver-linux`** kernel module, which exposes DDC/CI-controlled monitors under `/sys/class/backlight/ddcci*` (the same interface as a native panel), so the same hook script works unmodified on both a laptop (native panel) and a desktop (DDC/CI monitor):

- **Arch Linux**: AUR package `ddcci-driver-linux-dkms` (or `-git` for newer kernels)
- **Slackware**: [`ddcci-driver-linux`](https://slackbuilds.org/repository/15.0/system/ddcci-driver-linux/) on SlackBuilds.org

System settings required:

- **Registering each monitor's DDC/CI device**, since `ddcci-driver-linux` doesn't autodetect monitors on its own -- it needs the main device (address `0x37`) added manually per i2c bus. Add the following snippet to your system's startup (adjust the `card0-*` glob to match which GPU your monitors are on):
  ```sh
  /sbin/modprobe ddcci-backlight

  # DisplayPort connectors expose the real DDC/CI-capable channel as a direct
  # i2c-N subdirectory of the connector itself (the AUX-channel-backed
  # adapter); their `ddc` symlink instead points to a separate, more limited
  # legacy adapter that can't complete the full DDC/CI handshake. HDMI
  # connectors have no such split -- their `ddc` symlink is the only (and
  # correct) adapter.
  (
    for conn in /sys/class/drm/card0-*/; do
      [ "$(cat "$conn/status" 2>/dev/null)" = "connected" ] || continue
      direct=$(ls -d "$conn"i2c-* 2>/dev/null | head -1)
      if [ -n "$direct" ]; then
        # DP
        ddc_bus=$(basename "$direct")
      else
        # HDMI
        ddc_link="$conn/ddc"
        [ -e "$ddc_link" ] || continue
        ddc_bus=$(basename "$(readlink -f "$ddc_link")")
      fi
      bus_num=${ddc_bus#i2c-}
      [ -e "/sys/bus/ddcci/devices/ddcci$bus_num" ] && continue
      echo ddcci 0x37 > "/sys/bus/i2c/devices/$ddc_bus/new_device" 2>/dev/null
    done
  ) & # writing to new_device is a synchronous sysfs call that blocks until the driver's real I2C handshake with that monitor finishes, and it's slow
  ```
- **Installing acpilight's udev rule** so `xbacklight` can write to `/sys/class/backlight` without root:
  ```sh
  sudo install -vCDt /etc/udev/rules.d deps/acpilight/90-backlight.rules
  sudo udevadm trigger -s backlight -c add
  ```
  (also requires your user to be in the `video` group)
