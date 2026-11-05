import { fauxProvider } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { env } from 'node:process';
import { afterEach, beforeEach, test } from 'node:test';
import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import { extension, type Harness, startSession } from './harness.ts';

let harness: Harness | undefined;
beforeEach(() => {
	delete env.PI_MEMORY_EXIT_SUMMARY;
});
afterEach(() => {
	harness?.dispose();
	delete env.PI_MEMORY_EXIT_SUMMARY;
});

const start = (provider: string, factories: ExtensionFactory[] = []) =>
	startSession({ extensions: [extension('pi-memory-env')], provider, factories });

test('enables the exit summary on a free provider', async () => {
	harness = await start('ollama');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '1');
});

test('disables the exit summary on a paid provider', async () => {
	harness = await start('anthropic');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
});

test('follows model changes', async () => {
	const ollama = fauxProvider({ provider: 'ollama' });
	harness = await start('anthropic', [(pi) => pi.registerProvider(ollama.provider)]);
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
	await harness.session.setModel(ollama.getModel());
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '1');
});

test('keeps an explicit setting', async () => {
	env.PI_MEMORY_EXIT_SUMMARY = '0';
	harness = await start('ollama');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
});
