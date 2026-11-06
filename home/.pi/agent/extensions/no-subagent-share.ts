import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { Value } from 'typebox/value';

// pi-subagents uploads the session to a gist via `gh` itself, so the bash permission rules never see it. It takes
// `share` at the top level, where it compares strictly, or in `options`, whose values it converts with TypeBox
// first, so options.share: "true" shares too:
// https://github.com/nicobailon/pi-subagents/blob/v0.84.0/src/extension/subagent-options.ts#L50
// https://github.com/nicobailon/pi-subagents/blob/v0.84.0/src/runs/foreground/subagent-executor.ts#L7658
// pi coerces only declared parameters, and `share` is not one of the tool's, so a string there stays a string
const ShareRequest = Type.Object({
	share: Type.Optional(Type.Unknown()),
	options: Type.Optional(Type.Object({ share: Type.Optional(Type.Unknown()) })),
});

const isTrue = (value: unknown) => Value.Convert(Type.Boolean(), value) === true;

export function requestsShare(input: unknown) {
	if (!Value.Check(ShareRequest, input)) return false;
	return input.share === true || isTrue(input.options?.share);
}

export default function (pi: ExtensionAPI) {
	pi.on('tool_call', (event) =>
		event.toolName === 'subagent' && requestsShare(event.input)
			? { block: true, reason: 'sharing subagent sessions is disabled; use /share explicitly' }
			: undefined,
	);
}
