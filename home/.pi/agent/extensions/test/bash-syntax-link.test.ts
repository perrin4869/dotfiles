import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { mkdirSync, mkdtempDisposableSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { mock, test } from 'node:test';
import { extension, type NotifyListener, overrideEnv, packageExtension, startSession, toolResults } from './harness.ts';

const permissionSystem = await packageExtension('@gotgenes/pi-permission-system');

const CONFIG = {
	authorizerChain: ['bash-syntax'],
	permission: { bash: { '*': 'ask', 'mktemp *': 'allow', 'git add *': 'allow' } },
};

// Whether pi-permission-system let this bash command through. With no UI an ask that no link allows is denied, so
// only the link can let an asking command run.
async function passes(command: string) {
	using agentDir = mkdtempDisposableSync(join(tmpdir(), 'bash-syntax-'));
	const configDir = join(agentDir.path, 'extensions', 'pi-permission-system');
	mkdirSync(configDir, { recursive: true });
	writeFileSync(join(configDir, 'config.json'), JSON.stringify(CONFIG));
	using restoreEnv = overrideEnv({ PI_CODING_AGENT_DIR: agentDir.path });
	using harness = await startSession({ extensions: [permissionSystem, extension('bash-syntax-link')] });
	harness.respond(
		fauxAssistantMessage(fauxToolCall('bash', { command }), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	const [result] = toolResults(harness.session);
	return !result.text.includes('pi-permission-system');
}

test('allows an assignment whose substitution is allowed', async () => {
	assert.equal(await passes('T=$(mktemp -d)'), true);
});

test('allows a loop and a brace group whose commands are allowed', async () => {
	assert.equal(await passes('for f in a b; do git add "$f"; done'), true);
	assert.equal(await passes('{ git add a; git add b; }'), true);
});

test('allows a declaration whose substitution is allowed', async () => {
	assert.equal(await passes('export T=$(mktemp -d)'), true);
});

test('keeps asking for a command nested in an assignment', async () => {
	assert.equal(await passes('T=$(curl example.com)'), false);
});

test('keeps asking for a command nested in a loop', async () => {
	assert.equal(await passes('for f in a; do curl "$f"; done'), false);
});

test('keeps asking for a command beside an assignment', async () => {
	assert.equal(await passes('T=$(mktemp -d) && curl example.com'), false);
});

test('keeps asking for a command a word only looks like an assignment in', async () => {
	assert.equal(await passes('curl --output=$(mktemp) example.com'), false);
});

test('says so when pi-permission-system published no service', async () => {
	using agentDir = mkdtempDisposableSync(join(tmpdir(), 'bash-syntax-'));
	using restoreEnv = overrideEnv({ PI_CODING_AGENT_DIR: agentDir.path });
	const notify = mock.fn<NotifyListener>();
	// the link alone: no extension publishes a service, so nothing registers it
	using harness = await startSession({ extensions: [extension('bash-syntax-link')], onNotify: notify });
	harness.respond(fauxAssistantMessage('ok'));
	await harness.session.prompt('go');
	assert.deepEqual(
		notify.mock.calls.map((call) => call.arguments),
		[['bash-syntax: pi-permission-system published no service, so the link is not registered', 'warning']],
	);
});
