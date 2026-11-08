import type { AgentSession, ExtensionUIContext } from '@earendil-works/pi-coding-agent';
import { type Terminal, TuiMainScreen } from '@earendil-works/pi-tui';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHarness, extension } from './harness.ts';

// the full-redraw path clears the screen and the scrollback before repainting; a plain render never does
const CLEAR = '\x1b[2J\x1b[H\x1b[3J';

type WidgetFactory = Extract<Parameters<ExtensionUIContext['setWidget']>[1], Function>;

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

// what a real TUI writes to the terminal when `trigger` runs, after its first frame
async function written(trigger: (session: AgentSession) => Promise<void>) {
	using cleanup = new DisposableStack();
	const harness = cleanup.use(await createHarness({ extensions: [extension('redraw')] }));
	const terminal = new RecordingTerminal();
	const tui = new TuiMainScreen(terminal);
	tui.start();
	cleanup.defer(() => tui.stop());
	tui.renderNow();

	const ui = harness.session.extensionRunner.getUIContext();
	await harness.session.bindExtensions({
		uiContext: {
			...ui,
			setWidget: (_key: string, content: string[] | WidgetFactory | undefined) => {
				if (typeof content === 'function') content(tui, ui.theme);
			},
		},
	});

	const before = terminal.output.length;
	await trigger(harness.session);
	// a forced render runs on the next tick
	await new Promise((resolve) => process.nextTick(resolve));
	return terminal.output.slice(before);
}

test('ctrl+l clears and repaints the screen', async () => {
	const output = await written(async (session) => {
		await session.extensionRunner.getShortcuts({}).get('ctrl+l')?.handler(session.extensionRunner.createContext());
	});
	assert.ok(output.includes(CLEAR));
});

test('/redraw clears and repaints the screen', async () => {
	const output = await written((session) => session.prompt('/redraw'));
	assert.ok(output.includes(CLEAR));
});
