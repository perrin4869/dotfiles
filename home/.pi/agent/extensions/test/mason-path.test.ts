import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { env } from 'node:process';
import { afterEach, beforeEach, test } from 'node:test';
import { extension, type Harness, startSession, stubTools } from './harness.ts';

// read when the extension loads
env.XDG_DATA_HOME = '/xdg';
const MASON_BIN = join('/xdg', 'nvim', 'mason', 'bin');

let harness: Harness | undefined;
let path: string | undefined;
beforeEach(() => {
	path = env.PATH;
	env.PATH = '/usr/bin';
});
afterEach(() => {
	harness?.dispose();
	env.PATH = path;
});

async function call(...tools: string[]) {
	harness = await startSession({
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
}

test('adds Mason to PATH when a pi-lsp tool runs', async () => {
	await call('lsp_hover');
	assert.equal(env.PATH, `/usr/bin:${MASON_BIN}`);
});

test('leaves PATH alone for other tools', async () => {
	await call('other');
	assert.equal(env.PATH, '/usr/bin');
});

test('adds Mason once', async () => {
	await call('lsp_hover', 'lsp_hover');
	assert.equal(env.PATH, `/usr/bin:${MASON_BIN}`);
});

test('keeps an existing Mason entry', async () => {
	env.PATH = `${MASON_BIN}:/usr/bin`;
	await call('lsp_hover');
	assert.equal(env.PATH, `${MASON_BIN}:/usr/bin`);
});
