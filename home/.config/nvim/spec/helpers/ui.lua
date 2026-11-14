-- A child Neovim with a UI, for specs that need real mouse input. Mouse events need a grid to land on, which a headless
-- child has none of, and a channel is either a UI or an RPC endpoint: the pty provides the UI, the listener socket carries
-- the handle. The child boots this config like any other session, so the plugin under test is loaded the way a user's is.
local yd = require('yo-dawg')

local M = {}

local info = debug.getinfo(1, 'S')
---@cast info -nil
local CONFIG = vim.fn.fnamemodify(info.source:sub(2), ':p:h:h:h')
local HOME = vim.fn.fnamemodify(CONFIG, ':h:h')
local SOCKET = CONFIG .. '/spec/.nvim.sock'
-- opening a tracked file rather than nothing keeps the dashboard out of the way; the specs only ever look at it
local SCRATCH = CONFIG .. '/spec/.scratch'

--- @return table<string, function> child
function M.start()
	-- a socket left behind by an interrupted run would keep the child from listening
	vim.fn.delete(SOCKET)

	--- @type integer
	local job
	-- the key a spec wants typed for each kind of prompt, and the kind the last output left on screen
	--- @type { more?: string, enter?: string }
	local page_keys = {}
	--- @type 'more'|'enter'|nil
	local page_on_screen
	-- A pty is a terminal, so the child behaves like any TUI: it paints its screen with escape sequences on stdout and
	-- reads the replies to its queries from stdin. There is no message protocol on top of that, only a screen.
	--- @param data string[]
	--- @return nil
	local function answer(data)
		-- on_stdout delivers lines, and no escape sequence contains a newline, so joining a chunk gives it back whole
		local chunk = table.concat(data, '\n')

		-- OSC 11, "report your background colour": ESC ] 11 ; ? BEL. A terminal answers with the colour,
		-- ESC ] 11 ; rgb:R/G/B ESC \ (ESC \ being the string terminator), which Neovim reads into 'background'.
		if chunk:find('\27%]11;?') then
			vim.fn.chansend(job, '\27]11;rgb:0000/0000/0000\27\\')
		end

		-- DSR 5, "device status report": ESC [ 5 n, asked right after the colour query. The answer is ESC [ 0 n, and
		-- only on receiving it does Neovim stop waiting; without it, it gives up and pages E1568.
		if chunk:find('\27%[5n') then
			vim.fn.chansend(job, '\27[0n')
		end

		-- Neovim draws everything it prints, so tall output is paged by Neovim itself (`-- More --`) and a message that
		-- does not fit one line ends with `Press ENTER or type command to continue`. They are different prompts: the
		-- pager stays up until the message is through, one page per space and one back per `b`, while the hit-enter
		-- prompt waits for any key. Both hold the child and its RPC, so a spec arms the key it expects, if any.
		if chunk:find('%-%- More %-%-') then
			page_on_screen = 'more'
		elseif chunk:find('Press ENTER') then
			page_on_screen = 'enter'
		else
			page_on_screen = nil
		end
		local key = page_on_screen and page_keys[page_on_screen]
		if key then
			vim.fn.chansend(job, key)
		end
	end

	job = vim.fn.jobstart({
		vim.v.progpath,
		'--listen',
		SOCKET,
		'--cmd',
		'set noswapfile',
		SCRATCH,
	}, {
		pty = true,
		width = 80,
		height = 24,
		-- the checkout is the child's home, so it boots this config rather than the machine's
		env = vim.tbl_extend('force', vim.fn.environ(), { HOME = HOME, TERM = 'xterm-256color' }),
		on_stdout = function(_, data)
			answer(data)
		end,
	})

	assert(
		vim.wait(8000, function()
			return vim.uv.fs_stat(SOCKET) ~= nil
		end, 20),
		'the child never listened'
	)

	local chan = vim.fn.sockconnect('pipe', SOCKET, { rpc = true })
	-- the socket is up before the config has finished starting, so ask until it says it has; the timeout keeps one
	-- answer from outliving the wait
	assert(
		vim.wait(20000, function()
			local ok, entered = pcall(
				vim.rpcrequest,
				chan,
				{ timeout = 1000 },
				'nvim_exec_lua',
				'return vim.v.vim_did_enter',
				{}
			)
			return ok and entered == 1
		end, 100),
		'the child never finished starting'
	)

	local child = yd.connect(chan)

	--- @param button string one of the names nvim_input_mouse takes, "x1" included
	--- @param action string
	--- @param win? integer the window to point at, the current one by default
	function child.mouse(button, action, win)
		-- (2, 2) inside the window, whose own top-left cell can be a winbar; grid 0 is the whole screen
		local pos =
			child:exec_lua(('local p = vim.api.nvim_win_get_position(%d) return { p[1] + 2, p[2] + 2 }'):format(win or 0), {})
		child:async_input_mouse(button, action, '', 0, pos[1], pos[2])
		child:exec_lua('vim.wait(600, function() return false end, 10)', {})
	end

	-- A prompt waits for a key, and which one depends on which prompt it is: a space takes the pager's next page and
	-- `b` the one before it, while the hit-enter prompt wants any key at all. Typing it as the prompt is drawn is the
	-- point, so these arm a key rather than send one now; a prompt already on screen gets it at once, since nothing
	-- further will be printed to react to.
	--- @param key? string the key typed at every `-- More --` page from now on; nil stops answering
	function child.answer_more(key)
		page_keys.more = key
		if key and page_on_screen == 'more' then
			vim.fn.chansend(job, key)
		end
	end

	--- @param key? string the key typed at every `Press ENTER or type command to continue` prompt from now on; nil
	--- stops answering
	function child.answer_enter(key)
		page_keys.enter = key
		if key and page_on_screen == 'enter' then
			vim.fn.chansend(job, key)
		end
	end

	--- @param keys string keys to type into the child's terminal, without waiting for a page
	function child.send(keys)
		vim.fn.chansend(job, keys)
		vim.wait(100, function()
			return false
		end, 10)
	end

	-- yo-dawg's own stop waits on the channel it started, which here is the pty rather than the handle
	function child.stop()
		child:async_cmd({ cmd = 'quitall', bang = true }, {})
		vim.fn.jobwait({ job }, 2000)
		vim.fn.jobstop(job)
		vim.fn.delete(SOCKET)
	end

	return child
end

return M
