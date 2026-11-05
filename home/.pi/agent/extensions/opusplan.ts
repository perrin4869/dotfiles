import { type CustomEntry, type ExtensionAPI, type ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { Value } from 'typebox/value';
import { readSettings } from './lib/settings.ts';

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or toggle with /opusplan.
const OpusplanSettings = Type.Object({
	enabled: Type.Optional(Type.Boolean()),
	plan: Type.Optional(Type.String()),
	execute: Type.Optional(Type.String()),
});

const DEFAULTS = { plan: 'claude-bridge/claude-opus-5-5', execute: 'claude-bridge/claude-sonnet-5-5' };
// pi-plan-mode persists its state as custom session entries of this type; the latest one is current
const PLAN_STATE_ENTRY = 'plan-mode-state';
const PlanState = Type.Object({ enabled: Type.Boolean() });

const readOpusplan = (cwd: string) => ({ ...DEFAULTS, ...readSettings(cwd, 'opusplan', OpusplanSettings) });

function isPlanning(ctx: ExtensionContext): boolean {
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
		handler: (_args, ctx) => {
			override = !(override ?? readOpusplan(ctx.cwd).enabled ?? false);
			ctx.ui.notify(`opusplan ${override ? 'enabled' : 'disabled'}`, 'info');
			return Promise.resolve();
		},
	});

	pi.on('before_agent_start', async (_event, ctx) => {
		const { enabled, plan, execute } = readOpusplan(ctx.cwd);
		if (!(override ?? enabled ?? false)) return;
		const spec = isPlanning(ctx) ? plan : execute;
		const [provider, ...rest] = spec.split('/');
		const id = rest.join('/');
		if (ctx.model?.provider === provider && ctx.model?.id === id) return;
		const model = ctx.modelRegistry.find(provider, id);
		if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${spec}`, 'warning');
	});
}
