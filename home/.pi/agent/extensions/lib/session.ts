import type { CustomEntry, ExtensionContext } from '@earendil-works/pi-coding-agent';
import type { Static, TSchema } from 'typebox';
import { Value } from 'typebox/value';

// the data of the latest custom entry of this type on the current branch, if it matches the schema;
// packages that append their state as custom entries treat the latest one as current
export function latestEntry<T extends TSchema>(
	ctx: ExtensionContext,
	customType: string,
	schema: T,
): Static<T> | undefined {
	const entry = ctx.sessionManager
		.getBranch()
		.findLast((e): e is CustomEntry => e.type === 'custom' && e.customType === customType);
	return entry !== undefined && Value.Check(schema, entry.data) ? entry.data : undefined;
}
