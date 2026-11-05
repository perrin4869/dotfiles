import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { homedir } from 'node:os';
import { delimiter, join } from 'node:path';
import { env } from 'node:process';

const LSP_PACKAGE = /^npm:@narumitw\/pi-lsp(@|$)/;
const MASON_BIN = join(env.XDG_DATA_HOME || join(homedir(), '.local', 'share'), 'nvim', 'mason', 'bin');

// pi-lsp resolves servers from PATH when a tool runs, so Mason's servers are only needed from then on
export default function (pi: ExtensionAPI) {
	const isLspTool = (name: string) =>
		pi.getAllTools().some((tool) => tool.name === name && LSP_PACKAGE.test(tool.sourceInfo.source));

	const unsubscribe = pi.on('tool_call', (event) => {
		if (!isLspTool(event.toolName)) return;
		const path = (env.PATH ?? '').split(delimiter).filter(Boolean);
		if (!path.includes(MASON_BIN)) env.PATH = [...path, MASON_BIN].join(delimiter);
		unsubscribe();
	});
}
