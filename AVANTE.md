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

### Required variables

* `vim.g.avante_provider = "copilot"`

  * Switches Avante to the Copilot provider

* `vim.g.enable_copilot_ls = true`

  * Enables the Copilot language server
