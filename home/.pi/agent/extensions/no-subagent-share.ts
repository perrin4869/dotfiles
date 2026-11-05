import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

// pi-subagents uploads the session to a gist via `gh` itself, so the bash permission rules never see it.
// Object.entries also walks arrays, which covers shares nested in parallel or chained tasks.
const requestsShare = (value: unknown): boolean =>
	typeof value === 'object' &&
	value !== null &&
	Object.entries(value).some(([key, nested]) => (key === 'share' && nested === true) || requestsShare(nested));

export default function (pi: ExtensionAPI) {
	pi.on('tool_call', (event) =>
		event.toolName === 'subagent' && requestsShare(event.input)
			? { block: true, reason: 'sharing subagent sessions is disabled; use /share explicitly' }
			: undefined,
	);
}
