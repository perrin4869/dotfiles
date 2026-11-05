import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import type { Static, TObject } from 'typebox';
import { Value } from 'typebox/value';

// A top-level key of pi's settings.json owned by one of our extensions, with a default for every field.
// pi.getSettings() merges project settings over global ones, field by field, and only once the project is trusted.
export function defineSettings<T extends TObject>(key: string, schema: T) {
	// warn once per problem rather than on every read
	const reported = new Set<string>();

	return {
		key,
		schema,
		read(pi: ExtensionAPI, ctx: ExtensionContext): Static<T> {
			// pi's Settings type lists only pi's own keys
			const raw: unknown = Reflect.get(pi.getSettings(), key);
			const section = Value.Default(schema, structuredClone(raw ?? {}));
			if (Value.Check(schema, section)) return section;

			const problems = Value.Errors(schema, section).map(
				({ instancePath, message }) => `${key}${instancePath.replaceAll('/', '.')} ${message}`,
			);
			const report = problems.join('; ');
			if (!reported.has(report)) {
				reported.add(report);
				ctx.ui.notify(`ignoring invalid settings: ${report}`, 'warning');
			}
			return Value.Create(schema);
		},
	};
}
