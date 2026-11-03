import type { ExtensionAPI, ToolCallEvent } from '@earendil-works/pi-coding-agent';

// pi-subagents uploads the session to a gist via `gh` itself, so the bash permission rules never see it
function requestsShare(value: unknown): boolean {
	if (Array.isArray(value)) return value.some(requestsShare);
	if (value === null || typeof value !== 'object') return false;
	return Object.entries(value).some(([key, v]) => (key === 'share' && v === true) || requestsShare(v));
}

export default function (pi: ExtensionAPI) {
	pi.on('tool_call', (event: ToolCallEvent) => {
		if (event.toolName === 'subagent' && requestsShare(event.input)) {
			return Promise.resolve({ block: true, reason: 'sharing subagent sessions is disabled; use /share explicitly' });
		}
		return Promise.resolve(undefined);
	});
}
