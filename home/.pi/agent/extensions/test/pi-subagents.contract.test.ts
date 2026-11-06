import assert from 'node:assert/strict';
import { test } from 'node:test';
import { type TSchema, Type } from 'typebox';
import { Value } from 'typebox/value';
import { requestsShare } from '../no-subagent-share.ts';
import { packageModule } from './harness.ts';

// no-subagent-share mirrors where pi-subagents reads `share`; these fail when an update changes that

type Options = { flattenSubagentToolOptions: (params: Record<string, unknown>) => Record<string, unknown> };
type Schemas = {
	SubagentFlatParams: TSchema;
	SubagentOptionParams: TSchema;
	SubagentParams: TSchema;
};

const { flattenSubagentToolOptions } = await packageModule<Options>(
	'pi-subagents',
	'src/extension/subagent-options.js',
);
const { SubagentFlatParams, SubagentOptionParams, SubagentParams } = await packageModule<Schemas>(
	'pi-subagents',
	'src/extension/schemas.js',
);

// whether pi-subagents would upload the session for this tool input
function shares(input: Record<string, unknown>) {
	try {
		return flattenSubagentToolOptions(input).share === true;
	} catch {
		// pi-subagents rejects the call
		return false;
	}
}

// the parts of a JSON schema that can declare nested properties
const SchemaNode = Type.Object({
	properties: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
	items: Type.Optional(Type.Unknown()),
	anyOf: Type.Optional(Type.Array(Type.Unknown())),
	oneOf: Type.Optional(Type.Array(Type.Unknown())),
	allOf: Type.Optional(Type.Array(Type.Unknown())),
});

// the dotted paths of every property called `share` in a JSON schema
function sharePaths(schema: unknown, path = ''): string[] {
	if (!Value.Check(SchemaNode, schema)) return [];
	const { properties = {}, items, anyOf = [], oneOf = [], allOf = [] } = schema;
	return [
		...Object.entries(properties).flatMap(([key, value]) => {
			const at = path ? `${path}.${key}` : key;
			return [...(key === 'share' ? [at] : []), ...sharePaths(value, at)];
		}),
		...sharePaths(items, `${path}[]`),
		...[...anyOf, ...oneOf, ...allOf].flatMap((variant) => sharePaths(variant, path)),
	];
}

// the model's own parameters carry share only through `options`, whose keys are checked against their own schema,
// and flat callers pass it at the top level; the blocker checks both places
test('share is declared at the top level of the flat and option schemas only', () => {
	assert.deepEqual(sharePaths(SubagentFlatParams), ['share']);
	assert.deepEqual(sharePaths(SubagentOptionParams), ['share']);
	assert.deepEqual(sharePaths(SubagentParams), []);
});

test('a share nested in a task is ignored', () => {
	// pi-subagents reads share only where the tests above look; if this starts sharing, the blocker needs the nested
	// check too
	assert.equal(shares({ agent: 'worker', tasks: [{ agent: 'a', task: 'x', share: true }] }), false);
});

test('blocks every input pi-subagents would share', () => {
	const inputs = [
		{},
		{ share: true },
		{ share: 'true' },
		{ share: false },
		{ options: { share: true } },
		{ options: { share: 'true' } },
		{ options: { share: 'TRUE' } },
		{ options: { share: 1 } },
		{ options: { share: '1' } },
		{ options: { share: 'false' } },
		{ options: { share: 'yes' } },
		{ options: { share: true, async: true } },
		{ share: true, options: { share: true } },
		{ options: 'share' },
	];
	for (const input of inputs) {
		const call = { agent: 'worker', task: 'x', ...input };
		if (shares(call)) assert.ok(requestsShare(call), `not blocked: ${JSON.stringify(input)}`);
	}
	// the corpus has to reach pi-subagents' share path at all, or the loop proves nothing
	assert.ok(inputs.some((input) => shares({ agent: 'worker', task: 'x', ...input })));
});
