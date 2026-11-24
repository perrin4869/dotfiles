import assert from 'node:assert/strict';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { env } from 'node:process';
import { test } from 'node:test';
import { overrideEnv } from '#lib/env';
import { extension, startSession } from './harness.ts';

const ASKPASS = join(homedir(), '.local', 'bin', 'askpass');

test('points sudo at the askpass helper', async () => {
	using restore = overrideEnv({ SUDO_ASKPASS: undefined });
	await using h = await startSession({ extensions: [extension('sudo-askpass')] });
	assert.equal(env.SUDO_ASKPASS, ASKPASS);
});

test('keeps one that is already set', async () => {
	using restore = overrideEnv({ SUDO_ASKPASS: '/somewhere/else' });
	await using h = await startSession({ extensions: [extension('sudo-askpass')] });
	assert.equal(env.SUDO_ASKPASS, '/somewhere/else');
});
