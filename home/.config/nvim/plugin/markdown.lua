local defer = require('defer')
defer.pack('render-markdown', 'render-markdown.nvim')
local fts = { 'markdown', 'Avante' }
defer.on_ft('render-markdown', {
	once = true,
	pattern = fts,
})

vim.g.render_markdown_config = {
	file_types = fts,
	completions = { lsp = { enabled = true } },
}
