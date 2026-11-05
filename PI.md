# PI.md

The pi config lives in `home/.pi/agent` and is stowed to `~/.pi/agent`. This file lists the switches this repo adds or configures, and where to flip each one: a command, an environment variable, or a project's `.pi/settings.json`.

Project settings go in `.pi/settings.json` at the project root. That file is ignored globally, so it stays local to each checkout. Project values take precedence over the global `~/.pi/agent/settings.json`, field by field, and apply only once pi trusts the project. A section with an invalid value is ignored, with a warning, and its defaults apply.

---

## Model

pi defaults to local Ollama (`gemma4:12b`). Claude through `pi-claude-bridge` is opt-in, per project or per session.

Per project, in `.pi/settings.json`:

```json
{
  "defaultProvider": "claude-bridge",
  "defaultModel": "claude-sonnet-5-5"
}
```

Per session: `/model`, or `Alt+P` / `Alt+Shift+P` to cycle.

---

## opusplan

Plans on one model and implements on another, like Claude Code's `opusplan`. It follows `/plan` (pi-plan-mode), including the fresh implementation session.

Off by default. Enable per project:

```json
{
  "opusplan": {
    "enabled": true,
    "plan": "claude-bridge/claude-opus-5-5",
    "execute": "claude-bridge/claude-sonnet-5-5"
  }
}
```

* `plan` and `execute` are optional, as `provider/model`. The defaults are shown above.
* Each field can also be set globally. A project value overrides only that field.

`/opusplan` toggles it for the running pi process, overriding the settings until pi exits.

---

## Advisor

`rpiv-advisor` has one global reviewer model, so a project on Ollama would send its conversation to that reviewer too. The `advisor` tool is hidden from the model unless a project enables it:

```json
{
  "advisor": { "enabled": true }
}
```

A global `"enabled": true` applies to projects that don't set it, and a project can set `false` to opt out again.

The reviewer model itself is global: `/advisor` picks it for every project (`~/.config/rpiv-advisor/advisor.json`).

---

## Memory exit summary

pi-memory can summarise the session on exit, at the cost of one more model call. It runs only while the session model is from `ollama` or `claude-bridge`, and switches with `/model`.

Force it on or off for a run:

```sh
PI_MEMORY_EXIT_SUMMARY=1 pi
PI_MEMORY_EXIT_SUMMARY=0 pi
```

When the variable is set, the model-based switching is skipped.

What memory may store is in `home/.pi/agent/AGENTS.md`. Memory is shared by every project.

---

## Compaction

`pi-vcc` takes over `/compact` and automatic compaction, without a model call. It is skipped on `claude-bridge`, where Claude's own summary is better and costs nothing extra (`skipForProviders` in `home/.pi/agent/pi-vcc-config.json`).

* `/pi-vcc` compacts now.
* To hand compaction back to pi, set `"overrideDefaultCompaction": false` in `pi-vcc-config.json`.

---

## Sandbox

`pi-sandbox` runs the `bash` tool under bubblewrap. The global rules are in `home/.pi/agent/sandbox.json`.

* `pi --no-sandbox`: disable for the session.
* `/sandbox`: show the configuration and this session's allowances.
* `/sandbox-enable`, `/sandbox-disable`: toggle for the session.
* `/sandbox-allow domain <url>`, `/sandbox-allow read <path>`, `/sandbox-allow write <path>`: prompt to add an allowance.
* `.pi/sandbox.json`: per-project rules, loaded only when pi trusts the project.

Commands typed with `!` and `bg_run` (pi-background) are not sandboxed.

Allowances saved "for all projects" write through the stowed symlink into `home/.pi/agent/sandbox.json`, so they show up in this repo. Review them before committing.

---

## Permissions

`pi-permission-system` asks before bash commands (read-only ones excepted) and before access outside the project, and denies secret paths. The global rules are in `home/.pi/agent/extensions/pi-permission-system/config.json`.

* `/permission-system`: configure logging and yolo mode (no prompts).
* `.pi/extensions/pi-permission-system/config.json`: per-project rules, loaded only when pi trusts the project.

`cc-safety-net` runs first and hard-blocks destructive commands; it has no per-project switch.

---

## Neovim

### Avante

Use pi as Avante's ACP provider in a project with `.nvim.lua` (see [AVANTE.md](AVANTE.md)):

```lua
vim.g.avante_provider = 'pi'
```

### pi-ide diff review

pi-ide's diff review of pi's edits is off by default, so edits apply directly.

* `:PiDiffEnable`: review each edit in a diff before it is applied.
* `:PiDiffDisable`: apply edits without review.
* `:PiDiffToggle`: switch between the two.

The setting lasts until Neovim exits.
