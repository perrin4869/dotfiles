import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { extension, type Harness, type HarnessOptions, startSession } from './harness.ts';

const models = [{ id: 'start' }, { id: 'plan' }, { id: 'execute' }];
const ENABLED = { opusplan: { enabled: true, plan: 'faux/plan', execute: 'faux/execute' } };

let harness: Harness | undefined;
afterEach(() => harness?.dispose());

async function start(options: Partial<HarnessOptions> = {}) {
	harness = await startSession({ extensions: [extension('opusplan')], models, model: 'start', ...options });
	return harness;
}

async function turn(h: Harness) {
	h.respond(fauxAssistantMessage('ok'));
	await h.session.prompt('go');
	return h.session.model?.id;
}

// what pi-plan-mode records when /plan is toggled
const setPlanning = (h: Harness, enabled: boolean) =>
	h.sessionManager.appendCustomEntry('plan-mode-state', { enabled });

test('does nothing unless enabled', async () => {
	assert.equal(await turn(await start()), 'start');
});

test('uses the execute model outside plan mode', async () => {
	assert.equal(await turn(await start({ projectSettings: ENABLED })), 'execute');
});

test('switches with plan mode', async () => {
	const h = await start({ projectSettings: ENABLED });
	setPlanning(h, true);
	assert.equal(await turn(h), 'plan');
	setPlanning(h, false);
	assert.equal(await turn(h), 'execute');
});

test('project settings override global ones per field', async () => {
	const h = await start({
		globalSettings: ENABLED,
		projectSettings: { opusplan: { execute: 'faux/start' } },
	});
	assert.equal(await turn(h), 'start');
	setPlanning(h, true);
	assert.equal(await turn(h), 'plan');
});

test('a project can disable a global enable', async () => {
	assert.equal(
		await turn(await start({ globalSettings: ENABLED, projectSettings: { opusplan: { enabled: false } } })),
		'start',
	);
});

test('/opusplan toggles it', async () => {
	const h = await start({ globalSettings: { opusplan: { plan: 'faux/plan', execute: 'faux/execute' } } });
	await h.session.prompt('/opusplan');
	assert.equal(await turn(h), 'execute');
	await h.session.prompt('/opusplan');
	setPlanning(h, true);
	assert.equal(await turn(h), 'execute');
});

test('keeps the model when the target is unavailable', async () => {
	assert.equal(
		await turn(await start({ projectSettings: { opusplan: { enabled: true, execute: 'faux/missing' } } })),
		'start',
	);
});
