import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Type } from 'typebox';
import { parseModelRef } from '../lib/models.ts';
import { describeErrors } from '../lib/settings.ts';

test('parseModelRef splits at the first slash only', () => {
	assert.deepEqual(parseModelRef('ollama/gemma4:12b'), ['ollama', 'gemma4:12b']);
	assert.deepEqual(parseModelRef('openrouter/qwen/qwen3-coder'), ['openrouter', 'qwen/qwen3-coder']);
});

test('describeErrors names each invalid field under its settings key', () => {
	const schema = Type.Object({ enabled: Type.Boolean(), nested: Type.Object({ ref: Type.String() }) });
	assert.equal(
		describeErrors('demo', schema, { enabled: 'yes', nested: { ref: 1 } }),
		'demo.enabled must be boolean; demo.nested.ref must be string',
	);
});

test('describeErrors is empty for valid settings', () => {
	assert.equal(describeErrors('demo', Type.Object({ enabled: Type.Boolean() }), { enabled: true }), '');
});
