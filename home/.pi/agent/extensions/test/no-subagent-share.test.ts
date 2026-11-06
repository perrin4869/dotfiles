import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { extension, startSession, stubTools, toolResults } from './harness.ts';

async function call(tool: string, input: Parameters<typeof fauxToolCall>[1]) {
	using harness = await startSession({
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

const blocked = async (input: Parameters<typeof fauxToolCall>[1]) => {
	const [result] = await call('subagent', { agent: 'worker', task: 'x', ...input });
	return result.isError && /sharing subagent sessions is disabled/.test(result.text);
};

test('blocks a top-level share', async () => {
	assert.equal(await blocked({ share: true }), true);
});

test('blocks a share in options', async () => {
	assert.equal(await blocked({ options: { share: true } }), true);
});

test('blocks a share pi-subagents converts to true', async () => {
	assert.equal(await blocked({ options: { share: 'true' } }), true);
	assert.equal(await blocked({ options: { share: 1 } }), true);
});

test('leaves a top-level share pi-subagents would not convert alone', async () => {
	assert.equal(await blocked({ share: 'true' }), false);
});

test('allows subagent calls without share', async () => {
	assert.equal(await blocked({}), false);
	assert.equal(await blocked({ share: false, options: { share: 'false', async: true } }), false);
});

test('ignores share on other tools', async () => {
	assert.deepEqual(await call('other', { share: true }), [{ isError: false, text: 'ran' }]);
});
