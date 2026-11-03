import type { ExtensionAPI, ToolCallEvent } from '@earendil-works/pi-coding-agent';
import { homedir } from 'node:os';
import { delimiter, join } from 'node:path';
import { env } from 'node:process';

const LSP_PACKAGE = /^npm:@narumitw\/pi-lsp(@|$)/;
const MASON_BIN = join(env.XDG_DATA_HOME || join(homedir(), '.local', 'share'), 'nvim', 'mason', 'bin');

// pi-lsp resolves servers from PATH when a tool runs, so Mason's servers are only needed from then on
export default function (pi: ExtensionAPI) {
	const unsubscribe = pi.on('tool_call', async (event: ToolCallEvent) => {
		if (!pi.getAllTools().some((t) => t.name === event.toolName && LSP_PACKAGE.test(t.sourceInfo.source))) return;
		const entries = (env.PATH ?? '').split(delimiter).filter(Boolean);
		if (!entries.includes(MASON_BIN)) env.PATH = [...entries, MASON_BIN].join(delimiter);
		unsubscribe();
	});
}
