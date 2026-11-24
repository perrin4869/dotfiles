import { homedir } from 'node:os';
import { delimiter, join } from 'node:path';
import { env } from 'node:process';

export const xdgDataHome = () => env.XDG_DATA_HOME || join(homedir(), '.local', 'share');

// for this process and the commands it starts from now on
export function appendToPath(dir: string) {
	const path = (env.PATH ?? '').split(delimiter).filter(Boolean);
	if (!path.includes(dir)) env.PATH = [...path, dir].join(delimiter);
}

type EnvValues = Record<string, string | undefined>;

// undefined unsets a variable, which assigning undefined to process.env would not
function assignEnv(values: EnvValues) {
	for (const [name, value] of Object.entries(values)) {
		if (value === undefined) delete env[name];
		else env[name] = value;
	}
}

// sets environment variables until disposed, then restores them
export function overrideEnv(vars: EnvValues): Disposable {
	const saved = Object.fromEntries(Object.keys(vars).map((name) => [name, env[name]]));
	assignEnv(vars);
	return { [Symbol.dispose]: () => assignEnv(saved) };
}
