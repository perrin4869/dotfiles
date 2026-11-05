import { type ExtensionAPI, SettingsManager } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Offer it only where a project opts in with `"advisor": { "enabled": true }`.
function setting(settings: object): boolean | undefined {
	const value = 'advisor' in settings ? settings.advisor : undefined;
	if (typeof value !== 'object' || value === null || !('enabled' in value)) return undefined;
	return typeof value.enabled === 'boolean' ? value.enabled : undefined;
}

export default function (pi: ExtensionAPI) {
	// by session_start every extension has registered its tools, so this replaces rpiv-advisor's whatever the
	// load order; a hidden tool is unreachable and setActiveTools ignores it, so rpiv-advisor cannot put it back
	pi.on('session_start', (_event, ctx) => {
		const manager = SettingsManager.create(ctx.cwd);
		if (setting(manager.getProjectSettings()) ?? setting(manager.getGlobalSettings()) ?? false) {
			return Promise.resolve();
		}
		pi.registerTool({
			name: 'advisor',
			label: 'advisor',
			description: 'disabled for this project',
			exposure: 'hidden',
			parameters: Type.Object({}),
			execute: () => Promise.reject(new Error('the advisor is disabled for this project')),
		});
		return Promise.resolve();
	});
}
