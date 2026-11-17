import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { mock, test } from 'node:test';
import { extension, type NotifyListener, overrideEnv, packageExtension, startSession, toolResults } from './harness.ts';

const permissionSystem = await packageExtension('@gotgenes/pi-permission-system');

// `*` asks, `mktemp *` and `git add *` are allowed, and the review log is off so a run writes nothing into the fixture
const AGENT_DIR = join(import.meta.dirname, 'fixtures', 'bash-syntax-agent');

// Whether pi-permission-system let this bash command through. With no UI an ask that no link allows is denied, so
// only the link can let an asking command run.
async function passes(command: string) {
	using restoreEnv = overrideEnv({ PI_CODING_AGENT_DIR: AGENT_DIR });
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

// variables that pick the program a later command runs, set by an assignment, a declaration or a loop; paths stay
// inside the project so the external-directory gate, which asks on its own, cannot be what makes these ask
for (const command of [
	'PATH=bin:$PATH',
	'GIT_SSH_COMMAND=ssh',
	'LD_PRELOAD=x.so',
	'export LD_PRELOAD=x.so',
	'export PATH',
	'declare -n p=T',
	'for PATH in bin; do git add a; done',
]) {
	test(`keeps asking for ${command}`, async () => {
		assert.equal(await passes(command), false);
	});
}

test('says so when pi-permission-system published no service', async () => {
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
