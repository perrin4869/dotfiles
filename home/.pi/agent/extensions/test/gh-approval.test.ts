import { fauxAssistantMessage, fauxToolCall } from '@earendil-works/pi-ai';
import assert from 'node:assert/strict';
import { chmodSync, mkdtempDisposableSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { createHarness, extension, overrideEnv, toolResults } from './harness.ts';

// a `gh` that answers the login lookup from the environment, so the account resolves without a real gh
function fakeGh(login: string | null) {
	const dir = mkdtempDisposableSync(join(tmpdir(), 'gh-approval-'));
	const gh = join(dir.path, 'gh');
	writeFileSync(gh, `#!/bin/sh\n${login === null ? 'exit 1' : `echo '${login}'`}\n`);
	chmodSync(gh, 0o755);
	const restore = overrideEnv({ PATH: `${dir.path}:${process.env.PATH}` });
	return { dir, [Symbol.dispose]: () => restore[Symbol.dispose]() };
}

type Result = { blocked: boolean; prompts: string[] };

// runs one bash call through a real session, with a UI that records what the extension asks. ctx.hasUI follows the
// session mode rather than the bound UI, so the headless path cannot be exercised here; a declined prompt covers it.
async function run(command: string, options: { login?: string | null; approve?: boolean } = {}): Promise<Result> {
	using gh = fakeGh(options.login === undefined ? 'perrin4869' : options.login);
	using harness = await createHarness({ extensions: [extension('gh-approval')] });
	const prompts: string[] = [];
	const ui = harness.session.extensionRunner.getUIContext();
	await harness.session.bindExtensions({
		uiContext: {
			...ui,
			confirm: (_title: string, message: string) => {
				prompts.push(message);
				return Promise.resolve(options.approve ?? false);
			},
		},
		onError: (error) => {
			throw new Error(`${error.extensionPath} failed on ${error.event}`, { cause: error.error });
		},
	});
	harness.respond(
		fauxAssistantMessage(fauxToolCall('bash', { command }), { stopReason: 'toolUse' }),
		fauxAssistantMessage('done'),
	);
	await harness.session.prompt('go');
	const [result] = toolResults(harness.session);
	return { blocked: result.text.includes('needs the exact title and body'), prompts };
}

test('posts to the account own repositories without asking', async () => {
	const { blocked, prompts } = await run('gh pr create --repo perrin4869/dotfiles --title T --body B', {
		approve: true,
	});
	assert.equal(blocked, false);
	assert.deepEqual(prompts, []);
});

test('asks about another account, then lets an approved post through', async () => {
	const { blocked, prompts } = await run('gh issue create --repo ldelossa/pi-ide --title T --body B', {
		approve: true,
	});
	assert.equal(blocked, false);
	assert.equal(prompts.length, 1);
});

test('asks again for the next post when one is declined', async () => {
	const { blocked, prompts } = await run('gh issue comment 3 --repo ldelossa/pi-ide --body-file /dev/null');
	assert.equal(blocked, true);
	assert.equal(prompts.length, 1);
});

test('shows the repository, title and body it would post', async () => {
	using body = mkdtempDisposableSync(join(tmpdir(), 'gh-approval-body-'));
	const file = join(body.path, 'issue.md');
	writeFileSync(file, '## What happens\n\nEvery request rewrites the cache.');
	const { prompts } = await run(`gh issue create --repo ldelossa/pi-ide --title "Editor block" --body-file ${file}`);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /repository: ldelossa\/pi-ide/);
	assert.match(prompts[0], /title: Editor block/);
	assert.match(prompts[0], /## What happens\n\nEvery request rewrites the cache\./);
});

test('leaves reads alone', async () => {
	for (const command of [
		'gh pr view 6926 --repo ldelossa/pi-ide',
		'gh issue list --repo ldelossa/pi-ide',
		'gh api repos/ldelossa/pi-ide/issues --jq length',
		'gh api user --jq .login',
	]) {
		const { blocked, prompts } = await run(command, { approve: true });
		assert.equal(blocked, false, command);
		assert.deepEqual(prompts, [], command);
	}
});

test('asks about an api call that writes', async () => {
	const { blocked, prompts } = await run('gh api repos/ldelossa/pi-ide/issues/3/comments -f body=hello');
	assert.equal(blocked, true);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /repository: ldelossa\/pi-ide/);
});

test('asks when the command names no repository and the checkout has no origin', async () => {
	const { blocked, prompts } = await run('gh pr create --title T --body B');
	assert.equal(blocked, true);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /repository: unknown/);
});

test('asks when the account cannot be resolved', async () => {
	const { blocked } = await run('gh pr create --repo perrin4869/dotfiles --title T --body B', { login: null });
	assert.equal(blocked, true);
});
