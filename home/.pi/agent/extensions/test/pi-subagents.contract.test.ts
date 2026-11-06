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
function sharesReported(input: Record<string, unknown>) {
	try {
		return flattenSubagentToolOptions(input).share === true;
	} catch {
		// pi-subagents rejects the call
		return false;
	}
}

// Each row: the tool input, whether pi-subagents' own option handling reports a share, and whether the blocker
// blocks. pi coerces only declared parameters, and `share` is not one, so a string at the top level shares nowhere.
const cases: [input: Record<string, unknown>, shares: boolean, blocked: boolean][] = [
	[{}, false, false],
	[{ share: true }, true, true],
	[{ share: 'true' }, false, false],
	[{ share: false }, false, false],
	[{ options: { share: true } }, true, true],
	[{ options: { share: 'true' } }, true, true],
	[{ options: { share: 'TRUE' } }, true, true],
	[{ options: { share: 1 } }, true, true],
	[{ options: { share: '1' } }, true, true],
	[{ options: { share: 'false' } }, false, false],
	[{ options: { share: 'yes' } }, false, false],
	[{ options: { share: true, fast: true } }, true, true],
	[{ share: true, options: { share: true } }, true, true],
	// pi-subagents ignores a share nested in a task; if this starts sharing, the blocker needs the nested check
	[{ tasks: [{ agent: 'a', task: 'x', share: true }] }, false, false],
];

test('blocks every input pi-subagents would share', () => {
	for (const [input, shares, blocked] of cases) {
		const call = { agent: 'worker', task: 'x', ...input };
		const where = JSON.stringify(input);
		assert.equal(sharesReported(call), shares, `pi-subagents on ${where}`);
		assert.equal(requestsShare(call), blocked, `blocker on ${where}`);
	}
	// every way pi-subagents shares has to be blocked
	assert.ok(cases.every(([, shares, blocked]) => !shares || blocked));
});
