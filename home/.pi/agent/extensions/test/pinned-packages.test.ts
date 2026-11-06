import assert from 'node:assert/strict';
import { test } from 'node:test';
import settings from '../../settings.json' with { type: 'json' };
import extensions from '../package.json' with { type: 'json' };

const PINNED = /^npm:((?:@[^/@]+\/)?[^@]+)@(\d[^@]*)$/;

// the contract tests load these packages, so they must be the versions pi installs
test('tested packages match the versions pinned in settings.json', () => {
	const pinned = new Map(
		settings.packages.flatMap((spec) => {
			const match = PINNED.exec(spec);
			return match ? [[match[1], match[2]] as const] : [];
		}),
	);
	const tested = Object.entries(extensions.devDependencies).filter(([name]) => pinned.has(name));
	assert.deepEqual(tested.map(([name]) => name).toSorted(), [
		'@juicesharp/rpiv-advisor',
		'@narumitw/pi-plan-mode',
		'pi-memory',
		'pi-subagents',
	]);
	for (const [name, version] of tested) assert.equal(version, pinned.get(name), name);
});
