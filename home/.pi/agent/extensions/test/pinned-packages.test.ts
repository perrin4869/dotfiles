import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Type } from 'typebox';
import { Value } from 'typebox/value';
import settings from '../../settings.json' with { type: 'json' };
import extensions from '../package.json' with { type: 'json' };
import { packageManifest } from './harness.ts';

const PINNED = /^npm:((?:@[^/@]+\/)?[^@]+)@(\d[^@]*)$/;

// pi installs a package only if its package.json has a `pi` section, so this tells pi packages from the SDK and tooling
const PiPackage = Type.Object({ version: Type.String(), pi: Type.Object({}) });

// the tests load these packages, so they must be the versions pi installs
test('installed pi packages match the versions pinned in settings.json', async () => {
	const pinned = new Map(
		settings.packages.flatMap((spec) => {
			const match = PINNED.exec(spec);
			return match ? [[match[1], match[2]] as const] : [];
		}),
	);
	for (const name of Object.keys(extensions.devDependencies)) {
		const manifest = await packageManifest(name);
		if (Value.Check(PiPackage, manifest)) assert.equal(manifest.version, pinned.get(name), name);
	}
});
