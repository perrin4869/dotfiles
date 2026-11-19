import assert from 'node:assert/strict';
import { test } from 'node:test';
import { memo, memoGlobal } from '../lib/memo.ts';

test('asks its loader once, and shares a load still in flight', async () => {
	let loads = 0;
	const load = memo(async () => {
		loads += 1;
		await new Promise((tick) => setImmediate(tick));
		return 'value';
	});
	assert.deepEqual(await Promise.all([load(), load()]), ['value', 'value']);
	assert.equal(await load(), 'value');
	assert.equal(loads, 1);
});

test('hands every caller the same rejection', async () => {
	let loads = 0;
	const load = memo(async () => {
		loads += 1;
		throw new Error('failed');
	});
	await assert.rejects(load(), /failed/);
	await assert.rejects(load(), /failed/);
	assert.equal(loads, 1);
});

test('caches an answer of undefined like any other', async () => {
	let loads = 0;
	const load = memo(async () => {
		loads += 1;
		return undefined;
	});
	assert.equal(await load(), undefined);
	assert.equal(await load(), undefined);
	assert.equal(loads, 1);
});

test('uses the first call arguments', async () => {
	const load = memo(async (name: string) => 'hello ' + name);
	assert.equal(await load('first'), 'hello first');
	assert.equal(await load('second'), 'hello first');
});

test('a global memo is shared by every wrapper made for its key', async () => {
	const key = Symbol.for('pi-extensions:test:memo-global');
	let loads = 0;
	const load = async () => {
		loads += 1;
		return 'value';
	};
	assert.deepEqual(await Promise.all([memoGlobal(load, key)(), memoGlobal(load, key)()]), ['value', 'value']);
	assert.equal(loads, 1);
	Reflect.deleteProperty(globalThis, key);
});
