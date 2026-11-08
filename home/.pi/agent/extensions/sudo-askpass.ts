import { homedir } from 'node:os';
import { join } from 'node:path';
import { env } from 'node:process';

// Claude Code gets SUDO_ASKPASS from its settings; pi has no equivalent for environment variables, and sudo has no
// terminal to prompt on, so without an askpass helper it can only fail.
export default function () {
	env.SUDO_ASKPASS ??= join(homedir(), '.local', 'bin', 'askpass');
}
