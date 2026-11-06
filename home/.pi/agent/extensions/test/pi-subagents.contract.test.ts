import assert from 'node:assert/strict';
import { test } from 'node:test';
import { requestsShare } from '../no-subagent-share.ts';
import { packageModule } from './harness.ts';

// no-subagent-share mirrors where pi-subagents reads `share` and how it converts the value; these fail when an
// update changes either

type Options = { flattenSubagentToolOptions: (params: Record<string, unknown>) => Record<string, unknown> };

const { flattenSubagentToolOptions } = await packageModule<Options>(
	'pi-subagents',
	'src/extension/subagent-options.js',
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

// every way pi-subagents decides to share, and the near misses the blocker must not confuse for one
const cases: [input: Record<string, unknown>, shares: boolean][] = [
	[{}, false],
	[{ share: true }, true],
	// pi converts a declared parameter before the tool runs, which is where a string `share` would become true
	[{ share: 'true' }, false],
	[{ share: false }, false],
	[{ options: { share: true } }, true],
	[{ options: { share: 'true' } }, true],
	[{ options: { share: 'TRUE' } }, true],
	[{ options: { share: 1 } }, true],
	[{ options: { share: '1' } }, true],
	[{ options: { share: 'false' } }, false],
	[{ options: { share: 'yes' } }, false],
	[{ options: { share: true, fast: true } }, true],
	[{ share: true, options: { share: true } }, true],
	// pi-subagents ignores a share nested in a task; if this starts sharing, the blocker needs the nested check
	[{ tasks: [{ agent: 'a', task: 'x', share: true }] }, false],
];

test('blocks every input pi-subagents would share', () => {
	for (const [input, expected] of cases) {
		const call = { agent: 'worker', task: 'x', ...input };
		const where = JSON.stringify(input);
		assert.equal(shares(call), expected, `pi-subagents on ${where}`);
		if (expected) assert.ok(requestsShare(call), `not blocked: ${where}`);
	}
	// the blocker may also block what pi-subagents rejects, but it has to block every way it shares
	assert.ok(cases.some(([, expected]) => expected));
});
