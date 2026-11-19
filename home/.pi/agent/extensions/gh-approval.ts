import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFile } from 'node:child_process';
import { once } from 'node:events';
import { accessSync, constants, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { readFile } from 'node:fs/promises';
import { createServer, type Server } from 'node:net';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { parseArgs, promisify } from 'node:util';
import { memo } from './lib/memo.ts';

const execFileAsync = promisify(execFile);

// ~/.agents/AGENTS.md asks for the exact title and body of any post to a repository outside my GitHub account, and an
// approval covering that one post. A rule in a prompt is advisory, so the wrapper on PATH asks instead: a gh call
// arrives here as its real argv, with no shell syntax left to guess at, and the dialog decides before gh runs.
const RULE = 'posting outside my GitHub account needs the exact title and body shown and an approval for that one post';

// the gh groups whose subcommands write something others can see, and the actions that do
const GROUPS = new Set(['issue', 'pr', 'release', 'repo']);
const WRITE_ACTIONS = new Set(['create', 'edit', 'comment', 'close', 'reopen', 'delete', 'review', 'merge', 'upload']);
// an api call with one of these methods, or with a request body, changes something; anything else reads
const WRITE_METHODS = new Set(['POST', 'PATCH', 'PUT', 'DELETE']);

// gh reuses -F for --body-file on issue and pr and for --field on api, so the table holds both and the group picks
const OPTIONS = {
	repo: { type: 'string', short: 'R' },
	title: { type: 'string', short: 't' },
	body: { type: 'string', short: 'b' },
	'body-file': { type: 'string' },
	method: { type: 'string', short: 'X' },
	field: { type: 'string', short: 'F', multiple: true },
	'raw-field': { type: 'string', short: 'f', multiple: true },
	input: { type: 'string' },
} as const;

// nothing in the gate may hang the session: a bind that never settles and a client that never finishes its frames
// both give up after this
const TIMEOUT_MS = 10_000;

const GITHUB_URL = /github\.com[:/]([^/\s]+)\/([^/\s?#]+)/;
const API_PATH = /(?:^|\/)repos\/([^/\s]+)\/([^/\s?#]+)/;

/** one gh call as the wrapper sends it: the directory it runs in, its argv, and the repository GH_REPO named */
type Call = { cwd: string; argv: string[]; ghRepo?: string };

type Post = {
	/** the call joined back into a command line, for the prompt */
	text: string;
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
// pi puts the wrapper's directory first on the PATH of the commands it runs, and nothing else does
const shimDir = () => join(agentDir(), 'bin');
const addrPath = () => join(agentDir(), 'gh-approval.addr');

/** argv joined into a command line a human can read, quoted where the shell would need it */
function commandLine(argv: string[]): string {
	return argv.map((arg) => (/^[\w@%+=:,./-]+$/.test(arg) ? arg : "'" + arg.replaceAll("'", "'\\''") + "'")).join(' ');
}

// the real gh, with the directory holding the wrapper dropped, so the gate never ends up calling itself. A missing gh
// is not an answer but a reason the account cannot be read, so it throws like one.
function realGh(): string {
	for (const dir of (process.env.PATH ?? '').split(':').filter((entry) => entry !== shimDir())) {
		const candidate = join(dir, 'gh');
		try {
			accessSync(candidate, constants.X_OK);
			return candidate;
		} catch {
			// not here
		}
	}
	throw new Error('no gh on PATH');
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

function postOf(call: Call): Post | undefined {
	// unknown flags are gh's own business; strict false keeps them out of the way, and a value one takes lands among the
	// positionals, which nothing here reads past the second of
	const { tokens } = parseArgs({
		args: call.argv,
		options: OPTIONS,
		allowPositionals: true,
		strict: false,
		tokens: true,
	});
	// the value of the first of these flags the call carries, whatever spelling it used
	const value = (...names: string[]) => {
		for (const token of tokens) {
			if (token.kind === 'option' && names.includes(token.name)) return token.value;
		}
		return undefined;
	};
	const carries = (...names: string[]) => value(...names) !== undefined;
	const [group, action] = tokens.flatMap((token) => (token.kind === 'positional' ? [token.value] : []));
	const api = group === 'api';
	const method = value('method');
	// --field, --raw-field and --input are gh api's three ways to send a request body
	const fielded = carries('field', 'raw-field', 'input');
	// an api call writes when its method says so, or, with no method, when it sends a body
	if (api && method !== undefined && !WRITE_METHODS.has(method.toUpperCase())) return undefined;
	if (api && method === undefined && !fielded) return undefined;
	// the other groups write through the actions in the list
	if (!api && !(GROUPS.has(group?.toLowerCase()) && WRITE_ACTIONS.has(action?.toLowerCase()))) return undefined;
	return {
		text: 'gh ' + commandLine(call.argv),
		repo: value('repo') ?? call.ghRepo ?? urlRepo(call.argv) ?? apiRepo(call.argv),
		title: value('title'),
		body: value('body'),
		bodyFile: api ? undefined : (value('body-file') ?? value('field')),
		cwd: call.cwd,
	};
}

async function approved(ctx: ExtensionContext, repo: string | undefined, post: Post): Promise<boolean> {
	if (!ctx.hasUI) return false;
	// gh sends the file when a call gives both --body and --body-file, and sends nothing at all when it cannot read it
	const body =
		post.bodyFile === undefined
			? post.body
			: await readFile(resolve(post.cwd, post.bodyFile), 'utf8').catch(() => undefined);
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
function framesOf(text: string): Call | undefined {
	const parts = text.split('\0');
	const count = Number(parts[2]);
	if (!Number.isInteger(count) || count < 0 || parts.length <= 3 + count) return undefined;
	return { cwd: parts[0], ghRepo: parts[1] || undefined, argv: parts.slice(3, 3 + count) };
}

// the checkout's origin names the repository when the call does not, read in the directory the call runs in
async function originRepo(cwd: string): Promise<string | undefined> {
	const result = await execFileAsync('git', ['remote', 'get-url', 'origin'], { cwd }).catch(() => undefined);
	return /github\.com[/:]([^/\s]+\/[^/\s]+?)(?:\.git)?\s*$/
		.exec(result?.stdout.trim() ?? '')
		?.slice(1)
		.join('/');
}

async function verdict(ctx: ExtensionContext, call: Call, account: (ctx: ExtensionContext) => Promise<string>) {
	const post = postOf(call);
	if (post === undefined) return 'allow';
	// the origin of the directory and the account the token belongs to are independent lookups, so they run together
	// a lookup that failed has already said why; the owner stays unknown, so the post asks
	const [repo, owner] = await Promise.all([post.repo ?? originRepo(call.cwd), account(ctx).catch(() => undefined)]);
	const mine = owner?.toLowerCase();
	if (repo !== undefined && repo.split('/')[0].toLowerCase() === mine) return 'allow';
	const allowed = await approved(ctx, repo, post).catch(() => false);
	return allowed ? 'allow' : 'deny ' + RULE + '; nothing was sent';
}

export default function (pi: ExtensionAPI) {
	let server: Server | undefined;

	// the account the token belongs to; the cache lives with the session, since a login or GH_TOKEN can change between
	// them. A lookup that cannot answer says why and throws, and the caller treats the owner as unknown, which asks
	const authenticated = memo(async (ctx: ExtensionContext) => {
		try {
			const result = await execFileAsync(realGh(), ['api', 'user', '--jq', '.login'], { timeout: 10_000 });
			const login = result.stdout.trim();
			if (!login) throw new Error('gh is not logged in');
			return login;
		} catch (error) {
			const reason = (error instanceof Error ? error.message : String(error)).split('\n')[0];
			ctx.ui.notify(
				'gh-approval: cannot tell which account the token belongs to (' + reason + '), so every post asks',
				'warning',
			);
			throw error;
		}
	});

	// the listener and the port exist only while the session does
	pi.on('session_start', async (_event, ctx) => {
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
						const call = framesOf(frames);
						if (call === undefined) continue;
						// the timeout is for a client that never finishes its frames; a dialog takes as long as it takes
						socket.setTimeout(0);
						// a dialog has nowhere to send its answer once the wrapper gave up, so a close rejects the race, as does an
						// error before it, and only a decision resolves it
						let answer: string;
						try {
							answer = await Promise.race([
								verdict(ctx, call, authenticated).catch(
									(error: unknown) => 'deny gh-approval failed: ' + String(error) + '; nothing was sent',
								),
								once(socket, 'close').then(() => Promise.reject(new Error('the gh call ended before it was answered'))),
							]);
						} catch {
							ctx.ui.notify('gh-approval: the gh call ended while the dialog was open, so nothing was sent', 'warning');
							return;
						}
						socket.end(answer + '\n');
						return;
					}
				} catch {
					// the client hung up mid-exchange; there is nobody left to answer
				}
			});
			// loopback, for security: bound anywhere else, the network could ask this session to post, and the protocol
			// carries nothing that could tell a peer from the wrapper. The port is the OS's, and the session publishes it
			// with the address so the wrapper dials what was bound
			server.listen(0, 'localhost');
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
		// a session that cannot publish its endpoint has no gate, and the wrapper reports that it has no session to ask
		try {
			mkdirSync(agentDir(), { recursive: true });
			writeFileSync(addrPath(), address.address + ' ' + address.port + '\n');
		} catch {
			// nothing to gate with
		}
	});

	// the endpoint file goes with the session; a wrapper left without one says so and runs gh, since the gate is gone
	pi.on('session_shutdown', () => {
		server?.close();
		server = undefined;
		rmSync(addrPath(), { force: true });
	});
}
