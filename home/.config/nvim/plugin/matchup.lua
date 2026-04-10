local yall = require('yall')
-- very-lazy will fail to setup on the first opened buffer
yall.pack('matchup', 'vim-matchup')
yall.on_bufreadpost('matchup')
