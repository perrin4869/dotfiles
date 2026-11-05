import { SettingsManager } from '@earendil-works/pi-coding-agent';
import type { Static, TObject } from 'typebox';
import { Value } from 'typebox/value';

export const isRecord = (value: unknown): value is Record<string, unknown> =>
	typeof value === 'object' && value !== null && !Array.isArray(value);

// our extensions read their own top-level key of pi's settings.json; project fields override global ones, and a
// section that doesn't match its schema is ignored
export function readSettings<T extends TObject>(cwd: string, key: string, schema: T): Partial<Static<T>> {
	const section = (settings: unknown) => {
		const value = isRecord(settings) ? settings[key] : undefined;
		return Value.Check(schema, value) ? value : {};
	};
	const manager = SettingsManager.create(cwd);
	return { ...section(manager.getGlobalSettings()), ...section(manager.getProjectSettings()) };
}
