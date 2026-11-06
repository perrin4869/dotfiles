import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { findModel, ModelRef, modelRef } from './lib/models.ts';
import { latestEntry } from './lib/session.ts';
import { defineSettings } from './lib/settings.ts';

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or toggle with /opusplan.
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
	// set by /opusplan; overrides the settings for the rest of this pi process, including fresh implementation sessions
	let override: boolean | undefined;
	const isEnabled = ({ enabled }: { enabled: boolean }) => override ?? enabled;
	// the model in use before opusplan first switched, restored when /opusplan turns it off
	let replaced: ExtensionContext['model'];

	pi.registerCommand('opusplan', {
		description: 'Toggle opusplan: plan on one model, implement on another',
		handler: async (_args, ctx) => {
			override = !isEnabled(readSettings(pi, ctx));
			if (!override && replaced) {
				await pi.setModel(replaced);
				replaced = undefined;
			}
			ctx.ui.notify(`opusplan ${override ? 'enabled' : 'disabled'}`, 'info');
		},
	});

	pi.on('before_agent_start', async (_event, ctx) => {
		const settings = readSettings(pi, ctx);
		if (!isEnabled(settings)) return;
		const ref = isPlanning(ctx) ? settings.plan : settings.execute;
		if (ctx.model && modelRef(ctx.model) === ref) return;
		const model = findModel(ctx, ref);
		replaced ??= ctx.model;
		if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${ref}`, 'warning');
	});
}
