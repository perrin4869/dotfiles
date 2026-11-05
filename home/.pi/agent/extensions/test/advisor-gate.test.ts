import { fauxAssistantMessage, type FauxResponseFactory, fauxToolCall, getCurrentTools } from '@earendil-works/pi-ai';
import type { ExtensionFactory } from '@earendil-works/pi-coding-agent';
import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { extension, type Harness, type HarnessOptions, startSession, stubTools, toolResults } from './harness.ts';

let harness: Harness | undefined;
afterEach(() => harness?.dispose());

// rpiv-advisor with a reviewer picked: it puts its tool back before every prompt
const rpivAdvisor: ExtensionFactory = (pi) => {
	stubTools('advisor')(pi);
	pi.on('before_agent_start', () => {
		const active = pi.getActiveTools();
		if (!active.includes('advisor')) pi.setActiveTools([...active, 'advisor']);
	});
};

async function start(options: Partial<HarnessOptions> = {}) {
	harness = await startSession({
		extensions: [extension('advisor-gate')],
		factories: [rpivAdvisor, stubTools('other')],
		...options,
	});
	return harness;
}

// the tools offered on each request of a prompt that calls one tool and then finishes
async function offeredTools(options: Partial<HarnessOptions> = {}) {
	const h = await start(options);
	const offered: string[][] = [];
	const recording =
		(reply: ReturnType<typeof fauxAssistantMessage>): FauxResponseFactory =>
		(context) => {
			offered.push(getCurrentTools(context.messages).map((tool) => tool.name));
			return reply;
		};
	h.respond(
		recording(fauxAssistantMessage(fauxToolCall('other', {}), { stopReason: 'toolUse' })),
		recording(fauxAssistantMessage('done')),
	);
	await h.session.prompt('go');
	return offered;
}

const offersAdvisor = async (options?: Partial<HarnessOptions>) =>
	(await offeredTools(options)).map((tools) => tools.includes('advisor'));

const ENABLED = { advisor: { enabled: true } };
const DISABLED = { advisor: { enabled: false } };

test('hides the advisor by default', async () => {
	assert.deepEqual(await offersAdvisor(), [false, false]);
});

test('offers the advisor where the project enables it', async () => {
	assert.deepEqual(await offersAdvisor({ projectSettings: ENABLED }), [true, true]);
});

test('a global enable applies to projects that say nothing', async () => {
	assert.deepEqual(await offersAdvisor({ globalSettings: ENABLED }), [true, true]);
});

test('a project can disable a global enable', async () => {
	assert.deepEqual(await offersAdvisor({ globalSettings: ENABLED, projectSettings: DISABLED }), [false, false]);
});

test('an untrusted project cannot enable the advisor', async () => {
	assert.deepEqual(await offersAdvisor({ projectSettings: ENABLED, projectTrusted: false }), [false, false]);
});

test('an advisor call in a disabled project fails', async () => {
	const h = await start();
	h.respond(fauxAssistantMessage(fauxToolCall('advisor', {}), { stopReason: 'toolUse' }), fauxAssistantMessage('done'));
	await h.session.prompt('go');
	assert.equal(toolResults(h.session)[0].isError, true);
});

test('leaves other tools alone', async () => {
	for (const tools of await offeredTools()) assert.ok(tools.includes('other'));
});
