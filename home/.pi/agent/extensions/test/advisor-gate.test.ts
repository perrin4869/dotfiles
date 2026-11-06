import { fauxAssistantMessage, type FauxResponseFactory, fauxToolCall, getCurrentTools } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { env } from 'node:process';
import { test } from 'node:test';
import {
	extension,
	type Harness,
	type HarnessOptions,
	packageExtension,
	startSession,
	stubTools,
	toolResults,
} from './harness.ts';

// the real rpiv-advisor, with faux/reviewer picked as its reviewer in fixtures/config/rpiv-advisor/advisor.json;
// node --test runs each file in its own process
env.XDG_CONFIG_HOME = join(import.meta.dirname, 'fixtures', 'config');

const start = async (options: Partial<HarnessOptions> = {}) =>
	startSession({
		extensions: [await packageExtension('@juicesharp/rpiv-advisor'), extension('advisor-gate')],
		factories: [stubTools('other')],
		models: [{ id: 'executor' }, { id: 'reviewer' }],
		model: 'executor',
		...options,
	});

// the names of the tools a request is offered
const toolNames = (context: Parameters<FauxResponseFactory>[0]) =>
	new Set(getCurrentTools(context.messages).map((tool) => tool.name));

// the tools offered to any request of a prompt that calls one tool and then finishes
async function offeredTools(h: Harness) {
	let offered = new Set<string>();
	const recording =
		(reply: ReturnType<typeof fauxAssistantMessage>): FauxResponseFactory =>
		(context) => {
			offered = offered.union(toolNames(context));
			return reply;
		};
	h.respond(
		recording(fauxAssistantMessage(fauxToolCall('other', {}), { stopReason: 'toolUse' })),
		recording(fauxAssistantMessage('done')),
	);
	await h.session.prompt('go');
	return offered;
}

const offersAdvisorIn = async (options?: Partial<HarnessOptions>) => {
	using h = await start(options);
	return (await offeredTools(h)).has('advisor');
};

const ENABLED = { advisor: { enabled: true } };
const DISABLED = { advisor: { enabled: false } };

test('keeps the advisor and the gate out of the prompt by default', async () => {
	using h = await start();
	const offered = await offeredTools(h);
	assert.ok(!offered.has('advisor') && !offered.has('advisor_gate'), [...offered].join());
});

// opusplan switches models while the run starts, which makes rpiv-advisor re-add its tool
test('keeps the advisor out when another extension switches models', async () => {
	using h = await startSession({
		extensions: [await packageExtension('@juicesharp/rpiv-advisor'), extension('advisor-gate'), extension('opusplan')],
		models: [{ id: 'executor' }, { id: 'reviewer' }, { id: 'target' }],
		model: 'executor',
		projectSettings: { opusplan: { enabled: true, execute: 'faux/target' } },
	});
	let offered = new Set<string>();
	h.respond((context) => {
		offered = offered.union(toolNames(context));
		return fauxAssistantMessage('done');
	});
	await h.session.prompt('go');
	assert.equal(h.session.model?.id, 'target');
	assert.ok(!offered.has('advisor'), [...offered].join());
});

test('hides the advisor by default', async () => {
	assert.equal(await offersAdvisorIn(), false);
});

test('offers the advisor where the project enables it', async () => {
	assert.equal(await offersAdvisorIn({ projectSettings: ENABLED }), true);
});

test('a global enable applies to projects that say nothing', async () => {
	assert.equal(await offersAdvisorIn({ globalSettings: ENABLED }), true);
});

test('a project can disable a global enable', async () => {
	assert.equal(await offersAdvisorIn({ globalSettings: ENABLED, projectSettings: DISABLED }), false);
});

test('an untrusted project cannot enable the advisor', async () => {
	assert.equal(await offersAdvisorIn({ projectSettings: ENABLED, projectTrusted: false }), false);
});

test('stays hidden when the model changes', async () => {
	using h = await start();
	const model = h.session.modelRuntime.getModel('faux', 'reviewer');
	assert.ok(model);
	await h.session.setModel(model);
	assert.equal((await offeredTools(h)).has('advisor'), false);
});

test('an advisor call in a disabled project fails', async () => {
	using h = await start();
	h.respond(fauxAssistantMessage(fauxToolCall('advisor', {}), { stopReason: 'toolUse' }), fauxAssistantMessage('done'));
	await h.session.prompt('go');
	assert.equal(toolResults(h.session)[0].isError, true);
});

test('leaves other tools alone', async () => {
	using h = await start();
	assert.ok((await offeredTools(h)).has('other'));
});
