import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { join } from 'node:path';
import { appendToPath, xdgDataHome } from './lib/env.ts';

const LSP_PACKAGE = /^npm:@narumitw\/pi-lsp(@|$)/;
const MASON_BIN = join(xdgDataHome(), 'nvim', 'mason', 'bin');

// pi-lsp resolves servers from PATH when a tool runs, so Mason's servers are only needed from then on
export default function (pi: ExtensionAPI) {
	const isLspTool = (name: string) =>
		pi.getAllTools().some((tool) => tool.name === name && LSP_PACKAGE.test(tool.sourceInfo.source));

	const unsubscribe = pi.on('tool_call', (event) => {
		if (!isLspTool(event.toolName)) return;
		appendToPath(MASON_BIN);
		unsubscribe();
	});
}
