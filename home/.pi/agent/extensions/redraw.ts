import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { matchesKey } from '@earendil-works/pi-tui';

const KEY = 'redraw';

// ctx.ui exposes no redraw, but a widget factory runs synchronously with the live TUI, so borrow it for one call
function redraw({ ui }: ExtensionContext) {
	ui.setWidget(KEY, (tui) => {
		tui.requestRender(true);
		return { render: () => [], invalidate: () => {} };
	});
	ui.setWidget(KEY, undefined);
}

export default function (pi: ExtensionAPI) {
	pi.registerShortcut('ctrl+l', { description: 'Redraw the screen', handler: redraw });
	// the same action without a key binding
	pi.registerCommand('redraw', { description: 'Redraw the screen', handler: async (_args, ctx) => redraw(ctx) });

	// A shortcut only fires at pi's own prompt, and a dialog takes the keys instead. Raw input reaches listeners
	// before the focused component, so listen only while a dialog is open, and drop the listener when it closes.
	let unsubscribe: (() => void) | undefined;
	const stopListening = () => {
		unsubscribe?.();
		unsubscribe = undefined;
	};
	pi.on('ui_prompt_start', (_event, ctx) => {
		stopListening();
		unsubscribe = ctx.ui.onTerminalInput((data) =>
			matchesKey(data, 'ctrl+l') ? (redraw(ctx), { consume: true }) : undefined,
		);
	});
	pi.on('ui_prompt_end', stopListening);
	pi.on('session_shutdown', stopListening);
}
