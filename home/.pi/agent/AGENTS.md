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

The clipboard rules in `~/.agents/AGENTS.md` need one adjustment here, because commands run sandboxed:

- The clipboard is an ownership protocol, not a buffer: the tool has to stay alive to serve the text. pi runs each command in its own PID namespace whose init dies with it, taking the whole tree down, so start the tool as a background job. `setsid` and `nohup` don't help; they detach the process, not the namespace.
- Verify from a later command (`xclip -selection clipboard -out`), never the same one: a read in the same command passes even when the copy is already gone.
