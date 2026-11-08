import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';

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
}
