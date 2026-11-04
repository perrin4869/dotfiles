import { type ExtensionAPI, SettingsManager, type ToolCallEvent } from '@earendil-works/pi-coding-agent';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Allow it only where a project opts in with `"advisor": { "enabled": true }`.
function enabled(settings: object): boolean | undefined {
	const value = 'advisor' in settings ? settings.advisor : undefined;
	if (typeof value !== 'object' || value === null || !('enabled' in value)) return undefined;
	return typeof value.enabled === 'boolean' ? value.enabled : undefined;
}

export default function (pi: ExtensionAPI) {
	pi.on('tool_call', (event: ToolCallEvent, ctx) => {
		if (event.toolName !== 'advisor') return Promise.resolve(undefined);
		const manager = SettingsManager.create(ctx.cwd);
		if (enabled(manager.getProjectSettings()) ?? enabled(manager.getGlobalSettings()) ?? false) {
			return Promise.resolve(undefined);
		}
		return Promise.resolve({
			block: true,
			reason:
				'the advisor is disabled for this project; enable it with "advisor": { "enabled": true } in .pi/settings.json',
		});
	});
}
