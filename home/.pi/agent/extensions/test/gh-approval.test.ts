import assert from 'node:assert/strict';
import { execFile, execFileSync } from 'node:child_process';
import { once } from 'node:events';
import { mkdtempSync, rmSync } from 'node:fs';
import { connect } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { promisify } from 'node:util';
import { extension, overrideEnv, startSession } from './harness.ts';

const execFileAsync = promisify(execFile);

// the stand-in gh the fixture puts on PATH, which answers the login lookup with GH_APPROVAL_LOGIN
const FIXTURES = join(import.meta.dirname, 'fixtures', 'gh-approval');
// the wrapper as the repo holds it, stowed to <agent>/bin/gh by make; the port below is what the session writes
const SHIM = join(import.meta.dirname, '../../bin/gh');
// the session's working directory: not a checkout, so a call that names no repository has none to fall back on
const CWD = '/nonexistent/pi-test/project';

// a checkout carrying the given remotes, which is where gh looks when no argument names a repository
function checkout(remotes: Record<string, string>): Disposable & { path: string } {
	const path = mkdtempSync(join(tmpdir(), 'gh-approval-'));
	execFileSync('git', ['init', '--quiet', path]);
	for (const [name, url] of Object.entries(remotes)) execFileSync('git', ['-C', path, 'remote', 'add', name, url]);
	return { path, [Symbol.dispose]: () => rmSync(path, { force: true, recursive: true }) };
}

// the session announces its gate while starting, which startSession waits for, in the environment its commands
// inherit: this process's
function endpoint(): { host: string; port: number } {
	const [host, port] = (process.env.GH_APPROVAL_ADDR ?? '').split(' ');
	if (host === undefined || port === undefined) throw new Error('gh-approval announced no endpoint');
	return { host, port: Number(port) };
}

type Answer = {
	verdict: string;
	prompts: string[];
	notices: string[];
	stdout?: string;
	stderr?: string;
	code?: number;
};

// the wrapper's side of one call: send cwd, GH_REPO and argv over loopback, and return what came back
async function ask(
	argv: string[],
	options: { cwd?: string; ghRepo?: string; approve?: boolean; login?: string | null } = {},
) {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + process.env.PATH,
		// unset stands in for a gh that is missing or logged out, which the fixture answers by failing
		GH_APPROVAL_LOGIN: options.login === null ? undefined : (options.login ?? 'perrin4869'),
	});
	const answer: Answer = { verdict: '', prompts: [], notices: [] };
	using harness = await startSession({
		extensions: [extension('gh-approval')],
		ui: {
			confirm: (_title, message) => {
				answer.prompts.push(message);
				return Promise.resolve(options.approve ?? false);
			},
			notify: (message) => answer.notices.push(message),
		},
	});
	const socket = connect(endpoint());
	const frames = [options.cwd ?? CWD, options.ghRepo ?? '', String(argv.length), ...argv];
	socket.write(frames.join('\0') + '\0');
	for await (const chunk of socket) answer.verdict += chunk.toString();
	return answer;
}

// the same call through the installed wrapper, which finds the real gh with its own directory dropped from PATH
async function throughShim(argv: string[], options: { approve?: boolean } = {}) {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + process.env.PATH,
		GH_APPROVAL_LOGIN: 'perrin4869',
	});
	const answer: Answer = { verdict: '', prompts: [], notices: [] };
	using harness = await startSession({
		extensions: [extension('gh-approval')],
		ui: {
			confirm: (_title, message) => {
				answer.prompts.push(message);
				return Promise.resolve(options.approve ?? false);
			},
			notify: (message) => answer.notices.push(message),
		},
	});
	const failed = (error: { stdout?: string; stderr?: string; code?: number }) => {
		answer.code = error.code;
		return { stdout: error.stdout ?? '', stderr: error.stderr ?? '' };
	};
	// the wrapper runs in a real directory, since a spawn needs one; every case here names its repository, so the
	// origin there does not decide anything
	const { stdout, stderr } = await execFileAsync(SHIM, argv, { cwd: process.cwd(), env: process.env }).catch(failed);
	return { ...answer, stdout, stderr };
}

test('allows a post to my own repository without asking', async () => {
	const { verdict, prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'perrin4869/dotfiles',
		'--title',
		'T',
		'--body',
		'B',
	]);
	assert.equal(verdict.trim(), 'allow');
	assert.deepEqual(prompts, []);
});

test('asks about another account, and a decline stops gh', async () => {
	const { verdict, prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'ldelossa/pi-ide',
		'--title',
		'T',
		'--body',
		'B',
	]);
	assert.equal(prompts.length, 1);
	assert.match(verdict, /^deny /);
	assert.match(verdict, /nothing was sent/);
});

