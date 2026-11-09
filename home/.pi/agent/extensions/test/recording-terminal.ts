import type { Terminal } from '@earendil-works/pi-tui';

// A terminal that records what pi-tui writes and delivers input the way a real one does: through the handler TUI
// passes to start(). Feeding keys here exercises the whole path, from terminal to the focused component.
export class RecordingTerminal implements Terminal {
	output = '';
	columns = 80;
	rows = 24;
	kittyProtocolActive = false;
	#input?: (data: string) => void;

	start(onInput: (data: string) => void) {
		this.#input = onInput;
	}

	stop() {}
	async drainInput() {}

	type(data: string) {
		this.#input?.(data);
	}

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
