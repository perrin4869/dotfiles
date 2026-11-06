import assert from 'node:assert/strict';
import { test } from 'node:test';
import { requestsShare } from '../no-subagent-share.ts';
import { packageModule } from './harness.ts';

// no-subagent-share mirrors where pi-subagents reads `share` and how it converts the value; these fail when an
// update changes either. They cover the tool input, which 0.84.0 makes the only way to share; a release that adds
// another way (a config default, a slash command) passes them, so read its changes when bumping it.

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

// Each row: a tool input and whether pi-subagents shares it. The blocker has to answer the same: blocking a call
// that would not share rejects work pi-subagents would run, and missing one uploads the session.
const cases: [input: Record<string, unknown>, shares: boolean][] = [
	[{}, false],
	[{ share: true }, true],
	// pi coerces only declared parameters, and `share` is not one, so a string at the top level shares nowhere
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

test('blocks exactly the inputs pi-subagents shares', () => {
	for (const [input, shares] of cases) {
		const call = { agent: 'worker', task: 'x', ...input };
		const where = JSON.stringify(input);
		assert.equal(sharesReported(call), shares, `pi-subagents on ${where}`);
		assert.equal(requestsShare(call), shares, `blocker on ${where}`);
	}
	// the corpus has to reach both answers, or a blocker that always said the same would pass
	assert.ok(cases.some(([, shares]) => shares) && cases.some(([, shares]) => !shares));
});
