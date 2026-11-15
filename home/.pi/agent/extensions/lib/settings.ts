import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import type { Static, TObject, TSchema } from 'typebox';
import { Value } from 'typebox/value';

// a predicate that is true only the first time it sees each value
function firstSeen() {
	const seen = new Set<string>();
	return (value: string) => {
		if (seen.has(value)) return false;
		seen.add(value);
		return true;
	};
}

// validation errors as `key.field message`, joined into one line
const describeErrors = (key: string, schema: TSchema, value: unknown) =>
	Value.Errors(schema, value)
		.map(({ instancePath, message }) => `${key}${instancePath.replaceAll('/', '.')} ${message}`)
		.join('; ');

// The settings sections recorded in this process, keyed by section, with their top-level fields; only PI_SETTINGS_RECORD
// fills this, so nothing accumulates in pi itself. The slot is on globalThis through Symbol.for because pi loads
// extensions through its own module graph: a module-level one is an instance the extensions never fill.
const DEFINED = Symbol.for('pi-extensions:settings');

const definedMap = (): Map<string, string[]> | undefined => Reflect.get(globalThis, DEFINED);

/** @return the sections recorded so far; empty unless PI_SETTINGS_RECORD was set before pi loaded the extensions */
export function definedSettings(): Map<string, string[]> {
	const existing = definedMap();
	if (existing) return existing;
	const created = new Map<string, string[]>();
	Reflect.set(globalThis, DEFINED, created);
	return created;
}

// A reader for a top-level key of pi's settings.json owned by one of our extensions, with a default for every field.
// pi.getSettings() merges project settings over global ones, field by field, and only once the project is trusted.
export function defineSettings<T extends TObject>(key: string, schema: T) {
	if (process.env.PI_SETTINGS_RECORD !== undefined) definedSettings().set(key, Object.keys(schema.properties));
	// warn once per problem rather than on every read
	const unreported = firstSeen();

	return (pi: ExtensionAPI, ctx: ExtensionContext): Static<T> => {
		// pi's Settings type lists only pi's own keys; getSettings() returns a copy, so Value.Default may fill it in place
		const raw: unknown = Reflect.get(pi.getSettings(), key);
		const section = Value.Default(schema, raw ?? {});
		if (Value.Check(schema, section)) return section;

		const problems = describeErrors(key, schema, section);
		if (unreported(problems)) ctx.ui.notify(`ignoring invalid settings: ${problems}`, 'warning');
		return Value.Create(schema);
	};
}
