// What a body of release notes is made of: GitHub reads, link rewriting, cutting a note to fit, and sharing the room
// between them.
import { setTimeout as sleep } from 'node:timers/promises';

// `work` tried again while `shouldRetry` says the answer may change, pausing `wait`'s milliseconds before each try; a
// throw is tried again too, unless the attempts run out
export async function retry(work, shouldRetry, { attempts = 3, wait = (_, attempt) => 1000 * 2 ** (attempt - 1) } = {}) {
	for (let attempt = 1; ; attempt++) {
		let answer;
		try {
			answer = await work();
		} catch (error) {
			if (attempt === attempts) throw error;
			await sleep(wait(undefined, attempt));
			continue;
		}
		if (!shouldRetry(answer) || attempt === attempts) return answer;
		await sleep(wait(answer, attempt));
	}
}

// The API's answer for `path` under `repo`, or undefined where it has none; `raw` asks for a file's bare contents
export async function github(repo, path, { raw = false } = {}) {
	const token = process.env.GITHUB_TOKEN;
	const response = await retry(
		() =>
			fetch(`https://api.github.com/repos/${repo}/${path}`, {
				headers: {
					accept: raw ? 'application/vnd.github.raw+json' : 'application/vnd.github+json',
					// CI passes its own token, for the higher rate limit
					...(token && { authorization: `Bearer ${token}` }),
				},
			}),
		// a 5xx, a 429 or a 403 carrying `retry-after` may pass; a plain 403 is a permission answer
		(response) =>
			response.status >= 500 ||
			response.status === 429 ||
			(response.status === 403 && response.headers.has('retry-after')),
		// the server names the wait when it rate limits, and the backoff doubles otherwise
		{ wait: (response, attempt) => Number(response?.headers.get('retry-after')) * 1000 || 1000 * 2 ** (attempt - 1) },
	);
	if (response.status === 404) return undefined;
	if (!response.ok) throw new Error(`GitHub answered ${response.status} for ${repo}/${path}`);
	return raw ? response.text() : response.json();
}

// notes are written for their own repo: point its issue references there, and keep mentions from notifying
const relink = (repo, body) =>
	body
		// `&` keeps an HTML entity such as `&#39;` intact
		.replace(/(^|[^\w/`&])#(\d+)\b/g, `$1${repo}#$2`)
		.replace(/(^|[^\w/`])@([A-Za-z\d](?:[A-Za-z\d-]*[A-Za-z\d])?)\b(?![./]\w)/g, '$1`@$2`');

// One section of the body with the URL it came from, which is where to read the rest when it is cut; undefined when
// its source says nothing
export function noteSection(repo, heading, url, body) {
	const trimmed = body?.trim();
	return trimmed ? { url, text: `### [${heading}](${url})\n\n${relink(repo, trimmed)}` } : undefined;
}

// the mark a cut leaves where the rest of the note would be
const ELLIPSIS = '...';

// the last word of `text` that fits in `room` once the ellipsis is counted, for a text with no line short enough
function cutWord(text, room) {
	if (text.length <= room) return text;
	const width = Math.max(0, room - ELLIPSIS.length);
	// a word the cut lands inside is dropped, one it ends on is kept whole
	const sliced = text.slice(0, width);
	const words = /\s/.test(text[width]) ? sliced.trimEnd() : sliced.replace(/\s+\S*$/, '');
	return words ? `${words}${ELLIPSIS}` : '';
}

// `text` cut to fit in `room`: at the last line that fits, else at the last word, marked with an ellipsis; a code
// block the cut leaves open is closed
function cut(text, room) {
	const end = text.lastIndexOf('\n', room);
	const kept = end < 0 ? cutWord(text, room) : text.slice(0, end).trimEnd();
	return (kept.match(/^```/gm)?.length ?? 0) % 2 ? `${kept}\n\`\`\`` : kept;
}

// A source's notes joined into one markdown block within `limit`, ending where the rest is when they do not fit
export function fit(notes, limit) {
	const separator = '\n\n';
	const kept = [];
	let size = 0;
	for (const { url, text } of notes) {
		const gap = kept.length > 0 ? separator.length : 0;
		if (size + gap + text.length <= limit) {
			size += gap + text.length;
			kept.push(text);
			continue;
		}
		// the link that says where the rest is comes out of the same allowance
		const more = `[More](${url})`;
		// a note that follows others ends the block where it stands; a first one is cut to leave the link its room
		if (kept.length > 0) return [...kept, more].join(separator);
		const room = limit - separator.length - more.length;
		return [room > 0 ? cut(text, room) : '', more].filter(Boolean).join(separator);
	}
	return kept.join(separator);
}

// A body is one GitHub comment of 65,536 characters, wrappers included, and `create-pull-request` truncates past it
export const BODY_LIMIT = 65000;

// What each source's notes may take: an equal share of what the wrappers leave, and what the short ones leave unused
// going to the long ones
export function allowances(sizes, budget) {
	if (sizes.length === 0) return [];
	const share = Math.floor(budget / sizes.length);
	const spare = budget - sizes.reduce((sum, size) => sum + Math.min(size, share), 0);
	const over = sizes.filter((size) => size > share).length;
	const extra = over > 0 ? Math.floor(spare / over) : 0;
	return sizes.map((size) => (size > share ? share + extra : size));
}
