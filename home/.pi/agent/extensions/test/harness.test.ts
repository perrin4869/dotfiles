import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import { type Terminal, TuiMainScreen, type TUI } from '@earendil-works/pi-tui';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { startSession } from './harness.ts';

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

const widgetExtension =
	(seen: TUI[]): ExtensionFactory =>
	(pi) => {
		pi.on('session_start', (_event, ctx) => {
			ctx.ui.setWidget('probe', (tui) => {
				seen.push(tui);
				return { render: () => [], invalidate: () => {} };
			});
		});
	};

const inputExtension =
	(consumed: string[]): ExtensionFactory =>
	(pi) => {
		pi.on('session_start', (_event, ctx) => {
			ctx.ui.onTerminalInput((data) => {
				if (data !== 'x') return undefined;
				consumed.push(data);
				return { consume: true };
			});
		});
	};

test('hands the given TUI to widget factories', async () => {
	const seen: TUI[] = [];
	const tui = new TuiMainScreen(new RecordingTerminal());
	tui.start();
	try {
		using harness = await startSession({ extensions: [], factories: [widgetExtension(seen)], tui });
		assert.deepEqual(seen, [tui]);
	} finally {
		tui.stop();
	}
});

test('routes typed input to the listeners the UI registered', async () => {
	const consumed: string[] = [];
	using harness = await startSession({ extensions: [], factories: [inputExtension(consumed)] });
	assert.equal(harness.type('y'), false);
	assert.equal(harness.type('x'), true);
	assert.deepEqual(consumed, ['x']);
});
