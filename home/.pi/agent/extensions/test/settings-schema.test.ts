import assert from 'node:assert/strict';
import { test } from 'node:test';
import committed from '../settings.schema.json' with { type: 'json' };
import { settingsSchema } from '../scripts/settings-schema.ts';

test('settings.schema.json matches the extensions (regenerate with npm run schema)', async () => {
	assert.deepEqual(committed, JSON.parse(await settingsSchema()));
});
