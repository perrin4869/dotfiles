import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { execFile } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

// ~/.agents/AGENTS.md asks for the exact title and body of any post to a repository outside my GitHub account, and
// an approval covering that one post. Prose in the prompt is advisory, so this checks the same thing before the
// shell runs. Repositories under the authenticated account are left alone.
const RULE = 'posting outside my GitHub account needs the exact title and body shown and an approval for that one post';

// a gh subcommand that writes something others can see, and the group it belongs to
const WRITE = /\bgh\s+(issue|pr|release|repo)\s+([a-z-]+)|\bgh\s+(api)\b[^\n;&|]*/gi;
const WRITES = new Set(['create', 'edit', 'comment', 'close', 'reopen', 'delete', 'review', 'merge', 'upload']);
// an api call that changes something; anything else reads
const API_WRITE = /(?:-X|--method)[=\s]*(?:POST|PATCH|PUT|DELETE)|-[fF]\s|--(?:raw-)?field\b/i;

type Post = { text: string; api: boolean };

function commandOf(input: unknown): string | undefined {
	if (typeof input !== 'object' || input === null || !('command' in input)) return undefined;
	return typeof input.command === 'string' ? input.command : undefined;
}

/** The value of a flag, quoted or not. */
function flag(text: string, ...names: string[]): string | undefined {
	for (const name of names) {
		const match = new RegExp(`(?:^|\\s)(?:${name})(?:[=\\s]+)(?:"([^"]*)"|'([^']*)'|(\\S+))`).exec(text);
		if (match) return match[1] ?? match[2] ?? match[3];
	}
	return undefined;
}

/** The gh calls in a command that post something, one entry per call. */
function posts(command: string): Post[] {
	const found: Post[] = [];
	for (const match of command.matchAll(WRITE)) {
		// the call runs to the next shell operator, which is where its own arguments end
		const text = command
			.slice(match.index)
			.split(/[;&|\n]/)[0]
			.trim();
		const api = match[3] !== undefined;
		if (!api && !WRITES.has(match[2].toLowerCase())) continue;
		if (api && !API_WRITE.test(text)) continue;
		found.push({ text, api });
	}
	return found;
}

/** The repository a gh call names itself: its --repo, or an api path. */
function namedRepo(text: string): string | undefined {
	const explicit = flag(text, '--repo', '-R');
	if (explicit) return explicit;
	return /\bapi\b[^\n;&|]*?\brepos\/([^/\s?]+)\/([^/\s?]+)/.exec(text)?.slice(1).join('/');
}

/** The body a gh call would post, read from --body-file when that is what it uses. */
async function bodyOf(post: Post): Promise<string | undefined> {
	if (post.api) return undefined;
	const inline = flag(post.text, '--body', '-b');
	if (inline) return inline;
	const file = flag(post.text, '--body-file', '-F');
	return file && (await readFile(file, 'utf8').catch(() => undefined));
}

// the checkout's origin names the repository when the command does not
async function originRepo(cwd: string): Promise<string | undefined> {
	const result = await execFileAsync('git', ['remote', 'get-url', 'origin'], { cwd }).catch(() => undefined);
	return /github\.com[/:]([^/\s]+\/[^/\s]+?)(?:\.git)?\s*$/
		.exec(result?.stdout.trim() ?? '')
		?.slice(1)
		.join('/');
}

async function approved(ctx: ExtensionContext, repo: string | undefined, post: Post): Promise<boolean> {
	if (!ctx.hasUI) return false;
	const title = flag(post.text, '--title', '-t');
	const body = await bodyOf(post);
	const shown = body && body.length > 6000 ? `${body.slice(0, 6000)}\n... ${body.length - 6000} more characters` : body;
	const details = [
		`repository: ${repo ?? 'unknown, the command names none'}`,
		`command: ${post.text}`,
		title && `title: ${title}`,
		shown && `body:\n${shown}`,
		'',
		RULE,
	].filter(Boolean);
	return ctx.ui.confirm(`Post to ${repo ?? 'GitHub'}?`, details.join('\n'));
}

export default function (pi: ExtensionAPI) {
	let login: string | undefined;

	// empty when gh is missing or logged out, which asks rather than assuming the post is mine. execFile rather than
	// pi.exec, which spawns with the PATH pi started under and so misses a gh added since.
	async function authenticated(): Promise<string | undefined> {
		if (login === undefined) {
			const result = await execFileAsync('gh', ['api', 'user', '--jq', '.login'], { timeout: 10_000 }).catch(
				() => undefined,
			);
			login = result?.stdout.trim();
		}
		return login || undefined;
	}

	pi.on('tool_call', async (event, ctx) => {
		const command = commandOf(event.input);
		if (command === undefined) return undefined;
		const found = posts(command);
		if (found.length === 0) return undefined;
		const mine = (await authenticated())?.toLowerCase();
		for (const post of found) {
			const repo = namedRepo(post.text) ?? (await originRepo(ctx.cwd));
			if (repo && repo.split('/')[0].toLowerCase() === mine) continue;
			if (await approved(ctx, repo, post)) continue;
			return { block: true, reason: `${RULE}; nothing was sent` };
		}
		return undefined;
	});
}
