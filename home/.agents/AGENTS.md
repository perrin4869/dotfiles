# Global instructions

Only what every agent needs belongs here.

## GitHub

- Before posting to a repository outside my GitHub account (an issue, PR, comment or review), show me the exact title and body and wait for my approval. Approval covers that one post only.
- Repositories owned by the account `gh` is authenticated as are mine: open issues and PRs and comment there without asking. Resolve that account with `gh api user --jq .login`; if it cannot be resolved, ask.

## Clipboard

- When producing a chunk of multiline text whose purpose is for the user to paste it somewhere else (submission/PR notes, a message, a commit description draft, etc.), automatically copy it to the system clipboard as part of delivering it — don't wait to be asked. Still show the text in the response as normal; the clipboard copy is in addition, not instead.
  - Detect the available clipboard tool: `xclip`/`xsel` on X11 (`$DISPLAY` set), `wl-copy` on Wayland (`$WAYLAND_DISPLAY` set), `pbcopy` on macOS.
  - Prefer writing the text to a file first, then piping/loading that file into the clipboard tool (e.g. `xclip -selection clipboard -in <file>`), rather than inlining multiline text into a shell `echo`/heredoc, to avoid quoting issues.
  - If no clipboard tool or display session is available, skip silently (or note it) rather than erroring out.

- When asking the user to run a command themselves (e.g. it needs `sudo`, physical interaction like a FIDO touch, or otherwise can't be run directly), copy that command to the system clipboard the same way, in addition to showing it in the response — unless the user has said otherwise for that session. This applies even to single-line commands, not just multiline text.

## sudo

- sudo has no terminal to prompt on. Run `sudo -A <command>`: `-A` makes it ask the helper in `$SUDO_ASKPASS`, so expect a key touch per command. Never `sudo -n`, which cannot prompt and always fails.
