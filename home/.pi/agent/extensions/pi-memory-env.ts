import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { env } from 'node:process';

// providers where pi-memory's exit summary (one extra model call on quit) costs nothing extra
const FREE_PROVIDERS = new Set<string | undefined>(['ollama', 'claude-bridge']);

// pi-memory is configured only through environment variables, which it reads when needed rather than at load
const setExitSummary = (provider?: string) => {
	env.PI_MEMORY_EXIT_SUMMARY = FREE_PROVIDERS.has(provider) ? '1' : '0';
};

export default function (pi: ExtensionAPI) {
	if (env.PI_MEMORY_EXIT_SUMMARY !== undefined) return;
	setExitSummary();
	pi.on('session_start', (_event, ctx) => setExitSummary(ctx.model?.provider));
	pi.on('model_select', (event) => setExitSummary(event.model.provider));
}
