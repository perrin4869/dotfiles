import type { AgentSession } from '@earendil-works/pi-coding-agent';
import { TuiMainScreen } from '@earendil-works/pi-tui';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { setImmediate as settle } from 'node:timers/promises';
import { extension, startSession } from './harness.ts';
import { RecordingTerminal } from './recording-terminal.ts';

// the full-redraw path clears the screen and the scrollback before repainting; a plain render never does
const CLEAR = '\x1b[2J\x1b[H\x1b[3J';
const CTRL_L = '\x0c';

type Probe = {
	session: AgentSession;
	terminal: RecordingTerminal;
	prompt: (type: 'ui_prompt_start' | 'ui_prompt_end') => Promise<void>;
};

// a session whose UI is a real TUI over a terminal that records, so a forced render shows up in its output
async function withTui(run: (probe: Probe) => Promise<void> | void) {
	const terminal = new RecordingTerminal();
	const tui = new TuiMainScreen(terminal);
	tui.start();
	using stopTui = new DisposableStack();
	stopTui.defer(() => tui.stop());
	using harness = await startSession({ extensions: [extension('redraw')], tui });
	tui.renderNow();
	terminal.output = '';
	await run({
		session: harness.session,
		terminal,
		prompt: (type) => harness.session.extensionRunner.emit({ type, reason: 'ui_prompt', kind: 'select' }),
	});
	// a forced render is scheduled on the next tick, and an immediate runs after that queue
	await settle();
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
	const output = await withTui(async ({ prompt, terminal }) => {
		await prompt('ui_prompt_start');
		terminal.type(CTRL_L);
	});
	assert.ok(output.includes(CLEAR));
});

test('leaves ctrl+l alone without a dialog, and after one closes', async () => {
	const output = await withTui(async ({ prompt, terminal }) => {
		terminal.type(CTRL_L);
		await prompt('ui_prompt_start');
		await prompt('ui_prompt_end');
		terminal.type(CTRL_L);
	});
	assert.ok(!output.includes(CLEAR));
});

test('leaves other keys to the dialog', async () => {
	const output = await withTui(async ({ prompt, terminal }) => {
		await prompt('ui_prompt_start');
		terminal.type('j');
	});
	assert.ok(!output.includes(CLEAR));
});
