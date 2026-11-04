-- Type-check the Neovim config with lua-language-server, as the editor sees it.
-- Run with `nvim -l`. The library is $VIMRUNTIME plus every installed plugin's lua/, which lazydev
-- adds per file in the editor; it lives in a generated config instead of .luarc.json, which would
-- override lazydev's.
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, 'S').source:sub(2))))
local config_dir = vim.fs.joinpath(root, 'home', '.config', 'nvim')
local lua_ls = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin', 'lua-language-server')

local library = { vim.env.VIMRUNTIME }
vim.list_extend(library, vim.fn.globpath(vim.o.packpath, 'pack/*/*/*/lua', false, true))
vim.list_extend(library, vim.fn.globpath(vim.o.packpath, 'pack/*/*/luvit-meta/library', false, true))

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, 'p')
local configpath = vim.fs.joinpath(tmp, 'luarc.json')
vim.fn.writefile({
	vim.json.encode({
		runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' }, pathStrict = true },
		workspace = { library = library, checkThirdParty = false },
	}),
}, configpath)

local result = vim
	.system({
		lua_ls,
		'--check=' .. config_dir,
		'--configpath=' .. configpath,
		'--check_out_path=' .. vim.fs.joinpath(tmp, 'check.json'),
		'--logpath=' .. tmp,
	}, { text = true })
	:wait()

local ok, report = pcall(vim.fn.readfile, vim.fs.joinpath(tmp, 'check.json'))
local problems = ok and vim.json.decode(table.concat(report, '\n')) or {}
vim.fn.delete(tmp, 'rf')
if result.code ~= 0 and vim.tbl_isempty(problems) then
	io.stderr:write(('lua-language-server failed (%d):\n%s'):format(result.code, result.stderr or ''))
	os.exit(1)
end

local lines = {}
for uri, diagnostics in pairs(problems) do
	local file = vim.fs.relpath(root, vim.uri_to_fname(uri)) or vim.uri_to_fname(uri)
	for _, d in ipairs(diagnostics) do
		table.insert(
			lines,
			('%s:%d:%d [%s] %s'):format(file, d.range.start.line + 1, d.range.start.character + 1, d.code, d.message)
		)
	end
end
table.sort(lines)
for _, line in ipairs(lines) do
	io.stderr:write(line .. '\n')
end
os.exit(#lines == 0 and 0 or 1)
