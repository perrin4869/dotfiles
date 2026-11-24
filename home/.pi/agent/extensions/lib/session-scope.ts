import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

// what an extension holds for its session, released last first when the session ends; pi loads an extension instance per
// session, so one scope per instance is one per session
export function sessionScope(pi: ExtensionAPI): AsyncDisposableStack {
	const scope = new AsyncDisposableStack();
	pi.on('session_shutdown', () => scope.disposeAsync());
	return scope;
}
