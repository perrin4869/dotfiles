# AVANTE.md

Avante can be configured per project using a `.nvim.lua` file at the repository root.

---

## Provider selection

```lua
vim.g.avante_provider = "<provider>"
```

Selects which backend Avante uses.

If unset, the default is:

```lua
"ollama"
```

---

## Copilot setup

To use Copilot in this project, create `.nvim.lua` with:

```lua
vim.g.avante_provider = "copilot"
vim.g.enable_copilot_ls = true
```

Avante authenticates Copilot itself: run `:Avante copilot login` once. Credentials from `copilot.lua` or
`copilot.vim` are not imported.

### Required variables

* `vim.g.avante_provider = "copilot"`

  * Switches Avante to the Copilot provider

* `vim.g.enable_copilot_ls = true`

  * Enables the Copilot language server

---

## Claude authentication

`vim.g.avante_claude_auth_type` selects how the `claude` provider authenticates. It accepts exactly two values;
anything else fails with `Provider "claude" does not support auth_type "<value>"` when Avante resolves the
provider.

```lua
vim.g.avante_claude_auth_type = "subscription"
```

* `"api_key"` (the default)

  * Reads `ANTHROPIC_API_KEY`, no login needed

* `"subscription"`

  * Uses a Claude Pro or Max account, and needs `:Avante claude login` once; credentials from an earlier Avante
    version are not imported
