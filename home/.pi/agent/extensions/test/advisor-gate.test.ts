import { fauxAssistantMessage, fauxToolCall, getCurrentTools } from '@earendil-works/pi-ai';
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
		return Promise.resolve();
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

// the tools the model is offered on each request of a prompt
async function offeredTools(options: Partial<HarnessOptions> = {}) {
	const h = await start(options);
	const offered: string[][] = [];
	const record = (messages: { role: string }[]) => offered.push(getCurrentTools(messages).map((tool) => tool.name));
	h.respond(
		(context) => {
			record(context.messages);
			return fauxAssistantMessage(fauxToolCall('other', {}), { stopReason: 'toolUse' });
		},
		(context) => {
			record(context.messages);
			return fauxAssistantMessage('done');
		},
	);
	await h.session.prompt('go');
	return offered;
}

const ENABLED = { advisor: { enabled: true } };
const DISABLED = { advisor: { enabled: false } };

test('hides the advisor by default', async () => {
	for (const tools of await offeredTools()) assert.ok(!tools.includes('advisor'), tools.join());
});

test('offers the advisor where the project enables it', async () => {
	for (const tools of await offeredTools({ projectSettings: ENABLED })) assert.ok(tools.includes('advisor'));
});

test('a global enable applies to projects that say nothing', async () => {
	for (const tools of await offeredTools({ globalSettings: ENABLED })) assert.ok(tools.includes('advisor'));
});

test('a project can disable a global enable', async () => {
	const offered = await offeredTools({ globalSettings: ENABLED, projectSettings: DISABLED });
	for (const tools of offered) assert.ok(!tools.includes('advisor'));
});

test('an advisor call in a disabled project fails', async () => {
	const h = await start();
	h.respond(fauxAssistantMessage(fauxToolCall('advisor', {}), { stopReason: 'toolUse' }), fauxAssistantMessage('done'));
	await h.session.prompt('go');
	const [result] = toolResults(h.session);
	assert.equal(result.isError, true);
});

test('leaves other tools alone', async () => {
	for (const tools of await offeredTools()) assert.ok(tools.includes('other'));
});
