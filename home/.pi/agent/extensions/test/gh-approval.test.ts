import assert from 'node:assert/strict';
import { execFile, execFileSync } from 'node:child_process';
import { once } from 'node:events';
import { existsSync, statSync } from 'node:fs';
import { mkdtempDisposable } from 'node:fs/promises';
import { connect } from 'node:net';
import { tmpdir } from 'node:os';
import { basename, dirname, join } from 'node:path';
import { cwd, env } from 'node:process';
import { test } from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';
import { promisify } from 'node:util';
import { overrideEnv } from '#lib/env';
import { type BindOptions, extension, startSession } from './harness.ts';

const execFileAsync = promisify(execFile);

// the stand-in gh the fixture puts on PATH, which answers the login lookup with GH_APPROVAL_LOGIN
const FIXTURES = join(import.meta.dirname, 'fixtures', 'gh-approval');
// the wrapper as the repo holds it, stowed to <agent>/bin/gh by make
const SHIM = join(import.meta.dirname, '../../bin/gh');
// the session's working directory: not a checkout, so a call that names no repository has none to fall back on
const CWD = '/nonexistent/pi-test/project';

// a checkout carrying the given remotes, which is where gh looks when no argument names a repository
async function checkout(remotes: Record<string, string>) {
	// removes the directory if setting it up fails
	await using cleanup = new AsyncDisposableStack();
	const dir = cleanup.use(await mkdtempDisposable(join(tmpdir(), 'gh-approval-')));
	await execFileAsync('git', ['init', '--quiet', dir.path]);
	// git holds config.lock while it writes and waits for one another holds, so the adds can overlap
	await Promise.all(
		Object.entries(remotes).map(([name, url]) => execFileAsync('git', ['-C', dir.path, 'remote', 'add', name, url])),
	);
	cleanup.move();
	return dir;
}

// set while the session starts, which startSession waits for
function socket(): string {
	const path = env.GH_APPROVAL_SOCKET;
	if (path === undefined) throw new Error('gh-approval announced no socket');
	return path;
}

async function start(ui?: BindOptions['ui']) {
	await using stack = new AsyncDisposableStack();
	// a runtime directory per session, so the tests neither use the host's nor leave sockets in it
	const dir = stack.use(await mkdtempDisposable(join(tmpdir(), 'gh-approval-runtime-')));
	// the fixture gh answers the account lookup, and the socket this process inherited is the outer session's, not ours
	stack.use(
		overrideEnv({
			XDG_RUNTIME_DIR: dir.path,
			PATH: join(FIXTURES, 'bin') + ':' + env.PATH,
			GH_APPROVAL_SOCKET: undefined,
		}),
	);
	stack.use(await startSession({ extensions: [extension('gh-approval')], ui }));
	return stack.move();
}

// a started session that records what it shows, with the fixture gh on PATH and alice holding the token; the caller
// owns both, which is what the wrapper tests need to be alive while they run it
async function boot(options: { approve?: boolean; login?: string | null } = {}) {
	const prompts: string[] = [];
	const notices: string[] = [];
	await using cleanup = new AsyncDisposableStack();
	cleanup.use(
		overrideEnv({
			// unset stands in for a gh that is missing or logged out, which the fixture answers by failing
			GH_APPROVAL_LOGIN: options.login === null ? undefined : (options.login ?? 'alice'),
		}),
	);
	cleanup.use(
		await start({
			confirm: (_title, message) => {
				prompts.push(message);
				return Promise.resolve(options.approve ?? false);
			},
			notify: (message) => notices.push(message),
		}),
	);
	return Object.assign(cleanup.move(), { prompts, notices });
}

// one call's frames to a socket, and the line that comes back
async function send(path: string, argv: string[], options: { cwd?: string; ghRepo?: string } = {}) {
	const connection = connect(path);
	const frames = [options.cwd ?? CWD, options.ghRepo ?? '', String(argv.length), ...argv];
	connection.write(frames.join('\0') + '\0');
	let verdict = '';
	for await (const chunk of connection) verdict += chunk.toString();
	return verdict;
}

// the wrapper's side of one call, against the session's socket
async function ask(
	argv: string[],
	options: { cwd?: string; ghRepo?: string; approve?: boolean; login?: string | null } = {},
) {
	await using booted = await boot(options);
	return { prompts: booted.prompts, notices: booted.notices, verdict: await send(socket(), argv, options) };
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
	await using here = await checkout({ origin: 'https://github.com/alice/dotfiles.git' });
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
	await using here = await checkout({
		origin: 'https://github.com/bob/widgets.git',
		upstream: 'https://github.com/alice/dotfiles.git',
	});
	const { verdict, prompts } = await ask(['issue', 'create', '--title', 'T', '--body', 'B'], { cwd: here.path });
	assert.deepEqual(prompts, []);
	assert.equal(verdict.trim(), 'allow');
});

