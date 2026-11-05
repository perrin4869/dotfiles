import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';

// Tools can't be unregistered, so withdraw one by registering a hidden tool under its name: hidden tools are
// unreachable and setActiveTools ignores them, so the package that owns the tool can't put it back. Call it once
// every extension has registered its tools, such as on session_start, so it replaces theirs whatever the load order.
export function withdrawTool(pi: ExtensionAPI, name: string, reason: string) {
	pi.registerTool({
		name,
		label: name,
		description: reason,
		exposure: 'hidden',
		parameters: Type.Object({}),
		execute: () => Promise.reject(new Error(reason)),
	});
}
