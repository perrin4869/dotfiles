import assert from 'node:assert/strict';
import { execFile, execFileSync } from 'node:child_process';
import { once } from 'node:events';
import { mkdtempSync, rmSync } from 'node:fs';
import { connect } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { cwd, env } from 'node:process';
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
	const [host, port] = (env.GH_APPROVAL_ADDR ?? '').split(' ');
	if (host === undefined || port === undefined) throw new Error('gh-approval announced no endpoint');
	return { host, port: Number(port) };
}

// a started session that records what it shows, with the fixture gh on PATH and alice holding the token; the caller
// owns both, which is what the wrapper tests need to be alive while they run it
async function boot(options: { approve?: boolean; login?: string | null } = {}) {
	const prompts: string[] = [];
	const notices: string[] = [];
	using cleanup = new DisposableStack();
	cleanup.use(
		overrideEnv({
			PATH: join(FIXTURES, 'bin') + ':' + env.PATH,
			// unset stands in for a gh that is missing or logged out, which the fixture answers by failing
			GH_APPROVAL_LOGIN: options.login === null ? undefined : (options.login ?? 'alice'),
		}),
	);
	cleanup.use(
		await startSession({
			extensions: [extension('gh-approval')],
			ui: {
				confirm: (_title, message) => {
					prompts.push(message);
					return Promise.resolve(options.approve ?? false);
				},
				notify: (message) => notices.push(message),
			},
		}),
	);
	const owned = cleanup.move();
	return { prompts, notices, [Symbol.dispose]: () => owned.dispose() };
}

// the wrapper's side of one call: send cwd, GH_REPO and argv over loopback, and return the line that came back
async function ask(
	argv: string[],
	options: { cwd?: string; ghRepo?: string; approve?: boolean; login?: string | null } = {},
) {
	using booted = await boot(options);
	const socket = connect(endpoint());
	const frames = [options.cwd ?? CWD, options.ghRepo ?? '', String(argv.length), ...argv];
	socket.write(frames.join('\0') + '\0');
	let verdict = '';
	for await (const chunk of socket) verdict += chunk.toString();
	return { prompts: booted.prompts, notices: booted.notices, verdict };
}

test('allows a post to my own repository without asking', async () => {
	const { verdict, prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'alice/dotfiles',
		'--title',
		'T',
		'--body',
		'B',
	]);
	assert.equal(verdict.trim(), 'allow');
	assert.deepEqual(prompts, []);
});

test('asks about another account, and a decline stops gh', async () => {
	const { verdict, prompts } = await ask(['issue', 'create', '--repo', 'bob/widgets', '--title', 'T', '--body', 'B']);
	assert.equal(prompts.length, 1);
	assert.match(verdict, /^deny /);
	assert.match(verdict, /nothing was sent/);
});

test('lets an approved post through', async () => {
	const { verdict, prompts } = await ask(['issue', 'create', '--repo', 'bob/widgets', '--title', 'T', '--body', 'B'], {
		approve: true,
	});
	assert.equal(prompts.length, 1);
	assert.equal(verdict.trim(), 'allow');
});

test('asks when the account cannot be resolved', async () => {
	const { verdict, prompts, notices } = await ask(
		['issue', 'create', '--repo', 'alice/dotfiles', '--title', 'T', '--body', 'B'],
		{
			login: null,
		},
	);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: alice\/dotfiles$/m);
	// the lookup failed, so the dialog cannot say whether this is my repository, and the session says why
	assert.match(notices.join(''), /cannot tell which account the token belongs to/);
	assert.match(verdict, /^deny /);
});

test('shows the repository, title and body it would post', async () => {
	const { prompts } = await ask(
		['issue', 'create', '--repo', 'bob/widgets', '--title', 'Editor block', '--body-file', join(FIXTURES, 'issue.md')],
		{ approve: false },
	);
	assert.match(prompts[0], /^repository: bob\/widgets$/m);
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
		'bob/widgets',
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
		'bob/widgets',
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
	const { prompts } = await ask(['pr', 'comment', 'https://github.com/bob/widgets/pull/3', '--body', 'hi'], {
		ghRepo: 'alice/dotfiles',
	});
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: bob\/widgets$/m);
});

