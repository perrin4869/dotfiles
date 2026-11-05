import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { extension, type Harness, type HarnessOptions, startSession } from './harness.ts';

const models = [{ id: 'start' }, { id: 'plan' }, { id: 'execute' }];
const ENABLED = { opusplan: { enabled: true, plan: 'faux/plan', execute: 'faux/execute' } };

const start = (options: Partial<HarnessOptions> = {}) =>
	startSession({ extensions: [extension('opusplan')], models, model: 'start', ...options });

async function turn(h: Harness) {
	h.respond(fauxAssistantMessage('ok'));
	await h.session.prompt('go');
	return h.session.model?.id;
}

// the model after one prompt in a fresh session
async function firstTurn(options: Partial<HarnessOptions> = {}) {
	using h = await start(options);
	// awaited here, before `using` disposes the session
	return await turn(h);
}

// what pi-plan-mode records when /plan is toggled
const setPlanning = (h: Harness, enabled: boolean) =>
	h.sessionManager.appendCustomEntry('plan-mode-state', { enabled });

test('does nothing unless enabled', async () => {
	assert.equal(await firstTurn(), 'start');
});

test('uses the execute model outside plan mode', async () => {
	assert.equal(await firstTurn({ projectSettings: ENABLED }), 'execute');
});

test('switches with plan mode', async () => {
	using h = await start({ projectSettings: ENABLED });
	setPlanning(h, true);
	assert.equal(await turn(h), 'plan');
	setPlanning(h, false);
	assert.equal(await turn(h), 'execute');
});

test('project settings override global ones per field', async () => {
	using h = await start({ globalSettings: ENABLED, projectSettings: { opusplan: { execute: 'faux/start' } } });
	assert.equal(await turn(h), 'start');
	setPlanning(h, true);
	assert.equal(await turn(h), 'plan');
});

test('a project can disable a global enable', async () => {
	assert.equal(
		await firstTurn({ globalSettings: ENABLED, projectSettings: { opusplan: { enabled: false } } }),
		'start',
	);
});

test('/opusplan toggles it', async () => {
	using h = await start({ globalSettings: { opusplan: { plan: 'faux/plan', execute: 'faux/execute' } } });
	await h.session.prompt('/opusplan');
	assert.equal(await turn(h), 'execute');
	await h.session.prompt('/opusplan');
	setPlanning(h, true);
	assert.equal(await turn(h), 'execute');
});

test('keeps the model when the target is unavailable', async () => {
	assert.equal(await firstTurn({ projectSettings: { opusplan: { enabled: true, execute: 'faux/missing' } } }), 'start');
});

test('ignores an untrusted project', async () => {
	assert.equal(await firstTurn({ projectSettings: ENABLED, projectTrusted: false }), 'start');
});

test('warns once about invalid settings and falls back to the defaults', async () => {
	using h = await start({ projectSettings: { opusplan: { enabled: 'yes', plan: 'no-provider' } } });
	assert.equal(await turn(h), 'start');
	assert.equal(await turn(h), 'start');
	assert.deepEqual(h.notifications, [
		'ignoring invalid settings: opusplan.enabled must be boolean; opusplan.plan must match pattern "^[^/]+/.+$"',
	]);
});
