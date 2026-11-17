import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { mock, test } from 'node:test';
import { Type } from 'typebox';
import { Value } from 'typebox/value';
import { extension, type NotifyListener, overrideEnv, packageExtension, startSession } from './harness.ts';

const permissionSystem = await packageExtension('@gotgenes/pi-permission-system');

// `*` asks, `mktemp *` and `git add *` are allowed, and the review log is off so a run writes nothing into the fixture
const AGENT_DIR = join(import.meta.dirname, 'fixtures', 'bash-syntax-agent');

// the fields of a permissions:decision broadcast these tests read; the package asks consumers to check payloads by field
const Decision = Type.Object({ surface: Type.String(), resolution: Type.String() });

// How pi-permission-system resolved each bash ask this command raised: `authorizer_allowed` when a link let it through,
// `user_denied` when it reached the terminal, which in a session with no dialog refuses every ask.
async function resolutions(command: string) {
	const resolved: string[] = [];
	using restoreEnv = overrideEnv({ PI_CODING_AGENT_DIR: AGENT_DIR });
	using harness = await startSession({
		extensions: [permissionSystem, extension('bash-syntax-link')],
		factories: [
			(pi) => {
				pi.events.on('permissions:decision', (event) => {
					if (Value.Check(Decision, event) && event.surface === 'bash') resolved.push(event.resolution);
				});
			},
		],
	});
	harness.respond(
		fauxAssistantMessage(fauxToolCall('bash', { command }), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	return resolved;
}

test('allows an assignment whose substitution is allowed', async () => {
	assert.deepEqual(await resolutions('T=$(mktemp -d)'), ['authorizer_allowed']);
});

test('allows a loop and a brace group whose commands are allowed', async () => {
	assert.deepEqual(await resolutions('for f in a b; do git add "$f"; done'), ['authorizer_allowed']);
	assert.deepEqual(await resolutions('{ git add a; git add b; }'), ['authorizer_allowed']);
});

test('allows a declaration whose substitution is allowed', async () => {
	assert.deepEqual(await resolutions('export T=$(mktemp -d)'), ['authorizer_allowed']);
});

// one per statement the link reads from the grammar, plus quotes inside a substitution, which a tokenizer splits on
for (const command of [
	'( git add a )',
	'if true; then git add a; fi',
	'[[ -f a ]]',
	'foo() { git add a; }',
	'unset T',
	'cd a',
	'T="$(mktemp -p "a b")"',
]) {
	test(`allows ${command}`, async () => {
		assert.deepEqual(await resolutions(command), ['authorizer_allowed']);
	});
}

test('keeps asking for a command nested in an assignment', async () => {
	assert.deepEqual(await resolutions('T=$(curl example.com)'), ['user_denied']);
});

test('keeps asking for a command nested in a loop', async () => {
	assert.deepEqual(await resolutions('for f in a; do curl "$f"; done'), ['user_denied']);
});

test('keeps asking for a command beside an assignment', async () => {
	assert.deepEqual(await resolutions('T=$(mktemp -d) && curl example.com'), ['user_denied']);
});

test('keeps asking for a command a word only looks like an assignment in', async () => {
	assert.deepEqual(await resolutions('curl --output=$(mktemp) example.com'), ['user_denied']);
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
		assert.deepEqual(await resolutions(command), ['user_denied']);
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
