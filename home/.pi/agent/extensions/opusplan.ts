import { type ExtensionAPI, type ExtensionContext, SettingsManager } from '@earendil-works/pi-coding-agent';

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or toggle with /opusplan.
type OpusplanSettings = { enabled?: boolean; plan?: string; execute?: string };

const DEFAULTS = { plan: 'claude-bridge/claude-opus-5-5', execute: 'claude-bridge/claude-sonnet-5-5' };
// pi-plan-mode persists its state as custom session entries of this type
const PLAN_STATE_ENTRY = 'plan-mode-state';

function pick(settings: object): OpusplanSettings {
	const value = 'opusplan' in settings ? settings.opusplan : undefined;
	if (typeof value !== 'object' || value === null) return {};
	return {
		enabled: 'enabled' in value && typeof value.enabled === 'boolean' ? value.enabled : undefined,
		plan: 'plan' in value && typeof value.plan === 'string' ? value.plan : undefined,
		execute: 'execute' in value && typeof value.execute === 'string' ? value.execute : undefined,
	};
}

function readSettings(cwd: string): OpusplanSettings {
	const manager = SettingsManager.create(cwd);
	const global = pick(manager.getGlobalSettings());
	const project = pick(manager.getProjectSettings());
	return {
		enabled: project.enabled ?? global.enabled,
		plan: project.plan ?? global.plan,
		execute: project.execute ?? global.execute,
	};
}

function isPlanning(ctx: ExtensionContext): boolean {
	const entries = ctx.sessionManager.getBranch();
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry.type !== 'custom' || entry.customType !== PLAN_STATE_ENTRY) continue;
		const data = entry.data;
		return typeof data === 'object' && data !== null && 'enabled' in data && data.enabled === true;
	}
	return false;
}

export default function (pi: ExtensionAPI) {
	// set by /opusplan; overrides the settings for the rest of this pi process, including fresh implementation sessions
	let override: boolean | undefined;

	pi.registerCommand('opusplan', {
		description: 'Toggle opusplan: plan on one model, implement on another',
		handler: (_args, ctx) => {
			override = !(override ?? readSettings(ctx.cwd).enabled === true);
			ctx.ui.notify(`opusplan ${override ? 'enabled' : 'disabled'}`, 'info');
			return Promise.resolve();
		},
	});

	pi.on('before_agent_start', async (_event, ctx) => {
		const settings = readSettings(ctx.cwd);
		if (!(override ?? settings.enabled === true)) return;
		const spec = isPlanning(ctx) ? (settings.plan ?? DEFAULTS.plan) : (settings.execute ?? DEFAULTS.execute);
		const [provider, ...rest] = spec.split('/');
		const id = rest.join('/');
		if (ctx.model?.provider === provider && ctx.model?.id === id) return;
		const model = ctx.modelRegistry.find(provider, id);
		if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${spec}`, 'warning');
	});
}
