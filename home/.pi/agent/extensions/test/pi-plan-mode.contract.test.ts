import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { extension, type Harness, packageExtension, startSession } from './harness.ts';

// opusplan reads pi-plan-mode's state from its session entries; this fails when an update changes them

const models = [{ id: 'start' }, { id: 'plan' }, { id: 'execute' }];

async function turn(h: Harness) {
	h.respond(fauxAssistantMessage('ok'));
	await h.session.prompt('go');
	return h.session.model?.id;
}

test('opusplan follows the real pi-plan-mode', async () => {
	using h = await startSession({
		extensions: [packageExtension('@narumitw/pi-plan-mode'), extension('opusplan')],
		models,
		model: 'start',
		projectSettings: { opusplan: { enabled: true, plan: 'faux/plan', execute: 'faux/execute' } },
	});
	assert.equal(await turn(h), 'execute');
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
});
