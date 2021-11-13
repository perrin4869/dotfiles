require("commented").setup({
  	keybindings = {n = "gc", v = "gc", nl = "gcc"},
    hooks = {
        before_comment = require("ts_context_commentstring.internal").update_commentstring,
    },
})
