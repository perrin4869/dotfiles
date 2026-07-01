local yall = require('yall')
-- snacks used by avante.nvim and claudecode.nvim
yall.pack('snacks', 'snacks.nvim')
yall.setup('snacks')
yall.hook('snacks') -- avante.nvim might not even call snacks so load it only when needed