test('takes the remote gh repo set-default recorded over the name order', async () => {
	await using here = await checkout({
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
	await using here = await checkout({ origin: 'https://github.com/alice/dotfiles.git' });
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
	await using here = await checkout({ origin: 'https://github.com/alice/dotfiles.git' });
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
	await using harness = await start();
	const connection = connect(socket());
	// the cwd and GH_REPO frames, with the count and the arguments still to come
	connection.write([CWD, '', ''].join('\0'));
	// the server's idle timeout is what ends this, so the wait lasts as long as TIMEOUT_MS, and no answer arrives
	await once(connection, 'close', { signal: AbortSignal.timeout(15_000) });
	assert.equal(connection.read(), null);
});

test('answers one call while another waits on its dialog', async () => {
	const opened = Promise.withResolvers<void>();
	const answer = Promise.withResolvers<boolean>();
	await using harness = await start({
		confirm: () => {
			opened.resolve();
			return answer.promise;
		},
	});
	// a failed assertion must not leave the dialog open: its connection would hold the run alive
	using decided = { [Symbol.dispose]: () => answer.resolve(false) };
	// a post whose dialog stays open until this test closes it, and a read that must not wait behind it
	const asked = send(socket(), ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi']);
	await opened.promise;
	assert.equal((await send(socket(), ['pr', 'view', '1', '--repo', 'bob/widgets'])).trim(), 'allow');
	answer.resolve(false);
	assert.match(await asked, /^deny /);
});

test('dismisses a dialog whose gh call went away', async () => {
	using restore = overrideEnv({ GH_APPROVAL_LOGIN: 'alice' });
	const opened = Promise.withResolvers<void>();
	const noticed = Promise.withResolvers<string>();
	// bounded, so a dialog that is never dismissed fails the test instead of holding the session open
	setTimeout(() => noticed.reject(new Error('the dialog was never dismissed')), 5_000).unref();
	await using harness = await start({
		confirm: (_title, _message, options) => {
			opened.resolve();
			// pi answers a dismissed dialog with no
			return once(options!.signal!, 'abort').then(() => false);
		},
		notify: (message) => noticed.resolve(message),
	});
	const connection = connect(socket());
	const argv = ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi'];
	connection.write([CWD, '', String(argv.length), ...argv].join('\0') + '\0');
	await opened.promise;
	connection.destroy();
	assert.match(await noticed.promise, /the gh call ended before it was answered/);
});

test('gives each session a socket of its own', async () => {
	await using first = await boot();
	const one = socket();
	await using second = await boot();
	const two = socket();
	// each session here has its own runtime directory, so compare the names, which must differ in a shared one
	assert.notEqual(basename(one), basename(two));
});

test('makes a private directory for its socket when there is no runtime directory', async () => {
	const notices: string[] = [];
	let dir = '';
	{
		using restore = overrideEnv({ XDG_RUNTIME_DIR: undefined });
		await using harness = await startSession({
			extensions: [extension('gh-approval')],
			ui: { notify: (message) => notices.push(message) },
		});
		dir = dirname(socket());
		// only this user may connect: nothing in the protocol tells a peer from the wrapper
		assert.equal(statSync(dir).mode & 0o777, 0o700);
		assert.match(notices.join('\n'), /XDG_RUNTIME_DIR is not set/);
	}
	assert.equal(existsSync(dir), false);
});

test('takes the socket away with the session', async () => {
	let path = '';
	{
		await using harness = await start();
		path = socket();
		assert.ok(existsSync(path));
	}
	assert.equal(existsSync(path), false);
});

// the wrapper is a bash script, so these spawn it the way git does: a child process, handed the environment the session
// published, with none of the session in-process. What they can assert is what the script alone produces, which the
// session-side tests above cannot see: the PATH walk, the exit code, stderr, and the stdout of the gh it execs. All but
// the last boot a session for it to dial; the last one covers the branch where no session named an endpoint.

test('the wrapper runs the real gh for my own repository', async () => {
	await using booted = await boot();
	// a spawn needs a real directory, and every case here names its repository, so the origin there decides nothing
	const { stdout } = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles'], {
		cwd: cwd(),
		env,
	});
	assert.equal(stdout.trim(), 'alice');
	assert.deepEqual(booted.prompts, []);
});

test('answers each call of a session on its own', async () => {
	await using booted = await boot();
	// the post has to ask, and the read after it is allowed without a word; a denial left over for the second call would
	// end it with exit 1 instead
	await assert.rejects(
		execFileAsync(SHIM, ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi'], { cwd: cwd(), env }),
		{ code: 1 },
	);
	// the post is the one that asks
	assert.equal(booted.prompts.length, 1);
	const read = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles'], { cwd: cwd(), env });
	assert.equal(read.stdout.trim(), 'alice');
	// and the read after it asks nothing
	assert.equal(booted.prompts.length, 1);
});

test('the wrapper stops a declined post before gh runs', async () => {
	await using booted = await boot();
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

test('the wrapper waits for a dialog however long it takes', async () => {
	using restore = overrideEnv({ GH_APPROVAL_LOGIN: 'alice' });
	// longer than socat's default half-second wait
	await using harness = await start({ confirm: () => delay(1000, true) });
	const { stdout } = await execFileAsync(SHIM, ['issue', 'comment', '3', '--repo', 'bob/widgets', '--body', 'hi'], {
		cwd: cwd(),
		env,
	});
	assert.equal(stdout.trim(), 'alice');
});

test('refuses when a session is there but does not answer', async () => {
	using restore = overrideEnv({
		PATH: join(FIXTURES, 'bin') + ':' + env.PATH,
		// a path nothing listens on, so the session is named and cannot be reached
		GH_APPROVAL_SOCKET: join(tmpdir(), 'gh-approval-nothing.sock'),
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
		GH_APPROVAL_SOCKET: undefined,
	});
	const { stdout, stderr } = await execFileAsync(SHIM, ['pr', 'view', '1', '--repo', 'alice/dotfiles']);
	assert.equal(stdout.trim(), 'alice');
	assert.match(stderr, /no pi session to ask/);
});
