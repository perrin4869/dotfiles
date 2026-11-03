import { type ExtensionAPI, type ExtensionContext, SettingsManager } from "@earendil-works/pi-coding-agent";

// Claude Code's opusplan for pi-plan-mode: one model while planning, another otherwise.
// Enable per project with `"opusplan": { "enabled": true }` in .pi/settings.json, or toggle with /opusplan.
type OpusplanSettings = { enabled?: boolean; plan?: string; execute?: string };

const DEFAULTS = { plan: "claude-bridge/claude-opus-5-5", execute: "claude-bridge/claude-sonnet-5-5" };
// pi-plan-mode persists its state as custom session entries of this type
const PLAN_STATE_ENTRY = "plan-mode-state";

function readSettings(cwd: string): OpusplanSettings {
	const manager = SettingsManager.create(cwd);
	const pick = (s: Record<string, unknown>) => (s.opusplan ?? {}) as OpusplanSettings;
	return { ...pick(manager.getGlobalSettings()), ...pick(manager.getProjectSettings()) };
}

function isPlanning(ctx: ExtensionContext): boolean {
	const entries = ctx.sessionManager.getBranch() as { type?: string; customType?: string; data?: { enabled?: boolean } }[];
	for (let i = entries.length - 1; i >= 0; i--) {
		if (entries[i].type === "custom" && entries[i].customType === PLAN_STATE_ENTRY) return entries[i].data?.enabled === true;
	}
	return false;
}

export default function (pi: ExtensionAPI) {
	// set by /opusplan; overrides the settings for the rest of this pi process, including fresh implementation sessions
	let override: boolean | undefined;

	pi.registerCommand("opusplan", {
		description: "Toggle opusplan: plan on one model, implement on another",
		handler: async (_args, ctx) => {
			override = !(override ?? readSettings(ctx.cwd).enabled === true);
			ctx.ui.notify(`opusplan ${override ? "enabled" : "disabled"}`, "info");
		},
	});

	pi.on("before_agent_start", async (_event, ctx) => {
		const settings = readSettings(ctx.cwd);
		if (!(override ?? settings.enabled === true)) return;
		const spec = isPlanning(ctx) ? (settings.plan ?? DEFAULTS.plan) : (settings.execute ?? DEFAULTS.execute);
		const [provider, ...rest] = spec.split("/");
		const id = rest.join("/");
		if (ctx.model?.provider === provider && ctx.model?.id === id) return;
		const model = ctx.modelRegistry.find(provider, id);
		if (!model || !(await pi.setModel(model))) ctx.ui.notify(`opusplan: cannot use ${spec}`, "warning");
	});
}
