import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { readSettings } from './lib/settings.ts';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Offer it only where a project opts in with `"advisor": { "enabled": true }`.
const AdvisorSettings = Type.Object({ enabled: Type.Optional(Type.Boolean()) });

export default function (pi: ExtensionAPI) {
	// by session_start every extension has registered its tools, so this replaces rpiv-advisor's whatever the
	// load order; a hidden tool is unreachable and setActiveTools ignores it, so rpiv-advisor cannot put it back
	pi.on('session_start', (_event, ctx) => {
		if (readSettings(ctx.cwd, 'advisor', AdvisorSettings).enabled) return Promise.resolve();
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
