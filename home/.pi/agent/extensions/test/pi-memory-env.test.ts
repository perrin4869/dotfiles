import { fauxProvider } from '@earendil-works/pi-ai';
import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import assert from 'node:assert/strict';
import { env } from 'node:process';
import { test } from 'node:test';
import { extension, overrideEnv, startSession } from './harness.ts';

const start = (provider: string, factories: ExtensionFactory[] = []) =>
	startSession({ extensions: [extension('pi-memory-env')], provider, factories });

// PI_MEMORY_EXIT_SUMMARY once a session starts on `provider`, with the variable initially `initial`
async function exitSummary(provider: string, initial?: string) {
	using restoreEnv = overrideEnv({ PI_MEMORY_EXIT_SUMMARY: initial });
	using harness = await start(provider);
	return env.PI_MEMORY_EXIT_SUMMARY;
}

test('enables the exit summary on a free provider', async () => {
	assert.equal(await exitSummary('ollama'), '1');
});

test('disables the exit summary on a paid provider', async () => {
	assert.equal(await exitSummary('anthropic'), '0');
});

test('keeps an explicit setting', async () => {
	assert.equal(await exitSummary('ollama', '0'), '0');
});

test('follows model changes', async () => {
	using restoreEnv = overrideEnv({ PI_MEMORY_EXIT_SUMMARY: undefined });
	const ollama = fauxProvider({ provider: 'ollama' });
	using harness = await start('anthropic', [(pi) => pi.registerProvider(ollama.provider)]);
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '0');
	await harness.session.setModel(ollama.getModel());
	assert.equal(env.PI_MEMORY_EXIT_SUMMARY, '1');
});