test('lets an approved post through', async () => {
	const { verdict, prompts } = await ask(
		['issue', 'create', '--repo', 'ldelossa/pi-ide', '--title', 'T', '--body', 'B'],
		{
			approve: true,
		},
	);
	assert.equal(prompts.length, 1);
	assert.equal(verdict.trim(), 'allow');
});

test('asks when the account cannot be resolved', async () => {
	const { verdict, prompts } = await ask(
		['issue', 'create', '--repo', 'perrin4869/dotfiles', '--title', 'T', '--body', 'B'],
		{
			login: null,
		},
	);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: perrin4869\/dotfiles$/m);
	assert.match(verdict, /^deny /);
});

test('shows the repository, title and body it would post', async () => {
	const { prompts } = await ask(
		[
			'issue',
			'create',
			'--repo',
			'ldelossa/pi-ide',
			'--title',
			'Editor block',
			'--body-file',
			join(FIXTURES, 'issue.md'),
		],
		{ approve: false },
	);
	assert.match(prompts[0], /^repository: ldelossa\/pi-ide$/m);
	assert.match(prompts[0], /^title: Editor block$/m);
	assert.match(prompts[0], /^body:$/m);
	assert.match(prompts[0], /Every request rewrites the cache\./);
});

test('shows the file when a call gives both --body and --body-file', async () => {
	// gh sends the file's contents and ignores the inline body
	const { prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'ldelossa/pi-ide',
		'--title',
		'T',
		'--body',
		'inline',
		'--body-file',
		join(FIXTURES, 'issue.md'),
	]);
	// the body block carries the file, whatever the command line also mentions
	assert.match(prompts.join(''), /body:\n## What happens/);
	assert.doesNotMatch(prompts.join(''), /body:\ninline/);
});

test('denies a call whose body file cannot be read, since gh would refuse it', async () => {
	const { verdict, prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'ldelossa/pi-ide',
		'--title',
		'T',
		'--body-file',
		join(FIXTURES, 'missing.md'),
	]);
	assert.deepEqual(prompts, []);
	assert.match(verdict, /^deny /);
	assert.match(verdict, /no such file/);
});

