import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { env } from 'node:process';
import { test } from 'node:test';
import {
	extension,
	type Harness,
	type HarnessOptions,
	overrideEnv,
	packageExtension,
	startSession,
} from './harness.ts';

// pi-memory resolves its directory when it loads, so point it somewhere disposable before the first session
const memoryDir = join(import.meta.dirname, '..', '..', '..', '..', '..', 'node_modules', '.cache', 'pi-memory');
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
	provider: string,
	options: {
		explicit?: string;
		providers?: HarnessOptions['providers'];
		after?: (harness: Harness) => Promise<void>;
	} = {},
) {
	rmSync(memoryDir, { recursive: true, force: true });
	using restoreEnv = overrideEnv({ PI_MEMORY_EXIT_SUMMARY: options.explicit });
	using h = await startSession({
		extensions: [await packageExtension('pi-memory'), extension('pi-memory-env')],
		provider,
		providers: options.providers,
	});
	h.respond(fauxAssistantMessage('one'), fauxAssistantMessage('two'), fauxAssistantMessage(SUMMARY));
	await h.session.prompt('first');
	await h.session.prompt('second');
	await options.after?.(h);
	await h.session.extensionRunner.emit({ type: 'session_shutdown', reason: 'quit' });
	return dailyLog().includes(SUMMARY);
}

test('summarises the session on exit with a free provider', async () => {
	assert.equal(await summarized('ollama'), true);
});

test('skips the summary on exit with a paid provider', async () => {
	assert.equal(await summarized('anthropic'), false);
});

test('an explicit setting wins', async () => {
	assert.equal(await summarized('ollama', { explicit: '0' }), false);
});

test('follows model changes', async () => {
	// switching from a free provider to a paid one stops the summary the free one would have written
	const switchedToPaid = await summarized('ollama', {
		providers: [{ provider: 'anthropic', models: [{ id: 'paid' }] }],
		after: async (h) => {
			const model = h.session.modelRuntime.getModel('anthropic', 'paid');
			assert.ok(model);
			await h.session.setModel(model);
		},
	});
	assert.equal(switchedToPaid, false);
});
