import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { join } from 'node:path';
import { mock, test } from 'node:test';
import { Type } from 'typebox';
import { Value } from 'typebox/value';
import { overrideEnv } from '#lib/env';
import { extension, type NotifyListener, packageExtension, startSession } from './harness.ts';

const permissionSystem = await packageExtension('@gotgenes/pi-permission-system');

// `*` asks, `mktemp *` and `git add *` are allowed, and the review log is off so a run writes nothing into the fixture
const AGENT_DIR = join(import.meta.dirname, 'fixtures', 'bash-syntax-agent');

// the fields of a permissions:decision broadcast these tests read; the package asks consumers to check payloads by field
const Decision = Type.Object({ surface: Type.String(), resolution: Type.String() });

// what a prompt asked about: the unit it will run, and the other units of the chain its answer also covers
const Prompt = Type.Object({
	surface: Type.Union([Type.String(), Type.Null()]),
	value: Type.Union([Type.String(), Type.Null()]),
	request: Type.Object({ otherAskingUnits: Type.Optional(Type.Array(Type.String())) }),
});

type Ask = {
	// `authorizer_allowed` when a link let an ask through, `user_denied` when it reached the terminal, which in a
	// session with no dialog refuses every ask
	resolutions: string[];
	prompts: { value: string | null; others: string[] | undefined }[];
};

// one bash command through a real session with the permission system and the link, recording how each ask ended and
// what the dialog would have asked about
async function ask(command: string): Promise<Ask> {
	const asked: Ask = { resolutions: [], prompts: [] };
	using restoreEnv = overrideEnv({ PI_CODING_AGENT_DIR: AGENT_DIR });
	await using harness = await startSession({
		extensions: [permissionSystem, extension('bash-syntax-link')],
		factories: [
			(pi) => {
				pi.events.on('permissions:decision', (event) => {
					if (Value.Check(Decision, event) && event.surface === 'bash') asked.resolutions.push(event.resolution);
				});
				pi.events.on('permissions:ui_prompt', (event) => {
					if (Value.Check(Prompt, event) && event.surface === 'bash') {
						asked.prompts.push({ value: event.value, others: event.request.otherAskingUnits });
					}
				});
			},
		],
	});
	harness.respond(
		fauxAssistantMessage(fauxToolCall('bash', { command }), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	return asked;
}

test('allows an assignment whose substitution is allowed', async () => {
	assert.deepEqual((await ask('T=$(mktemp -d)')).resolutions, ['authorizer_allowed']);
});

test('allows a loop and a brace group whose commands are allowed', async () => {
	assert.deepEqual((await ask('for f in a b; do git add "$f"; done')).resolutions, ['authorizer_allowed']);
	assert.deepEqual((await ask('{ git add a; git add b; }')).resolutions, ['authorizer_allowed']);
});

test('allows a declaration whose substitution is allowed', async () => {
	assert.deepEqual((await ask('export T=$(mktemp -d)')).resolutions, ['authorizer_allowed']);
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
		assert.deepEqual((await ask(command)).resolutions, ['authorizer_allowed']);
	});
}

test('keeps asking for a command nested in an assignment', async () => {
	assert.deepEqual((await ask('T=$(curl example.com)')).resolutions, ['user_denied']);
});

test('keeps asking for a command nested in a loop', async () => {
	assert.deepEqual((await ask('for f in a; do curl "$f"; done')).resolutions, ['user_denied']);
});

test('keeps asking for a command beside an assignment', async () => {
	assert.deepEqual((await ask('T=$(mktemp -d) && curl example.com')).resolutions, ['user_denied']);
});

test('settles the syntax half of a chain, leaving the prompt about the command alone', async () => {
	const { prompts } = await ask('T=$(mktemp -d) && curl example.com');
	assert.deepEqual(prompts, [{ value: 'curl example.com', others: undefined }]);
});

test('settles every syntax unit of a chain before the prompt', async () => {
	const { prompts } = await ask('A=$(mktemp -d) && B=$(mktemp -d) && curl example.com');
	assert.deepEqual(prompts, [{ value: 'curl example.com', others: undefined }]);
});

test('keeps asking for a command a word only looks like an assignment in', async () => {
	assert.deepEqual((await ask('curl --output=$(mktemp) example.com')).resolutions, ['user_denied']);
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
		assert.deepEqual((await ask(command)).resolutions, ['user_denied']);
	});
}

test('says so when pi-permission-system published no service', async () => {
	const notify = mock.fn<NotifyListener>();
	// the link alone: no extension publishes a service, so nothing registers it
	await using harness = await startSession({ extensions: [extension('bash-syntax-link')], ui: { notify } });
	harness.respond(fauxAssistantMessage('ok'));
	await harness.session.prompt('go');
	assert.deepEqual(
		notify.mock.calls.map((call) => call.arguments),
		[['bash-syntax: pi-permission-system published no service, so the link is not registered', 'warning']],
	);
});
