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

// A reader for a top-level key of pi's settings.json owned by one of our extensions, with a default for every field.
// pi.getSettings() merges project settings over global ones, field by field, and only once the project is trusted.
export function defineSettings<T extends TObject>(key: string, schema: T) {
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
