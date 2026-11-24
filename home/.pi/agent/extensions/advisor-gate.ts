import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { defineSettings } from '#lib/settings';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Offer it only where a project opts in with `"advisor": { "enabled": true }`.
const readSettings = defineSettings('advisor', Type.Object({ enabled: Type.Boolean({ default: false }) }));

// pi hides declarations only through an active tool's prepareLoadout, which it recomputes on every prompt. Dropping
// the tool from the active set instead is simpler, but rpiv-advisor re-adds it on a model switch (`restore.ts` does
// `[...active, ADVISOR]`), which puts it back in that run's prompt; hiding survives regardless. Hiding leaves the tool
// callable, hence the block.
const GATE = 'advisor_gate';
const ADVISOR = 'advisor';

export default function (pi: ExtensionAPI) {
	let enabled = false;
	pi.on('session_start', (_event, ctx) => {
		enabled = readSettings(pi, ctx).enabled;
	});

	pi.registerTool({
		name: GATE,
		label: GATE,
		description: 'Keeps the advisor out of projects that have not enabled it',
		// model-only means never callable, and it is active because prepareLoadout only runs for active tools
		exposure: 'model-only',
		// always hides its own declaration, so it costs no context
		prepareLoadout: () => ({ hiddenDeclarations: enabled ? [GATE] : [ADVISOR, GATE] }),
		parameters: Type.Object({}),
		// unreachable while the exposure is model-only; ToolDefinition still requires it
		execute: () => Promise.reject(new Error('the advisor gate takes no calls')),
	});

	pi.on('tool_call', (event) =>
		event.toolName === ADVISOR && !enabled
			? {
					block: true,
					reason:
						'the advisor is disabled for this project; enable it with "advisor": { "enabled": true } in .pi/settings.json',
				}
			: undefined,
	);
}
