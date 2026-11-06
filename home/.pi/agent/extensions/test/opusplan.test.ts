import { fauxAssistantMessage } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { mock, test } from 'node:test';
import {
	extension,
	type Harness,
	type HarnessOptions,
	type NotifyListener,
	type StartOptions,
	packageExtension,
	startSession,
} from './harness.ts';

// opusplan reads pi-plan-mode's state from its session entries, so these run against the real package
const planMode = await packageExtension('@narumitw/pi-plan-mode');
const models = [{ id: 'start' }, { id: 'plan' }, { id: 'execute' }];
const ENABLED = { opusplan: { enabled: true, plan: 'faux/plan', execute: 'faux/execute' } };

const start = (options: Partial<HarnessOptions & StartOptions> = {}) =>
	startSession({ extensions: [planMode, extension('opusplan')], models, model: 'start', ...options });

async function turn(h: Harness) {
	h.respond(fauxAssistantMessage('ok'));
	await h.session.prompt('go');
	return h.session.model?.id;
}

test('does nothing unless enabled', async () => {
	using h = await start();
	assert.equal(await turn(h), 'start');
});

test('uses the execute model outside plan mode', async () => {
	using h = await start({ projectSettings: ENABLED });
	assert.equal(await turn(h), 'execute');
});

test('switches with plan mode', async () => {
	using h = await start({ projectSettings: ENABLED });
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
	await h.session.prompt('/plan exit');
	assert.equal(await turn(h), 'execute');
});

test('project settings override global ones per field', async () => {
	using h = await start({ globalSettings: ENABLED, projectSettings: { opusplan: { execute: 'faux/start' } } });
	assert.equal(await turn(h), 'start');
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
});

test('a project can disable a global enable', async () => {
	using h = await start({ globalSettings: ENABLED, projectSettings: { opusplan: { enabled: false } } });
	assert.equal(await turn(h), 'start');
});

test('/opusplan enables it at once', async () => {
	using h = await start({ globalSettings: { opusplan: { plan: 'faux/plan', execute: 'faux/execute' } } });
	await h.session.prompt('/opusplan');
	assert.equal(h.session.model?.id, 'execute');
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
});

test('/opusplan twice keeps it enabled', async () => {
	using h = await start({ globalSettings: { opusplan: { plan: 'faux/plan', execute: 'faux/execute' } } });
	await h.session.prompt('/opusplan');
	await h.session.prompt('/opusplan');
	assert.equal(h.session.model?.id, 'execute');
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
});

test('/opusplan keeps an enable from the settings', async () => {
	using h = await start({ projectSettings: ENABLED });
	await h.session.prompt('/opusplan');
	assert.equal(await turn(h), 'execute');
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'plan');
});

test('switching models disables it', async () => {
	using h = await start({ projectSettings: ENABLED });
	assert.equal(await turn(h), 'execute');
	const model = h.session.modelRuntime.getModel('faux', 'start');
	assert.ok(model);
	await h.session.setModel(model);
	await h.session.prompt('/plan start');
	assert.equal(await turn(h), 'start');
});

test('keeps the model and warns when the target is unavailable', async () => {
	const notify = mock.fn<NotifyListener>();
	using h = await start({
		projectSettings: { opusplan: { enabled: true, plan: 'faux/plan', execute: 'faux/missing' } },
		onNotify: notify,
	});
	assert.equal(await turn(h), 'start');
	assert.deepEqual(
		notify.mock.calls.map((call) => call.arguments),
		[
			['opusplan: faux/missing is not a known model', 'warning'],
			['opusplan: cannot use faux/missing', 'warning'],
		],
	);
});

test('warns about an unknown plan model when the session starts', async () => {
	const notify = mock.fn<NotifyListener>();
	using h = await start({
		projectSettings: { opusplan: { enabled: true, plan: 'faux/missing', execute: 'faux/execute' } },
		onNotify: notify,
	});
	assert.deepEqual(
		notify.mock.calls.map((call) => call.arguments),
		[['opusplan: faux/missing is not a known model', 'warning']],
	);
});

test('checks the models when /opusplan enables it', async () => {
	const notify = mock.fn<NotifyListener>();
	using h = await start({
		globalSettings: { opusplan: { plan: 'faux/missing', execute: 'faux/execute' } },
		onNotify: notify,
	});
	assert.equal(notify.mock.callCount(), 0);
	await h.session.prompt('/opusplan');
	assert.deepEqual(
		notify.mock.calls.map((call) => call.arguments),
		[
			['opusplan enabled', 'info'],
			['opusplan: faux/missing is not a known model', 'warning'],
		],
	);
});

test('ignores an untrusted project', async () => {
	using h = await start({ projectSettings: ENABLED, projectTrusted: false });
	assert.equal(await turn(h), 'start');
});

test('warns once about invalid settings and falls back to the defaults', async () => {
	const notify = mock.fn<NotifyListener>();
	using h = await start({ projectSettings: { opusplan: { enabled: 'yes', plan: 'no-provider' } }, onNotify: notify });
	assert.equal(await turn(h), 'start');
	assert.equal(await turn(h), 'start');
	assert.equal(notify.mock.callCount(), 1);
	assert.deepEqual(notify.mock.calls[0].arguments, [
		'ignoring invalid settings: opusplan.enabled must be boolean; opusplan.plan must match pattern "^[^/]+/.+$"',
		'warning',
	]);
});
