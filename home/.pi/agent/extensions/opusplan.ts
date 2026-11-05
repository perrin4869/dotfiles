import type { CustomEntry, ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { Value } from 'typebox/value';
import { findModel, ModelRef, modelRef } from './lib/models.ts';
import { defineSettings } from './lib/settings.ts';

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or toggle with /opusplan.
export const settings = defineSettings(
	'opusplan',
	Type.Object({
		enabled: Type.Boolean({ default: false }),
		plan: ModelRef('claude-bridge/claude-opus-5-5'),
		execute: ModelRef('claude-bridge/claude-sonnet-5-5'),
	}),
);

// pi-plan-mode appends one of these custom entries whenever plan mode changes; the latest is current
const PLAN_STATE_ENTRY = 'plan-mode-state';
const PlanState = Type.Object({ enabled: Type.Boolean() });

function isPlanning(ctx: ExtensionContext) {
	const state = ctx.sessionManager
		.getBranch()
		.findLast((entry): entry is CustomEntry => entry.type === 'custom' && entry.customType === PLAN_STATE_ENTRY);
	return state !== undefined && Value.Check(PlanState, state.data) && state.data.enabled;
}

export default function (pi: ExtensionAPI) {
	// set by /opusplan; overrides the settings for the rest of this pi process, including fresh implementation sessions
	let override: boolean | undefined;

	pi.registerCommand('opusplan', {
		description: 'Toggle opusplan: plan on one model, implement on another',
		handler: async (_args, ctx) => {
			override = !(override ?? settings.read(pi, ctx).enabled);
			ctx.ui.notify(`opusplan ${override ? 'enabled' : 'disabled'}`, 'info');
		},
	});

	pi.on('before_agent_start', async (_event, ctx) => {
		const { enabled, plan, execute } = settings.read(pi, ctx);
		if (!(override ?? enabled)) return;
		const ref = isPlanning(ctx) ? plan : execute;
		if (ctx.model && modelRef(ctx.model) === ref) return;
		const model = findModel(ctx, ref);
		if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${ref}`, 'warning');
	});
}
