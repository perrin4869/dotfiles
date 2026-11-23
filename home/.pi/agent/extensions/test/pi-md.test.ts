import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import { findPackageJSON } from 'node:module';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { definedSettings } from '../lib/settings.ts';
import { overrideEnv, startSession } from './harness.ts';

const ROOT = join(import.meta.dirname, '..');

// every `section.field` set in PI.md's JSON examples
async function documentedFields() {
	// PI.md sits beside the workspace root's package.json, the nearest one above the extensions package
	const workspace = findPackageJSON(new URL('../..', import.meta.url));
	assert.ok(workspace);
	const readme = await readFile(join(dirname(workspace), 'PI.md'), 'utf8');
	const examples = [...readme.matchAll(/```json\n([\s\S]*?)```/g)].map(([, json]) => JSON.parse(json));
	return new Set(
		examples.flatMap((example) =>
			Object.entries(example).flatMap(([key, value]) =>
				typeof value === 'object' && value !== null ? Object.keys(value).map((field) => `${key}.${field}`) : [],
			),
		),
	);
}

test('PI.md shows every settings field in an example', async () => {
	// the flag has to be set before the boot, which is what loads the extensions and runs their defineSettings
	using records = overrideEnv({ PI_SETTINGS_RECORD: '1' });
	// every extension pi would load from the directory, so a new one is covered without touching this test
	await using running = await startSession({
		extensions: (await readdir(ROOT))
			.filter((name) => name.endsWith('.ts'))
			.toSorted()
			.map((name) => join(ROOT, name)),
	});

	const defined = new Set(
		definedSettings()
			.entries()
			.flatMap(([key, schema]) => Object.keys(schema.properties).map((field) => `${key}.${field}`)),
	);
	// without this the comparison passes when nothing was recorded at all
	assert.ok(defined.size > 0, 'nothing was recorded: is PI_SETTINGS_RECORD set before the boot?');
	assert.deepEqual(defined.difference(await documentedFields()), new Set());
});
