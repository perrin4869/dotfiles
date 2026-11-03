import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { env } from 'node:process';

// pi-memory is configured only through environment variables, which it reads when needed rather than at load
export default function (_pi: ExtensionAPI) {
	// skip the extra model call it makes on every quit to summarize the session
	env.PI_MEMORY_EXIT_SUMMARY ??= '0';
}
