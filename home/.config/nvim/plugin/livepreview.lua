local defer = require("defer")
-- very-lazy will fail to setup on the first opened buffer
defer.on_load("livepreview", "live-preview.nvim")
defer.hook("livepreview")
defer.cmd("LivePreview", "livepreview")
