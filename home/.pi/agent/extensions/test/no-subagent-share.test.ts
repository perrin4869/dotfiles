import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { extension, type Harness, startSession, stubTools, toolResults } from './harness.ts';

let harness: Harness | undefined;
afterEach(() => harness?.dispose());

async function call(tool: string, input: Parameters<typeof fauxToolCall>[1]) {
	harness = await startSession({
		extensions: [extension('no-subagent-share')],
		factories: [stubTools('subagent', 'other')],
	});
	harness.respond(
		fauxAssistantMessage(fauxToolCall(tool, input), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	return toolResults(harness.session);
}

test('blocks a top-level share', async () => {
	const [result] = await call('subagent', { agent: 'worker', task: 'x', share: true });
	assert.equal(result.isError, true);
	assert.match(result.text, /sharing subagent sessions is disabled/);
});

test('blocks a share nested in parallel tasks', async () => {
	const [result] = await call('subagent', {
		tasks: [
			{ agent: 'a', task: 'x' },
			{ agent: 'b', task: 'y', share: true },
		],
	});
	assert.equal(result.isError, true);
});

test('allows subagent calls without share', async () => {
	assert.deepEqual(await call('subagent', { agent: 'worker', task: 'x', share: false }), [
		{ isError: false, text: 'ran' },
	]);
});

test('ignores share on other tools', async () => {
	assert.deepEqual(await call('other', { share: true }), [{ isError: false, text: 'ran' }]);
});
