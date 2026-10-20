# Global instructions

- When producing a chunk of multiline text whose purpose is for the user to paste it somewhere else (submission/PR notes, a message, a commit description draft, etc.), automatically copy it to the system clipboard as part of delivering it — don't wait to be asked. Still show the text in the response as normal; the clipboard copy is in addition, not instead.
  - Detect the available clipboard tool: `xclip`/`xsel` on X11 (`$DISPLAY` set), `wl-copy` on Wayland (`$WAYLAND_DISPLAY` set), `pbcopy` on macOS.
  - Prefer writing the text to a file first, then piping/loading that file into the clipboard tool (e.g. `xclip -selection clipboard -in <file>`), rather than inlining multiline text into a shell `echo`/heredoc, to avoid quoting issues.
  - If no clipboard tool or display session is available, skip silently (or note it) rather than erroring out.

- When asking the user to run a command themselves (e.g. it needs `sudo`, physical interaction like a FIDO touch, or otherwise can't be run directly), copy that command to the system clipboard the same way, in addition to showing it in the response — unless the user has said otherwise for that session. This applies even to single-line commands, not just multiline text.

- Plain `sudo ...` works in Claude Code's shell (no `-A` needed): there is no terminal, so sudo falls back to the GUI helper in `SUDO_ASKPASS` (set in `~/.claude/settings.json`) for the PIN and key touch. Do not use `sudo -n`, it never prompts and always fails.
