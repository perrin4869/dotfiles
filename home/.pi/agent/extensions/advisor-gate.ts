import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { defineSettings } from './lib/settings.ts';
import { withdrawTool } from './lib/tools.ts';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Offer it only where a project opts in with `"advisor": { "enabled": true }`.
const readSettings = defineSettings('advisor', Type.Object({ enabled: Type.Boolean({ default: false }) }));

export default function (pi: ExtensionAPI) {
	pi.on('session_start', (_event, ctx) => {
		if (!readSettings(pi, ctx).enabled) withdrawTool(pi, 'advisor', 'the advisor is disabled for this project');
	});
}
