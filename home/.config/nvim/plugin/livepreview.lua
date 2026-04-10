local yall = require('yall')
-- very-lazy will fail to setup on the first opened buffer
yall.pack('livepreview', 'live-preview.nvim')
yall.hook('livepreview')
yall.cmd('LivePreview', 'livepreview')
