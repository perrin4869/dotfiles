local yall = require('yall')
yall.pack('render-markdown', 'render-markdown.nvim')
-- FileType patterns match the whole "markdown.Avante", which only the compound pattern covers
yall.on_ft('render-markdown', {
	once = true,
	pattern = { 'markdown', 'markdown.*' },
})

vim.g.render_markdown_config = {
	completions = { lsp = { enabled = true } },
}
