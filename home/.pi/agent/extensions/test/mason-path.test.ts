import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { env } from 'node:process';
import { test } from 'node:test';
import { extension, overrideEnv, startSession, stubTools } from './harness.ts';

// read when the extension loads; node --test runs each file in its own process
env.XDG_DATA_HOME = '/xdg';
const MASON_BIN = join('/xdg', 'nvim', 'mason', 'bin');

// PATH after a fresh session that starts with `path` runs these tools
async function pathAfter(tools: string[], path = '/usr/bin') {
	using restoreEnv = overrideEnv({ PATH: path });
	using harness = await startSession({
		extensions: [extension('mason-path')],
		factories: [stubTools('lsp_hover', 'other')],
		toolSources: { lsp_hover: 'npm:@narumitw/pi-lsp@1.0.0' },
	});
	for (const tool of tools) {
		harness.respond(
			fauxAssistantMessage(fauxToolCall(tool, {}), { stopReason: 'toolUse' }),
			fauxAssistantMessage('done'),
		);
		await harness.session.prompt('go');
	}
	return env.PATH;
}

test('adds Mason to PATH when a pi-lsp tool runs', async () => {
	assert.equal(await pathAfter(['lsp_hover']), `/usr/bin:${MASON_BIN}`);
});

test('leaves PATH alone for other tools', async () => {
	assert.equal(await pathAfter(['other']), '/usr/bin');
});

test('adds Mason once', async () => {
	assert.equal(await pathAfter(['lsp_hover', 'lsp_hover']), `/usr/bin:${MASON_BIN}`);
});

test('keeps an existing Mason entry', async () => {
	assert.equal(await pathAfter(['lsp_hover'], `${MASON_BIN}:/usr/bin`), `${MASON_BIN}:/usr/bin`);
});
