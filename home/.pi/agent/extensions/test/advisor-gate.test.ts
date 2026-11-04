import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { extension, type Harness, type HarnessOptions, startSession, stubTools, toolResults } from './harness.ts';

let harness: Harness | undefined;
afterEach(() => harness?.dispose());

async function call(tool: string, options: Partial<HarnessOptions> = {}) {
	harness = await startSession({
		extensions: [extension('advisor-gate')],
		factories: [stubTools('advisor', 'other')],
		...options,
	});
	harness.respond(
		fauxAssistantMessage(fauxToolCall(tool, {}), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	return toolResults(harness.session);
}

const ENABLED = { advisor: { enabled: true } };
const DISABLED = { advisor: { enabled: false } };

test('blocks the advisor by default', async () => {
	const [result] = await call('advisor');
	assert.equal(result.isError, true);
	assert.match(result.text, /advisor is disabled for this project/);
});

test('allows the advisor where the project enables it', async () => {
	assert.deepEqual(await call('advisor', { projectSettings: ENABLED }), [{ isError: false, text: 'ran' }]);
});

test('a global enable applies to projects that say nothing', async () => {
	assert.deepEqual(await call('advisor', { globalSettings: ENABLED }), [{ isError: false, text: 'ran' }]);
});

test('a project can disable a global enable', async () => {
	const [result] = await call('advisor', { globalSettings: ENABLED, projectSettings: DISABLED });
	assert.equal(result.isError, true);
});

test('leaves other tools alone', async () => {
	assert.deepEqual(await call('other'), [{ isError: false, text: 'ran' }]);
});
