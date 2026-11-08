import type { AgentSession, ExtensionUIContext } from '@earendil-works/pi-coding-agent';
import { type Terminal, TuiMainScreen } from '@earendil-works/pi-tui';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHarness, extension } from './harness.ts';

// the full-redraw path clears the screen and the scrollback before repainting; a plain render never does
const CLEAR = '\x1b[2J\x1b[H\x1b[3J';
const CTRL_L = '\x0c';

type InputHandler = Parameters<ExtensionUIContext['onTerminalInput']>[0];
const ignore: InputHandler = () => undefined;

// a terminal that only records what pi-tui writes to it
class RecordingTerminal implements Terminal {
	output = '';
	columns = 80;
	rows = 24;
	kittyProtocolActive = false;
	start() {}
	stop() {}
	async drainInput() {}
	write(data: string) {
		this.output += data;
	}
	moveBy() {}
	hideCursor() {}
	showCursor() {}
	clearLine() {}
	clearFromCursor() {}
	clearScreen() {}
	setTitle() {}
	setProgress() {}
	setProgramStatus() {}
}

type Probe = {
	session: AgentSession;
	terminal: RecordingTerminal;
	typed: (data: string) => ReturnType<InputHandler>;
	prompt: (type: 'ui_prompt_start' | 'ui_prompt_end') => Promise<void>;
};

// a session running a real TUI on RecordingTerminal, plus the raw input handler the extension registered
async function withTui(trigger: (probe: Probe) => Promise<void> | void) {
	using harness = await createHarness({ extensions: [extension('redraw')] });
	const terminal = new RecordingTerminal();
	const tui = new TuiMainScreen(terminal);
	tui.start();
	const session = harness.session;
	let input: InputHandler = ignore;
	let listening = false;
	const ui = session.extensionRunner.getUIContext();
	await session.bindExtensions({
		uiContext: {
			...ui,
			setWidget: (_key, content) => {
				if (typeof content === 'function') content(tui, ui.theme);
			},
			onTerminalInput: (handler) => {
				input = handler;
				listening = true;
				return () => {
					listening = false;
					input = ignore;
				};
			},
		},
	});
	tui.renderNow();
	terminal.output = '';
	try {
		await trigger({
			session,
			terminal,
			typed: (data) => (listening ? input(data) : undefined),
			prompt: (type) => session.extensionRunner.emit({ type, reason: 'ui_prompt', kind: 'select' }),
		});
		// a forced render runs on the next tick
		await new Promise((resolve) => process.nextTick(resolve));
	} finally {
		tui.stop();
	}
	return terminal.output;
}

test('ctrl+l clears and repaints the screen', async () => {
	const output = await withTui(({ session }) =>
		session.extensionRunner.getShortcuts({}).get('ctrl+l')?.handler(session.extensionRunner.createContext()),
	);
	assert.ok(output.includes(CLEAR));
});

test('/redraw clears and repaints the screen', async () => {
	const output = await withTui(({ session }) => session.prompt('/redraw'));
	assert.ok(output.includes(CLEAR));
});

test('ctrl+l redraws while a dialog is open', async () => {
	let consumed: boolean | undefined;
	const output = await withTui(async ({ prompt, typed }) => {
		await prompt('ui_prompt_start');
		consumed = typed(CTRL_L)?.consume;
	});
	assert.equal(consumed, true);
	assert.ok(output.includes(CLEAR));
});

test('leaves ctrl+l alone without a dialog, and after one closes', async () => {
	const output = await withTui(async ({ prompt, typed }) => {
		assert.equal(typed(CTRL_L), undefined);
		await prompt('ui_prompt_start');
		await prompt('ui_prompt_end');
		assert.equal(typed(CTRL_L), undefined);
	});
	assert.deepEqual(output, '');
});

test('leaves other keys to the dialog', async () => {
	const output = await withTui(async ({ prompt, typed }) => {
		await prompt('ui_prompt_start');
		assert.equal(typed('j'), undefined);
	});
	assert.deepEqual(output, '');
});
