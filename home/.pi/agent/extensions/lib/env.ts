import { homedir } from 'node:os';
import { delimiter, join } from 'node:path';
import { env } from 'node:process';

export const xdgDataHome = () => env.XDG_DATA_HOME || join(homedir(), '.local', 'share');

// for this process and the commands it starts from now on
export function appendToPath(dir: string) {
	const path = (env.PATH ?? '').split(delimiter).filter(Boolean);
	if (!path.includes(dir)) env.PATH = [...path, dir].join(delimiter);
}
