import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFile } from 'node:child_process';
import { once } from 'node:events';
import { accessSync, constants, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { createServer, type Server } from 'node:net';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

// ~/.agents/AGENTS.md asks for the exact title and body of any post to a repository outside my GitHub account, and an
// approval covering that one post. A rule in a prompt is advisory, so the wrapper below asks instead: a gh call arrives
// here as its real argv, with no shell syntax left to guess at, and the dialog decides before gh runs.
const RULE = 'posting outside my GitHub account needs the exact title and body shown and an approval for that one post';

// the gh groups whose subcommands write something others can see, and the subcommands that do
const GROUPS = new Set(['issue', 'pr', 'release', 'repo']);
const WRITES = new Set(['create', 'edit', 'comment', 'close', 'reopen', 'delete', 'review', 'merge', 'upload']);
// an api call with one of these methods or a field changes something; anything else reads
const METHODS = new Set(['POST', 'PATCH', 'PUT', 'DELETE']);
const FIELD = /^(?:-[fF]|--(?:field|raw-field|input)(?:=|$))/;

// nothing in the gate may hang the session: a bind that never settles and a client that never finishes its frames
// both give up after this
const TIMEOUT_MS = 10_000;

const GITHUB_URL = /github\.com[:/]([^/\s]+)\/([^/\s?#]+)/;
const API_PATH = /(?:^|\/)repos\/([^/\s]+)\/([^/\s?#]+)/;

type Post = {
	/** the call joined back into a command line, for the prompt */
	text: string;
	api: boolean;
	/** the repository the call names itself, if it names one */
	repo?: string;
	title?: string;
	body?: string;
	bodyFile?: string;
	/** the directory the call runs in, which is where the wrapper was */
	cwd: string;
};

// the agent directory the wrapper reads from too, overridable the way pi is
const agentDir = () => process.env.PI_CODING_AGENT_DIR ?? join(homedir(), '.pi', 'agent');
const shimPath = () => join(agentDir(), 'bin', 'gh');
const portPath = () => join(agentDir(), 'gh-approval.port');

/** argv joined into a command line a human can read, quoted where the shell would need it */
function commandLine(argv: string[]): string {
	return argv.map((arg) => (/^[\w@%+=:,./-]+$/.test(arg) ? arg : "'" + arg.replaceAll("'", "'\\''") + "'")).join(' ');
}

// the real gh, with the directory holding the wrapper dropped, so the gate never ends up calling itself
function realGh(): string | undefined {
	const path = (process.env.PATH ?? '')
		.split(':')
		.filter((dir) => dir !== dirname(shimPath()))
		.join(':');
	for (const dir of path.split(':')) {
		const candidate = join(dir, 'gh');
		try {
			accessSync(candidate, constants.X_OK);
			return candidate;
		} catch {
			// not here
		}
	}
	return undefined;
}

function splitFlag(arg: string): [string, string | undefined] {
	const equals = arg.indexOf('=');
	return arg.startsWith('-') && equals > 1 ? [arg.slice(0, equals), arg.slice(equals + 1)] : [arg, undefined];
}

/** the value of a flag, given as `--flag value`, `--flag=value` or `-Xvalue` */
function flag(args: string[], ...names: string[]): string | undefined {
	for (const [index, arg] of args.entries()) {
		const [name, inline] = splitFlag(arg);
		if (names.includes(name)) return inline ?? args[index + 1];
		// a short flag carries its value with no separator: -XPOST, -Rb/c
		const short = names.find((candidate) => candidate.length === 2 && arg.startsWith(candidate) && arg.length > 2);
		if (short !== undefined) return arg.slice(2);
	}
	return undefined;
}

/** whether an api call changes something, as opposed to reading it */
function apiWrites(args: string[]): boolean {
	const method = flag(args, '-X', '--method')?.toUpperCase();
	if (method !== undefined) return METHODS.has(method);
	return args.some((arg) => FIELD.test(arg));
}

/** the repository a URL in the call names */
function urlRepo(args: string[]): string | undefined {
	for (const arg of args) {
		const match = GITHUB_URL.exec(arg);
		if (match) return match[1] + '/' + match[2].replace(/\.git$/, '');
	}
	return undefined;
}

/** the repository an api path names */
function apiRepo(args: string[]): string | undefined {
	for (const arg of args) {
		const match = API_PATH.exec(arg);
		if (match) return match[1] + '/' + match[2];
	}
	return undefined;
}

function postOf(argv: string[], ghRepo: string | undefined, cwd: string): Post | undefined {
	const [group, action] = argv;
	const api = group === 'api';
	if (api ? !apiWrites(argv.slice(1)) : !(GROUPS.has(group?.toLowerCase()) && WRITES.has(action?.toLowerCase()))) {
		return undefined;
	}
	return {
		text: 'gh ' + commandLine(argv),
		api,
		repo: flag(argv, '--repo', '-R') ?? ghRepo ?? urlRepo(argv) ?? apiRepo(argv),
		title: flag(argv, '--title', '-t'),
		body: flag(argv, '--body', '-b'),
		bodyFile: flag(argv, '--body-file', '-F'),
		cwd,
	};
}

/** the body a post would send, from --body or the file --body-file names */
async function bodyOf(post: Post): Promise<string | undefined> {
	if (post.api) return undefined;
	if (post.body !== undefined) return post.body;
	return post.bodyFile && (await readFile(resolve(post.cwd, post.bodyFile), 'utf8').catch(() => undefined));
}

async function approved(ctx: ExtensionContext, repo: string | undefined, post: Post): Promise<boolean> {
	if (!ctx.hasUI) return false;
	const body = await bodyOf(post);
	const shown =
		body && body.length > 6000 ? body.slice(0, 6000) + '\n... ' + (body.length - 6000) + ' more characters' : body;
	const details = [
		'repository: ' + (repo ?? 'unknown, the command names none'),
		'command: ' + post.text,
		post.title && 'title: ' + post.title,
		shown && 'body:\n' + shown,
		'',
		RULE,
	].filter(Boolean);
	return ctx.ui.confirm('Post to ' + (repo ?? 'GitHub') + '?', details.join('\n'));
}

// the frames the wrapper sends: cwd, GH_REPO, the argument count, then each argument
function framesOf(text: string): { cwd: string; ghRepo: string; argv: string[] } | undefined {
	const parts = text.split('\0');
	const count = Number(parts[2]);
	if (parts.length <= 3 + count) return undefined;
	return { cwd: parts[0], ghRepo: parts[1], argv: parts.slice(3, 3 + count) };
}

// the checkout's origin names the repository when the call does not, read in the directory the call runs in
async function originRepo(cwd: string): Promise<string | undefined> {
	const result = await execFileAsync('git', ['remote', 'get-url', 'origin'], { cwd }).catch(() => undefined);
	return /github\.com[/:]([^/\s]+\/[^/\s]+?)(?:\.git)?\s*$/
		.exec(result?.stdout.trim() ?? '')
		?.slice(1)
		.join('/');
}

export default function (pi: ExtensionAPI) {
	let server: Server | undefined;
	let session: ExtensionContext | undefined;
	let login: string | undefined;
	let notified = false;

	// a gate that asks about everything looks broken, so the first lookup that fails says why and the rest stay quiet
	function note(ctx: ExtensionContext, reason: string): undefined {
		if (notified) return undefined;
		notified = true;
		ctx.ui.notify(
			'gh-approval: cannot tell which account the token belongs to (' + reason + '), so every post asks',
			'warning',
		);
		return undefined;
	}

	// empty when gh is missing, logged out, or unreachable, which asks rather than assuming the post is mine
	async function authenticated(ctx: ExtensionContext): Promise<string | undefined> {
		if (login !== undefined) return login || undefined;
		const gh = realGh();
		if (gh === undefined) return note(ctx, 'no gh on PATH');
		const result = await execFileAsync(gh, ['api', 'user', '--jq', '.login'], { timeout: 10_000 }).catch(
			(error: unknown) => note(ctx, String(error)),
		);
		login = result?.stdout.trim();
		return login || note(ctx, 'gh is not logged in');
	}

	async function verdict(ctx: ExtensionContext, ask: { cwd: string; ghRepo: string; argv: string[] }) {
		const post = postOf(ask.argv, ask.ghRepo || undefined, ask.cwd);
		if (post === undefined) return 'allow';
		// the origin of the directory and the account the token belongs to are independent lookups, so they run together
		const [repo, account] = await Promise.all([post.repo ?? originRepo(post.cwd), authenticated(ctx)]);
		const mine = account?.toLowerCase();
		if (repo !== undefined && repo.split('/')[0].toLowerCase() === mine) return 'allow';
		const allowed = await approved(ctx, repo, post).catch(() => false);
		return allowed ? 'allow' : 'deny ' + RULE + '; nothing was sent';
	}

	// writes the port the stowed wrapper asks on; a session that cannot write it has no gate
	async function install(ctx: ExtensionContext): Promise<void> {
		session = ctx;
		if (server === undefined) {
			server = createServer(async (socket) => {
				socket.setEncoding('utf8');
				socket.setTimeout(TIMEOUT_MS, () => socket.destroy());
				// an error on a socket with no listener is an uncaught exception, and a peer reset during end() raises one
				socket.on('error', () => socket.destroy());

				let frames = '';
				try {
					for await (const chunk of socket) {
						frames += chunk;
						const ask = framesOf(frames);
						if (ask === undefined) continue;
						const answer =
							session === undefined
								? 'deny gh-approval has no session to ask; nothing was sent'
								: await verdict(session, ask).catch(
										(error: unknown) => 'deny gh-approval failed: ' + String(error) + '; nothing was sent',
									);
						socket.end(answer + '\n');
						return;
					}
				} catch {
					// the client hung up mid-exchange; there is nobody left to answer
				}
			});
			server.listen({ port: 0, host: '127.0.0.1' });
			// a bind failure arrives as 'error' and a bind that never settles is cut off by the signal; either way this
			// rejects rather than leaving the session waiting on a promise nothing will settle
			try {
				await once(server, 'listening', { signal: AbortSignal.timeout(TIMEOUT_MS) });
			} catch (error) {
				server.close();
				ctx.ui.notify('gh-approval: cannot listen on loopback, so gh runs ungated: ' + String(error), 'warning');
				server = undefined;
				return;
			}
		}
		const address = server.address();
		// a listening TCP server answers with an AddressInfo; null is "not listening" and a string is a unix socket
		if (address === null || typeof address === 'string') return;
		mkdirSync(agentDir(), { recursive: true });
		writeFileSync(portPath(), String(address.port));
	}

	// a session that cannot write its port file has no gate; say so rather than fail the session over it
	pi.on('session_start', (_event, ctx) => install(ctx).catch(() => undefined));

	// the port file goes with the session; a wrapper left without one says so and runs gh, since the gate is gone
	pi.on('session_shutdown', () => {
		server?.close();
		server = undefined;
		session = undefined;
		rmSync(portPath(), { force: true });
	});
}
