import { readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { type TObject, Type } from 'typebox';

const ROOT = join(import.meta.dirname, '..');
export const SCHEMA_FILE = join(ROOT, 'settings.schema.json');

type Section = { key: string; schema: TObject };

// pi's settings.json schema, extended with the sections our extensions read through defineSettings, as JSON
export async function settingsSchema() {
	const properties: Record<string, TObject> = {};
	for (const file of readdirSync(ROOT)
		.filter((name) => name.endsWith('.ts'))
		.toSorted()) {
		const { readSettings }: { readSettings?: Section } = await import(join(ROOT, file));
		// every field has a default, so a settings file may set any subset
		if (readSettings) properties[readSettings.key] = Type.Partial(readSettings.schema);
	}
	return JSON.stringify({
		$schema: 'https://json-schema.org/draft/2020-12/schema',
		allOf: [{ $ref: 'https://pi.dev/schemas/settings.schema.json' }],
		properties,
	});
}

if (import.meta.main) writeFileSync(SCHEMA_FILE, `${await settingsSchema()}\n`);
