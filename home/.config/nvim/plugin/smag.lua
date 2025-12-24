local defer = require("defer")
defer.on_load("lsp_smag", "nvim-lsp-smag")
defer.on_event("lsp_smag", "LspAttach")