test('asks about a URL even when GH_REPO names my own repository', async () => {
	// gh acts on the URL, so reading GH_REPO here would skip the gate for another account's PR
	const { prompts } = await ask(['pr', 'comment', 'https://github.com/ldelossa/pi-ide/pull/3', '--body', 'hi'], {
		ghRepo: 'perrin4869/dotfiles',
	});
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('takes the URL over a flag, which is what gh does', async () => {
	const { prompts } = await ask([
		'pr',
		'comment',
		'https://github.com/ldelossa/pi-ide/pull/3',
		'--repo',
		'perrin4869/dotfiles',
		'--body',
		'hi',
	]);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('takes the URL over the checkout it runs in', async () => {
	// run from a checkout whose origin is mine, which is where a session actually is
	const { prompts } = await ask(
		['pr', 'comment', 'https://github.com/ldelossa/pi-ide/pull/3', '--repo', 'perrin4869/dotfiles', '--body', 'hi'],
		{ cwd: process.cwd() },
	);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('ignores a URL that is only the value of a flag', async () => {
	const { prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'ldelossa/pi-ide',
		'--title',
		'T',
		'--body',
		'https://github.com/perrin4869/dotfiles',
	]);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('takes the remote gh sorts first, upstream over origin', async () => {
	// gh orders the names upstream, github, origin, and posts to the first, whatever the branch tracks
	using here = checkout({
		origin: 'https://github.com/ldelossa/pi-ide.git',
		upstream: 'https://github.com/perrin4869/dotfiles.git',
	});
	const { verdict, prompts } = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('takes the remote gh repo set-default recorded over the name order', async () => {
	using here = checkout({
		origin: 'https://github.com/ldelossa/pi-ide.git',
		upstream: 'https://github.com/ldelossa/pi-ide.git',
	});
	const config = (...value: string[]) => execFileSync('git', ['-C', here.path, 'config', ...value]);
	// set-default writes "base" on the remote it matched, and a full name on the first sorted remote when it matched none
	config('remote.upstream.gh-resolved', 'perrin4869/dotfiles');
	const typed = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.deepEqual(typed.prompts, []);
	assert.equal(typed.verdict.trim(), 'allow');

	config('--replace-all', 'remote.upstream.gh-resolved', 'base');
	const based = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.equal(based.prompts.length, 1);
	assert.match(based.prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('reads the repository a bare OWNER/REPO positional names', async () => {
	const { prompts } = await ask(['repo', 'create', 'ldelossa/pi-ide', '--description', 'x']);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('allows a URL naming my own repository, whatever GH_REPO says', async () => {
	const { verdict, prompts } = await ask(
		['pr', 'comment', 'https://github.com/perrin4869/dotfiles/pull/1', '--body', 'hi'],
		{ ghRepo: 'perrin4869/dotfiles' },
	);
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('leaves reads alone', async () => {
	for (const argv of [
		['pr', 'view', '6926', '--repo', 'ldelossa/pi-ide'],
		['issue', 'list', '--repo', 'ldelossa/pi-ide'],
		['api', 'repos/ldelossa/pi-ide/issues', '--jq', 'length'],
		['api', 'user', '--jq', '.login'],
	]) {
		const { verdict, prompts } = await ask(argv);
		assert.equal(verdict.trim(), 'allow', argv.join(' '));
		assert.deepEqual(prompts, [], argv.join(' '));
	}
});

test('asks about an api call that writes', async () => {
	const { prompts } = await ask(['api', 'repos/ldelossa/pi-ide/issues/3/comments', '-f', 'body=hello']);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /^repository: ldelossa\/pi-ide$/m);
});

test('asks about a mutation whose repository it cannot name', async () => {
	const { prompts } = await ask(['api', 'graphql', '-f', 'query=mutation { addComment(input: {}) { id } }']);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /^repository: unknown/m);
});

test('asks when the call names the repository by URL or GH_REPO', async () => {
	const url = await ask(['pr', 'comment', 'https://github.com/ldelossa/pi-ide/pull/3', '--body', 'hi']);
	assert.match(url.prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
	const env = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { ghRepo: 'ldelossa/pi-ide' });
	assert.match(env.prompts.join(''), /^repository: ldelossa\/pi-ide$/m);
});

test('the wrapper runs the real gh for my own repository', async () => {
	const { stdout, code, prompts } = await throughShim(['pr', 'view', '1', '--repo', 'perrin4869/dotfiles']);
	assert.equal(code, undefined);
	assert.equal(stdout.trim(), 'perrin4869');
	assert.deepEqual(prompts, []);
});

test('the wrapper stops a declined post before gh runs', async () => {
	const { stdout, stderr, code, prompts } = await throughShim([
		'issue',
		'comment',
		'3',
		'--repo',
		'ldelossa/pi-ide',
		'--body',
		'hi',
	]);
	assert.equal(prompts.length, 1);
	assert.equal(code, 1);
	assert.equal(stdout, '');
	assert.match(stderr, /nothing was sent/);
});

test('refuses when a session is there but does not answer', async () => {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + process.env.PATH,
		// port 1 is never a listener, so the session is named and cannot be reached
		GH_APPROVAL_ADDR: '127.0.0.1 1',
	});
	await assert.rejects(
		execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'perrin4869/dotfiles']),
		(error: { code?: number; stdout?: string; stderr?: string }) => {
			assert.equal(error.code, 1);
			assert.equal(error.stdout, '');
			assert.match(error.stderr ?? '', /the session did not answer/);
			return true;
		},
	);
});

test('refuses when the only gh on PATH is itself', async () => {
	// the link spells the wrapper's directory differently, so dropping it by path would miss this
	using restore = overrideEnv({ PATH: join(FIXTURES, 'link') + ':/usr/bin:/bin' });
	await assert.rejects(
		execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'perrin4869/dotfiles']),
		(error: { code?: number; stderr?: string }) => {
			assert.equal(error.code, 127);
			assert.match(error.stderr ?? '', /the only gh on PATH is this wrapper/);
			return true;
		},
	);
});

test('runs gh with a warning when the session named no endpoint', async () => {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + process.env.PATH,
		GH_APPROVAL_LOGIN: 'perrin4869',
		GH_APPROVAL_ADDR: undefined,
	});
	const { stdout, stderr } = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'perrin4869/dotfiles']);
	assert.equal(stdout.trim(), 'perrin4869');
	assert.match(stderr, /no pi session to ask/);
});

test('drops a client that never finishes its frames', async () => {
	using harness = await startSession({ extensions: [extension('gh-approval')] });
	const socket = connect(endpoint());
	// the server's idle timeout is what closes this, so the wait is as long as TIMEOUT_MS
	await once(socket, 'close', { signal: AbortSignal.timeout(15_000) });
	assert.equal(socket.destroyed, true);
});
