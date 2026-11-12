@~/.agents/AGENTS.md

# Memory

Memory (`memory_write`, `scratchpad`) is shared by every project, personal and work alike, so keep it small and durable.

Save:
- Preferences and corrections about how to work with me that apply across projects.
- Non-obvious facts about my environment and tooling (dotfiles layout, Slackware, how tools are installed and pinned).
- Decisions with their reasons, when they will matter in later sessions.

Do not save:
- Secrets, tokens, credentials, keys, or anything read from credential or `.env` files.
- Work-specific details: client, employer or customer names, internal URLs, proprietary code or data.
- Anything the repository already records (code structure, git history, AGENTS.md/CLAUDE.md contents).
- Task progress or details that only matter to the current session; use the conversation for those.

Write to the daily log only when I ask. Before saving, check whether an existing entry covers it and update that instead of adding a duplicate.

# sudo

- `sudo` cannot run while the sandbox is on: commands run with `no new privileges`, so sudo never gets root. If a task needs it, ask me to turn the sandbox off (`/sandbox-disable`), run the command, and ask me to turn it back on (`/sandbox-enable`).

# Clipboard

The clipboard rules in `~/.agents/AGENTS.md` need one adjustment while the sandbox is on, and it is toggled per session (`/sandbox-disable`, `/sandbox-enable`):

- Sandboxed, each command runs in its own PID namespace (`bwrap --unshare-pid --die-with-parent`), so the clipboard tool's forked child dies with the command and the paste is empty. `clipmenud` runs outside the sandbox and takes ownership, but it needs a moment to fetch, so let the copy outlast it: `xclip -selection clipboard -in <file>; sleep 0.5`. `-loops 1` is not enough, since xsel asks for the target list and then the data.
- Unsandboxed there is no namespace to tear down, so a plain invocation is enough; the forked child outlives the command and keeps serving the selection.
- Get this right in one call instead of verifying it: a read in the same command always passes, because the owner is alive at that instant, and the extra call costs money.
- If a check is genuinely needed, do it from a later command (`xclip -selection clipboard -out`, `wl-paste`, `pbpaste`). That is a diagnostic after a reported empty paste, not a routine step.
