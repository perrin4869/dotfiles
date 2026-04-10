local yall = require('yall')
yall.pack('render-markdown', 'render-markdown.nvim')
local fts = { 'markdown', 'Avante' }
yall.on_ft('render-markdown', {
	once = true,
	pattern = fts,
})

vim.g.render_markdown_config = {
	file_types = fts,
	completions = { lsp = { enabled = true } },
}