test('takes the URL over a flag, which is what gh does', async () => {
	const { prompts } = await ask([
		'pr',
		'comment',
		'https://github.com/bob/widgets/pull/3',
		'--repo',
		'alice/dotfiles',
		'--body',
		'hi',
	]);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: bob\/widgets$/m);
});

test('takes the URL over the checkout it runs in', async () => {
	// the checkout names a repository of my own, which the URL would otherwise let this post to without asking
	using here = checkout({ origin: 'https://github.com/alice/dotfiles.git' });
	const { prompts } = await ask(['pr', 'comment', 'https://github.com/bob/widgets/pull/3', '--body', 'hi'], {
		cwd: here.path,
	});
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: bob\/widgets$/m);
});

test('ignores a URL that is only the value of a flag', async () => {
	const { prompts } = await ask([
		'issue',
		'create',
		'--repo',
		'bob/widgets',
		'--title',
		'T',
		'--body',
		'https://github.com/alice/dotfiles',
	]);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: bob\/widgets$/m);
});

test('takes the remote gh sorts first, upstream over origin', async () => {
	// gh orders the names upstream, github, origin, and posts to the first, whatever the branch tracks
	using here = checkout({
		origin: 'https://github.com/bob/widgets.git',
		upstream: 'https://github.com/alice/dotfiles.git',
	});
	const { verdict, prompts } = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('takes the remote gh repo set-default recorded over the name order', async () => {
	using here = checkout({
		origin: 'https://github.com/bob/widgets.git',
		upstream: 'https://github.com/bob/widgets.git',
	});
	const config = (...value: string[]) => execFileSync('git', ['-C', here.path, 'config', ...value]);
	// set-default writes "base" on the remote it matched, and a full name on the first sorted remote when it matched none
	config('remote.upstream.gh-resolved', 'alice/dotfiles');
	const typed = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.deepEqual(typed.prompts, []);
	assert.equal(typed.verdict.trim(), 'allow');

	config('--replace-all', 'remote.upstream.gh-resolved', 'base');
	const based = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.equal(based.prompts.length, 1);
	assert.match(based.prompts.join(''), /^repository: bob\/widgets$/m);
});

test('reads the repository a bare OWNER/REPO positional names', async () => {
	const { prompts } = await ask(['repo', 'create', 'bob/widgets', '--description', 'x']);
	assert.equal(prompts.length, 1);
	assert.match(prompts.join(''), /^repository: bob\/widgets$/m);
});

test('allows a URL naming my own repository, whatever GH_REPO says', async () => {
	// GH_REPO names another account, so it would have to ask if it answered for this call at all
	const { verdict, prompts } = await ask(
		['pr', 'comment', 'https://github.com/alice/dotfiles/pull/1', '--body', 'hi'],
		{ ghRepo: 'bob/widgets' },
	);
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('leaves reads alone', async () => {
	for (const argv of [
		['pr', 'view', '6926', '--repo', 'bob/widgets'],
		['issue', 'list', '--repo', 'bob/widgets'],
		['api', 'repos/bob/widgets/issues', '--jq', 'length'],
		['api', 'user', '--jq', '.login'],
	]) {
		const { verdict, prompts } = await ask(argv);
		assert.equal(verdict.trim(), 'allow', argv.join(' '));
		assert.deepEqual(prompts, [], argv.join(' '));
	}
});

test('asks about an api call that writes', async () => {
	const { prompts } = await ask(['api', 'repos/bob/widgets/issues/3/comments', '-f', 'body=hello']);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /^repository: bob\/widgets$/m);
});

test('reads GH_REPO as the repository an api placeholder path fills in', async () => {
	const { prompts } = await ask(['api', 'repos/{owner}/{repo}/issues', '-f', 'title=T'], { ghRepo: 'bob/widgets' });
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /^repository: bob\/widgets$/m);
});

test('asks about a mutation whatever is around it', async () => {
	// the subject is a node id inside the query, and gh resolves nothing for a graphql endpoint, so neither GH_REPO nor
	// the checkout this runs in answers for it
	using here = checkout({ origin: 'https://github.com/alice/dotfiles.git' });
	const { prompts } = await ask(
		[
			'api',
			'graphql',
			'-f',
			'query=mutation { addComment(input: {subjectId: "I_kwDOABCD1234", body: "hi"}) { clientMutationId } }',
		],
		{ cwd: here.path, ghRepo: 'alice/dotfiles' },
	);
	assert.equal(prompts.length, 1);
	assert.match(prompts[0], /^repository: unknown/m);
	// what the reader is shown, which is all the gate knows: the node id, with no repository to compare
	assert.match(prompts[0], /subjectId: "I_kwDOABCD1234"/);
});

test('reads an api placeholder path as the repository gh fills in', async () => {
	using here = checkout({ origin: 'https://github.com/alice/dotfiles.git' });
	const { verdict, prompts } = await ask(['api', 'repos/{owner}/{repo}/issues', '-f', 'title=T'], { cwd: here.path });
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('asks when the call names the repository by URL or GH_REPO', async () => {
	const url = await ask(['pr', 'comment', 'https://github.com/bob/widgets/pull/3', '--body', 'hi']);
	assert.match(url.prompts.join(''), /^repository: bob\/widgets$/m);
	const fromEnv = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { ghRepo: 'bob/widgets' });
	assert.match(fromEnv.prompts.join(''), /^repository: bob\/widgets$/m);
});

test('drops a client that never finishes its frames', async () => {
	using harness = await startSession({ extensions: [extension('gh-approval')] });
	const socket = connect(endpoint());
	// the cwd and GH_REPO frames, with the count and the arguments still to come
	socket.write([CWD, '', ''].join('\0'));
	// the server's idle timeout is what ends this, so the wait lasts as long as TIMEOUT_MS, and no answer arrives
	await once(socket, 'close', { signal: AbortSignal.timeout(15_000) });
	assert.equal(socket.read(), null);
});

// the wrapper is a bash script, so these spawn it the way git does: a child process, handed the environment the session
// published, with none of the session in-process. What they can assert is what the script alone produces, which the
// session-side tests above cannot see: the PATH walk, the exit code, stderr, and the stdout of the gh it execs. All but
// the last boot a session for it to dial; the last one covers the branch where no session named an endpoint.

test('the wrapper runs the real gh for my own repository', async () => {
	using booted = await boot();
	// a spawn needs a real directory, and every case here names its repository, so the origin there decides nothing
	const { stdout } = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles'], {
		cwd: cwd(),
		env,
	});
	assert.equal(stdout.trim(), 'alice');
	assert.deepEqual(booted.prompts, []);
});

test('answers each call of a session on its own', async () => {
	using booted = await boot();
	// the read is allowed without a word; the post after it has to ask, so it would inherit the wrong answer if the frames
	// of one call were still on hand for the next
	const read = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles'], {
		cwd: cwd(),
		env,
	});
	assert.equal(read.stdout.trim(), 'alice');
	await assert.rejects(
		execFileAsync(SHIM, ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi'], {
			cwd: cwd(),
			env,
		}),
		(error: { code?: number; stderr?: string }) => {
			assert.equal(error.code, 1);
			assert.match(error.stderr ?? '', /nothing was sent/);
			return true;
		},
	);
	assert.equal(booted.prompts.length, 1);
});

