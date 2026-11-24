import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFile } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { once } from 'node:events';
import { constants } from 'node:fs';
import { access, mkdtempDisposable, readFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { homedir, tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { env } from 'node:process';
import { parseArgs, promisify } from 'node:util';
import { overrideEnv } from '#lib/env';
import { memo } from '#lib/memo';
import { sessionScope } from '#lib/session-scope';

const execFileAsync = promisify(execFile);

// a post outside my GitHub account needs the exact title and body shown and an approval for that one post. A line of
// AGENTS.md would be advisory, and the wrapper hands over gh's real argv, so the gate asks here instead
const RULE = 'posting outside my GitHub account needs the exact title and body shown and an approval for that one post';

// the gh groups whose subcommands write something others can see, and the actions that do
const GROUPS = new Set(['issue', 'pr', 'release', 'repo']);
const WRITE_ACTIONS = new Set(['create', 'edit', 'comment', 'close', 'reopen', 'delete', 'review', 'merge', 'upload']);
// an api call with one of these methods, or with a request body, changes something; anything else reads
const WRITE_METHODS = new Set(['POST', 'PATCH', 'PUT', 'DELETE']);

// gh reuses -F for --body-file on issue and pr and for --field on api, so the table holds both and the group picks
// what the groups other than api send, and the file gh reads the body from
const COMMAND_OPTIONS = {
	repo: { type: 'string', short: 'R' },
	title: { type: 'string', short: 't' },
	body: { type: 'string', short: 'b' },
	'body-file': { type: 'string' },
	field: { type: 'string', short: 'F', multiple: true },
} as const;

// what gh api sends: the method, and the three ways it carries a request body
const API_OPTIONS = {
	method: { type: 'string', short: 'X' },
	field: { type: 'string', short: 'F', multiple: true },
	'raw-field': { type: 'string', short: 'f', multiple: true },
	input: { type: 'string' },
} as const;

// nothing in the gate may hang the session: a bind that never settles and a client that never finishes its frames
// both give up after this
const TIMEOUT_MS = 10_000;

const API_PATH = /(?:^|\/)repos\/([^/\s]+)\/([^/\s?#]+)/;
const GITHUB_HOST = 'github.com';

/** one gh call as the wrapper sends it: the directory it runs in, its argv, and the repository GH_REPO named */
type Call = { cwd: string; argv: string[]; ghRepo?: string };

type Post = {
	/** the repository the post goes to: the one the call names, or the one this checkout would push to */
	repo?: string;
	title?: string;
	body?: string;
	/** the body file, resolved against the directory the call runs in */
	bodyFile?: string;
};

// the agent directory the wrapper reads from too, overridable the way pi is
const agentDir = () => env.PI_CODING_AGENT_DIR ?? join(homedir(), '.pi', 'agent');
// pi puts the wrapper's directory first on the PATH of the commands it runs, and nothing else does
const shimDir = () => join(agentDir(), 'bin');

// the real gh, with the directory holding the wrapper dropped, so the gate never ends up calling itself. A missing gh
// is not an answer but a reason the account cannot be read, so it throws like one. The search runs once, in PATH order,
// because the first entry is the one a shell would run.
const realGh = memo(async (): Promise<string> => {
	for (const dir of (env.PATH ?? '').split(':')) {
		if (dir === shimDir()) continue;
		const candidate = join(dir, 'gh');
		try {
			await access(candidate, constants.X_OK);
			return candidate;
		} catch {
			// not here
		}
	}
	throw new Error('no gh on PATH');
});

/** owner and repository from a host and a path, when the host is github.com */
function githubRepo(host: string, path: string): string | undefined {
	if (host.toLowerCase() !== GITHUB_HOST) return undefined;
	const [owner, repo] = path
		.replace(/^\/+/, '')
		.replace(/\.git$/, '')
		.split('/');
	return owner !== undefined && repo !== undefined ? owner + '/' + repo : undefined;
}

/** the repository a git remote names: `git@github.com:owner/repo`, or any URL with that host, port and all */
function remoteRepo(remote: string): string | undefined {
	const scp = /^(?:[^@/\s]+@)?([^:/\s]+):([^/\s]+)\/([^/\s]+?)(?:\.git)?$/.exec(remote);
	if (scp !== null) return githubRepo(scp[1], scp[2] + '/' + scp[3]);
	try {
		const { hostname, pathname } = new URL(remote);
		return githubRepo(hostname, pathname);
	} catch {
		return undefined;
	}
}

/** the repository a URL in the call names, which may be a pull request or issue page under it */
function urlRepo(args: string[]): string | undefined {
	for (const arg of args) {
		const repo = remoteRepo(arg);
		if (repo !== undefined) return repo;
	}
	return undefined;
}

/** the repository a bare OWNER/REPO argument names, which is how gh repo names its target */
function bareRepo(args: string[]): string | undefined {
	for (const arg of args) {
		const match = /^[^/:\s]+\/[^/:\s]+$/.exec(arg);
		if (match) return arg;
	}
	return undefined;
}

/** the repository an api path names */
function apiRepo(args: string[]): string | undefined {
	for (const arg of args) {
		const match = API_PATH.exec(arg);
		// {owner} and {repo} are gh's placeholders, filled from the repository gh resolved, so they name no repository
		if (match !== null && !match[0].includes('{')) return match[1] + '/' + match[2];
	}
	return undefined;
}

// the names gh prefers a remote by, so the checkout answers with the one gh would post to
const remoteScore = (name: string): number => ({ upstream: 3, github: 2, origin: 1 })[name.toLowerCase()] ?? 0;

// gh lists the remotes, sorts them by that score and takes the first, unless `gh repo set-default` recorded a choice.
// With no terminal it cannot ask a human, so it never gets as far as the remotes it can reach
async function checkoutRepo(cwd: string): Promise<string | undefined> {
	const git = (args: string[]) =>
		execFileAsync('git', args, { cwd }).then(
			(result) => result.stdout,
			() => '',
		);
	const [listing, recorded] = await Promise.all([
		git(['remote', '-v']),
		git(['config', '--get-regexp', '^remote\\..*\\.gh-resolved$']),
	]);
	// git prints a fetch line and a push line for each remote; the fetch url is the one gh parses
	const urls = new Map<string, string>();
	for (const line of listing.split('\n')) {
		const [name, url] = line.split(/\s+/);
		if (name !== undefined && url !== undefined && !urls.has(name)) urls.set(name, url);
	}
	// set-default writes "base" on the remote it matched, and the name a human typed on one it did not
	const chosen = new Map<string, string>();
	for (const line of recorded.split('\n')) {
		const [, name, choice] = /^remote\.(.*)\.gh-resolved (.+)$/.exec(line) ?? [];
		if (name !== undefined && choice !== undefined) chosen.set(name, choice);
	}
	const names = [...urls.keys()].toSorted((a, b) => remoteScore(b) - remoteScore(a));
	for (const name of names) {
		const choice = chosen.get(name);
		if (choice === undefined) continue;
		if (choice === 'base') return remoteRepo(urls.get(name) ?? '');
		return choice.split('/').slice(-2).join('/');
	}
	const [first] = names;
	return first === undefined ? undefined : remoteRepo(urls.get(first) ?? '');
}

// strict false puts an option that takes no value into the parse result as a flag, so only a string carries one
const text = (value: unknown) => (typeof value === 'string' ? value : undefined);

async function apiPost(call: Call): Promise<Post | undefined> {
	const { values, positionals } = parseArgs({
		args: call.argv,
		options: API_OPTIONS,
		allowPositionals: true,
		strict: false,
	});
	const method = text(values.method);
	const fielded = values.field !== undefined || values['raw-field'] !== undefined || values.input !== undefined;
	if (method === undefined ? !fielded : !WRITE_METHODS.has(method.toUpperCase())) return undefined;
	// gh fills {owner} and {repo} in the path from the repository it resolved, and reaches one for no other endpoint: a
	// graphql mutation carries its subject in the query, so what this checkout is says nothing about it
	const fills = /\{(?:owner|repo)\}/.test(positionals[1] ?? '');
	const repo =
		urlRepo(positionals) ??
		apiRepo(positionals) ??
		(fills ? (call.ghRepo ?? (await checkoutRepo(call.cwd))) : undefined);
	return { repo };
}

async function commandPost(call: Call): Promise<Post | undefined> {
	const { values, positionals } = parseArgs({
		args: call.argv,
		options: COMMAND_OPTIONS,
		allowPositionals: true,
		strict: false,
	});
	const [group, action] = positionals;
	if (!GROUPS.has(group?.toLowerCase()) || !WRITE_ACTIONS.has(action?.toLowerCase())) return undefined;
	// gh repo names its target as a bare OWNER/REPO, which gh reads before -R, then GH_REPO, then this checkout's remotes
	const bare = group?.toLowerCase() === 'repo' ? bareRepo(positionals) : undefined;
	const repo = urlRepo(positionals) ?? bare ?? text(values.repo) ?? call.ghRepo ?? (await checkoutRepo(call.cwd));
	// the file -F names decides over the body, as it does for gh when both are given
	const fields = Array.isArray(values.field) ? values.field : [];
	const file = text(values['body-file']) ?? text(fields[0]);
	return {
		repo,
		title: text(values.title),
		body: text(values.body),
		bodyFile: file === undefined ? undefined : resolve(call.cwd, file),
	};
}

// gh api writes by its method or its body, and every other group by its action; a call that writes nothing has no post
async function postOf(call: Call): Promise<Post | undefined> {
	const { positionals } = parseArgs({ args: call.argv, options: {}, allowPositionals: true, strict: false });
	return positionals[0] === 'api' ? apiPost(call) : commandPost(call);
}

async function approved(ctx: ExtensionContext, post: Post, command: string, signal: AbortSignal): Promise<boolean> {
	if (!ctx.hasUI) return false;
	// gh sends the file when a call gives both --body and --body-file, and sends nothing at all when it cannot read it
	const body = post.bodyFile === undefined ? post.body : await readFile(post.bodyFile, 'utf8');
	const details = [
		'repository: ' + (post.repo ?? 'unknown, the command names none'),
		'command: ' + command,
		post.title && 'title: ' + post.title,
		body && 'body:\n' + body,
		'',
		RULE,
	].filter(Boolean);
	return ctx.ui.confirm('Post to ' + (post.repo ?? 'GitHub') + '?', details.join('\n'), { signal });
}

// the frames the wrapper sends: cwd, GH_REPO, the argument count, then each argument
function framesOf(received: string): Call | undefined {
	const parts = received.split('\0');
	const count = Number(parts[2]);
	if (!Number.isInteger(count) || count < 0 || parts.length <= 3 + count) return undefined;
	return { cwd: parts[0], ghRepo: parts[1] || undefined, argv: parts.slice(3, 3 + count) };
}

// the account is asked once per session, since a login or GH_TOKEN can change between them, and a failure says why
// once, because the memo runs the lookup once; the caller then treats the owner as unknown, which asks
// the account the token belongs to: gh answers with the owner of the token it would use, and the memo asks once
const account = memo(async () => {
	const result = await execFileAsync(await realGh(), ['api', 'user', '--jq', '.login'], { timeout: 10_000 });
	const login = result.stdout.trim();
	if (!login) throw new Error('gh is not logged in');
	return login;
});

async function verdict(ctx: ExtensionContext, call: Call, signal: AbortSignal) {
	const post = await postOf(call);
	if (post === undefined) return 'allow';
	const owner = await account()
		.then((login) => login.toLowerCase())
		.catch((error: unknown) => {
			const reason = (error instanceof Error ? error.message : String(error)).split('\n')[0];
			ctx.ui.notify(
				'gh-approval: cannot tell which account the token belongs to (' + reason + '), so every post asks',
				'warning',
			);
			return undefined;
		});
	if (post.repo !== undefined && post.repo.split('/')[0].toLowerCase() === owner) return 'allow';
	let allowed: boolean;
	try {
		allowed = await approved(ctx, post, 'gh ' + call.argv.join(' '), signal);
	} catch (error) {
		// a body file gh cannot read is a call it refuses, and a dialog that fails leaves no answer either
		return 'deny ' + (error instanceof Error ? error.message : String(error));
	}
	return allowed ? 'allow' : 'deny ' + RULE + '; nothing was sent';
}

export default function (pi: ExtensionAPI) {
	const scope = sessionScope(pi);

	// the listener and its socket exist only while the session does
	pi.on('session_start', async (_event, ctx) => {
		// released by itself if starting fails, and handed to the session once the gate listens
		await using starting = new AsyncDisposableStack();
		const server = createServer(async (socket) => {
			socket.setEncoding('utf8');
			socket.setTimeout(TIMEOUT_MS, () => socket.destroy());
			// an error on a socket with no listener is an uncaught exception, and a peer reset during end() raises one
			socket.on('error', () => socket.destroy());

			let frames = '';
			try {
				for await (const chunk of socket) {
					frames += chunk;
					const call = framesOf(frames);
					if (call === undefined) continue;
					// the timeout is for a client that never finishes its frames; a dialog takes as long as it takes
					socket.setTimeout(0);
					// a dialog has nowhere to send its answer once the gh call is gone, so the call's end dismisses it
					const hangUp = new AbortController();
					socket.once('close', () => hangUp.abort());
					const answer = await verdict(ctx, call, hangUp.signal).catch(
						(error: unknown) => 'deny gh-approval failed: ' + String(error) + '; nothing was sent',
					);
					if (hangUp.signal.aborted) {
						ctx.ui.notify('gh-approval: the gh call ended before it was answered, so nothing was sent', 'warning');
						return;
					}
					socket.end(answer + '\n');
					return;
				}
			} catch {
				// the client hung up mid-exchange; there is nobody left to answer
			}
		});
		// a unix socket rather than a loopback port: a sandboxed command has a network namespace of its own
		let dir = env.XDG_RUNTIME_DIR;
		if (dir === undefined) {
			// the spec's fallback is a directory as private as the runtime one, which mkdtemp gives
			dir = starting.use(await mkdtempDisposable(join(tmpdir(), 'gh-approval-'))).path;
			ctx.ui.notify('gh-approval: XDG_RUNTIME_DIR is not set, so the socket lives in ' + dir, 'warning');
		}
		const path = join(dir, 'gh-approval-' + randomBytes(8).toString('hex') + '.sock');
		// close() removes the socket file itself
		starting.defer(() => {
			server.close();
		});
		server.listen(path);
		// a bind failure arrives as 'error' and a bind that never settles is cut off by the signal; either way this
		// rejects rather than leaving the session waiting on a promise nothing will settle
		try {
			await once(server, 'listening', { signal: AbortSignal.timeout(TIMEOUT_MS) });
		} catch (error) {
			ctx.ui.notify('gh-approval: cannot listen on a socket, so gh runs ungated: ' + String(error), 'warning');
			return;
		}
		// the commands this session runs inherit it; a wrapper left without one warns and runs gh unchecked
		starting.use(overrideEnv({ GH_APPROVAL_SOCKET: path }));
		scope.use(starting.move());
	});
}
