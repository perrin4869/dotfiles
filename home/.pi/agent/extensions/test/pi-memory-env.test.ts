import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { env } from 'node:process';
import { test } from 'node:test';
import {
	extension,
	type Harness,
	type HarnessFaux,
	overrideEnv,
	packageDir,
	packageExtension,
	scriptedFaux,
	startSession,
} from './harness.ts';

// pi-memory resolves its directory when it loads, so point it at a disposable one before the first session; the
// package's own location gives node_modules without counting path levels
const memoryDir = join(dirname(packageDir('pi-memory')), '.cache', 'pi-memory');
env.PI_MEMORY_DIR = memoryDir;
env.PI_MEMORY_NO_SEARCH = '1';
env.PI_MEMORY_QMD_UPDATE = 'off';

const SUMMARY = 'Tried the exit summary';

// what pi-memory appended to the daily log, if anything
function dailyLog() {
	const daily = join(memoryDir, 'daily');
	if (!existsSync(daily)) return '';
	return readdirSync(daily)
		.map((file) => readFileSync(join(daily, file), 'utf8'))
		.join('\n');
}

// runs two prompts and quits the way pi does, then reports whether pi-memory summarised the session
async function summarized(
	faux: HarnessFaux,
	options: { explicit?: string; factories?: ExtensionFactory[]; after?: (harness: Harness) => Promise<void> } = {},
) {
	rmSync(memoryDir, { recursive: true, force: true });
	using restoreEnv = overrideEnv({ PI_MEMORY_EXIT_SUMMARY: options.explicit });
	using h = await startSession({
		extensions: [await packageExtension('pi-memory'), extension('pi-memory-env')],
		faux,
		factories: options.factories,
	});
	h.respond(fauxAssistantMessage('one'), fauxAssistantMessage('two'), fauxAssistantMessage(SUMMARY));
	await h.session.prompt('first');
	await h.session.prompt('second');
	await options.after?.(h);
	await h.session.extensionRunner.emit({ type: 'session_shutdown', reason: 'quit' });
	return dailyLog().includes(SUMMARY);
}

test('summarises the session on exit with a free provider', async () => {
	using faux = scriptedFaux({ provider: 'ollama' });
	assert.equal(await summarized(faux), true);
});

test('skips the summary on exit with a paid provider', async () => {
	using faux = scriptedFaux({ provider: 'anthropic' });
	assert.equal(await summarized(faux), false);
});

test('an explicit setting wins', async () => {
	using faux = scriptedFaux({ provider: 'ollama' });
	assert.equal(await summarized(faux, { explicit: '0' }), false);
});

test('follows model changes', async () => {
	// switching from a free provider to a paid one stops the summary the free one would have written
	using free = scriptedFaux({ provider: 'ollama' });
	using paid = scriptedFaux({ provider: 'anthropic', models: [{ id: 'paid' }] });
	const switchedToPaid = await summarized(free, {
		factories: [(pi) => pi.registerProvider(paid.provider)],
		after: async (h) => {
			const model = h.session.modelRuntime.getModel('anthropic', 'paid');
			assert.ok(model);
			await h.session.setModel(model);
		},
	});
	assert.equal(switchedToPaid, false);
});
