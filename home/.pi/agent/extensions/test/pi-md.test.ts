import assert from 'node:assert/strict';
import { readdir, readFile } from 'node:fs/promises';
import { findPackageJSON } from 'node:module';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import type { TObject } from 'typebox';

const ROOT = join(import.meta.dirname, '..');
type Section = { key: string; schema: TObject };

// every `section.field` the extensions read through defineSettings
async function definedFields() {
	const fields = new Set<string>();
	for (const file of (await readdir(ROOT)).filter((name) => name.endsWith('.ts'))) {
		const { readSettings }: { readSettings?: Section } = await import(join(ROOT, file));
		for (const field of Object.keys(readSettings?.schema.properties ?? {})) fields.add(`${readSettings?.key}.${field}`);
	}
	return fields;
}

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
	assert.deepEqual((await definedFields()).difference(await documentedFields()), new Set());
});
