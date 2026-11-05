import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { join } from 'node:path';
import { appendToPath, xdgDataHome } from './lib/env.ts';

const LSP_PACKAGE = /^npm:@narumitw\/pi-lsp(@|$)/;
const MASON_BIN = join(xdgDataHome(), 'nvim', 'mason', 'bin');

// pi-lsp resolves servers from PATH when a tool runs, so Mason's servers are only needed from then on
export default function (pi: ExtensionAPI) {
	// a tool call carries only the tool's name, so look up pi-lsp's tools once every extension has registered them
	let lspTools = new Set<string>();
	pi.on('session_start', () => {
		const tools = pi.getAllTools().filter((tool) => LSP_PACKAGE.test(tool.sourceInfo.source));
		lspTools = new Set(tools.map((tool) => tool.name));
	});

	const unsubscribe = pi.on('tool_call', (event) => {
		if (!lspTools.has(event.toolName)) return;
		appendToPath(MASON_BIN);
		unsubscribe();
	});
}
