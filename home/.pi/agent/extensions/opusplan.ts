import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { findModel, ModelRef, modelRef } from './lib/models.ts';
import { latestEntry } from './lib/session.ts';
import { defineSettings } from './lib/settings.ts';

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or with /opusplan; switching models
// disables it.
const readSettings = defineSettings(
	'opusplan',
	Type.Object({
		enabled: Type.Boolean({ default: false }),
		plan: ModelRef('claude-bridge/claude-opus-5-5'),
		execute: ModelRef('claude-bridge/claude-sonnet-5-5'),
	}),
);

// pi-plan-mode appends its whole state as one of these custom entries whenever it changes. Neither is exported, so
// both mirror its source; only `enabled` matters here:
// https://github.com/narumiruna/pi-extensions/blob/%40narumitw/pi-plan-mode%400.59.5/packages/pi-plan-mode/src/plan-mode.ts#L106
// https://github.com/narumiruna/pi-extensions/blob/%40narumitw/pi-plan-mode%400.59.5/packages/pi-plan-mode/src/state.ts#L51
const PLAN_STATE_ENTRY = 'plan-mode-state';
const PlanState = Type.Object({ enabled: Type.Boolean() });

const isPlanning = (ctx: ExtensionContext) => latestEntry(ctx, PLAN_STATE_ENTRY, PlanState)?.enabled ?? false;

export default function (pi: ExtensionAPI) {
	// set by /opusplan or a model switch; overrides the settings for the rest of this pi process, including fresh
	// implementation sessions
	let override: boolean | undefined;
	const isEnabled = (ctx: ExtensionContext) => override ?? readSettings(pi, ctx).enabled;
	// pi reports opusplan's own switches as model_select too
	let switching = false;

	async function follow(ctx: ExtensionContext) {
		const settings = readSettings(pi, ctx);
		const ref = isPlanning(ctx) ? settings.plan : settings.execute;
		if (ctx.model && modelRef(ctx.model) === ref) return;
		const model = findModel(ctx, ref);
		switching = true;
		try {
			if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${ref}`, 'warning');
		} finally {
			switching = false;
		}
	}

	pi.registerCommand('opusplan', {
		description: 'Enable opusplan: plan on one model, implement on another; switching models disables it',
		handler: async (_args, ctx) => {
			override = true;
			ctx.ui.notify('opusplan enabled', 'info');
			await follow(ctx);
		},
	});

	pi.on('model_select', (event, ctx) => {
		if (switching || event.source === 'restore' || !isEnabled(ctx)) return;
		override = false;
		ctx.ui.notify('opusplan disabled', 'info');
	});

	pi.on('before_agent_start', async (_event, ctx) => {
		if (isEnabled(ctx)) await follow(ctx);
	});
}
