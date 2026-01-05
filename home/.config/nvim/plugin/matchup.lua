local defer = require("defer")
-- very-lazy will fail to setup on the first opened buffer
defer.pack("matchup", "vim-matchup")
defer.on_bufreadpost("matchup")