test('the wrapper stops a declined post before gh runs', async () => {
	using booted = await boot();
	await assert.rejects(
		execFileAsync(SHIM, ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi'], {
			cwd: cwd(),
			env,
		}),
		(error: { code?: number; stdout?: string; stderr?: string }) => {
			assert.equal(error.code, 1);
			assert.equal(error.stdout, '');
			assert.match(error.stderr ?? '', /nothing was sent/);
			return true;
		},
	);
	assert.equal(booted.prompts.length, 1);
});

test('refuses when a session is there but does not answer', async () => {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + env.PATH,
		// port 1 is never a listener, so the session is named and cannot be reached
		GH_APPROVAL_ADDR: '127.0.0.1 1',
	});
	await assert.rejects(
		execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles']),
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
		execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles']),
		(error: { code?: number; stderr?: string }) => {
			assert.equal(error.code, 127);
			assert.match(error.stderr ?? '', /the only gh on PATH is this wrapper/);
			return true;
		},
	);
});

test('runs gh with a warning when the session named no endpoint', async () => {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + env.PATH,
		GH_APPROVAL_LOGIN: 'alice',
		GH_APPROVAL_ADDR: undefined,
	});
	const { stdout, stderr } = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles']);
	assert.equal(stdout.trim(), 'alice');
	assert.match(stderr, /no pi session to ask/);
});
