import type { ExtensionAPI, ExtensionFactory } from '@earendil-works/pi-coding-agent';

// an extension that holds things for its session: what it adds to the scope is released, last first, when the session
// ends. pi loads an extension instance per session, so a scope per instance is one per session
export const scoped =
	(factory: (pi: ExtensionAPI, scope: AsyncDisposableStack) => void): ExtensionFactory =>
	(pi) => {
		const scope = new AsyncDisposableStack();
		pi.on('session_shutdown', () => scope.disposeAsync());
		factory(pi, scope);
	};
