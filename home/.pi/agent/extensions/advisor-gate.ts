import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { defineSettings } from './lib/settings.ts';

// rpiv-advisor keeps one global reviewer for every session, so an Ollama project would send its whole
// conversation to that reviewer too. Offer it only where a project opts in with `"advisor": { "enabled": true }`.
export const readSettings = defineSettings('advisor', Type.Object({ enabled: Type.Boolean({ default: false }) }));

// pi hides declarations only through an active tool's prepareLoadout, which it recomputes on every prompt. Dropping
// the tool from the active set in before_agent_start is simpler, but any later handler that makes rpiv-advisor re-add
// it (a model switch does) puts it back in that run's prompt. Hiding leaves the tool callable, hence the block.
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
		// always hides its own declaration, so it costs no context; it stays active, which is what runs this
		prepareLoadout: () => ({ hiddenDeclarations: enabled ? [GATE] : [ADVISOR, GATE] }),
		parameters: Type.Object({}),
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
