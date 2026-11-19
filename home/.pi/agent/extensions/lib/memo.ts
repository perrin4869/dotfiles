/**
 * A function that asks its loader on the first call and hands every caller the same promise, resolved or rejected.
 * The first call's arguments are the ones used.
 */
export function memo<A extends unknown[], T>(load: (...args: A) => Promise<T>): (...args: A) => Promise<T> {
	let pending: Promise<T> | undefined;
	return (...args) => (pending ??= load(...args));
}

/**
 * The same, kept on globalThis under `key`, for a value that has to outlive a module evaluation: pi re-evaluates
 * extension modules on every reload and session replacement, and some loads hold resources nothing can free.
 */
export function memoGlobal<A extends unknown[], T>(
	load: (...args: A) => Promise<T>,
	key: symbol,
): (...args: A) => Promise<T> {
	return (...args) => {
		const pending: Promise<T> | undefined = Reflect.get(globalThis, key);
		if (pending !== undefined) return pending;
		const started = load(...args);
		Reflect.set(globalThis, key, started);
		return started;
	};
}
