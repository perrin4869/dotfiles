import { fauxProvider } from '@earendil-works/pi-ai';
import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import assert from 'node:assert/strict';
import { env } from 'node:process';
import { afterEach, beforeEach, test } from 'node:test';
import { extension, startSession } from './harness.ts';

const clearSetting = () => {
	delete env.PI_MEMORY_EXIT_SUMMARY;
};
beforeEach(clearSetting);
afterEach(clearSetting);

const start = (provider: string, factories: ExtensionFactory[] = []) =>
	startSession({ extensions: [extension('pi-memory-env')], provider, factories });

test('enables the exit summary on a free provider', async () => {
	using harness = await start('ollama');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '1');
});

test('disables the exit summary on a paid provider', async () => {
	using harness = await start('anthropic');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
});

test('follows model changes', async () => {
	const ollama = fauxProvider({ provider: 'ollama' });
	using harness = await start('anthropic', [(pi) => pi.registerProvider(ollama.provider)]);
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
	await harness.session.setModel(ollama.getModel());
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '1');
});

test('keeps an explicit setting', async () => {
	env.PI_MEMORY_EXIT_SUMMARY = '0';
	using harness = await start('ollama');
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
});
