import { readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { env } from 'node:process';
import { Type, type TObject } from 'typebox';
import { definedSettings } from '../lib/settings.ts';

const ROOT = join(import.meta.dirname, '..');
export const SCHEMA_FILE = join(ROOT, 'settings.schema.json');

// pi's settings.json schema, extended with the sections our extensions read through defineSettings, as JSON
export async function settingsSchema() {
	// what makes defineSettings record its section, as the extensions load
	env.PI_SETTINGS_RECORD = '1';
	for (const file of readdirSync(ROOT)
		.filter((name) => name.endsWith('.ts'))
		.toSorted()) {
		await import(join(ROOT, file));
	}

	const properties: Record<string, TObject> = {};
	for (const [key, schema] of definedSettings()) {
		// every field has a default, so a settings file may set any subset
		properties[key] = Type.Partial(schema);
	}
	return JSON.stringify({
		$schema: 'https://json-schema.org/draft/2020-12/schema',
		allOf: [{ $ref: 'https://pi.dev/schemas/settings.schema.json' }],
		properties,
	});
}

if (import.meta.main) writeFileSync(SCHEMA_FILE, `${await settingsSchema()}\n`);
