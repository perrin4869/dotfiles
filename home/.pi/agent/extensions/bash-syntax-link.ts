import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import type { Authorizer, PermissionsService } from '@gotgenes/pi-permission-system';

// An authorizer link for pi-permission-system: allows a bash ask when every unit still asking is shell syntax that
// runs no program itself. Commands nested in those units are units of their own, so one still asking keeps the ask.
// Enable with `"authorizerChain": ["bash-syntax"]` in pi-permission-system's config.json.
const LINK = 'bash-syntax';

// words that start a compound statement, which runs only the commands inside it
const COMPOUND = new Set(['for', 'while', 'until', 'if', 'case', 'select', '{', '(', '((', '[[', '!', 'function']);
// builtins that run no program and only change the shell's own state
const BUILTINS = new Set(['cd', 'pushd', 'popd', 'true', 'false', ':', 'test', '[', 'unset', 'shift', 'set']);
// builtins that only assign or declare variables
const DECLARATIONS = new Set(['export', 'local', 'declare', 'typeset', 'readonly']);

const ASSIGNMENT = /^[A-Za-z_]\w*(\[[^\]]*\])?\+?=/;
const NAME = /^[A-Za-z_]\w*$/;

// The top-level words of a command, with quotes and $(…), (…), ${…} and `…` kept inside their word; undefined when a
// redirect or operator sits at the top level, since those may do more than the command's own words.
function words(command: string): string[] | undefined {
	const result: string[] = [];
	let word = '';
	let depth = 0;
	let quote: string | undefined;
	for (let i = 0; i < command.length; i++) {
		const c = command[i];
		if (quote) {
			if (c === '\\' && quote !== "'") word += c + (command[++i] ?? '');
			else {
				if (c === quote) quote = undefined;
				word += c;
			}
			continue;
		}
		if (c === '\\') word += c + (command[++i] ?? '');
		else if (c === "'" || c === '"' || c === '`') {
			quote = c;
			word += c;
		} else if (c === '(' || (c === '{' && command[i - 1] === '$')) {
			depth++;
			word += c;
		} else if ((c === ')' || c === '}') && depth > 0) {
			depth--;
			word += c;
		} else if (depth > 0) word += c;
		else if (/\s/.test(c)) {
			if (word) result.push(word);
			word = '';
		} else if ('<>|&;'.includes(c)) return undefined;
		else word += c;
	}
	if (quote || depth > 0) return undefined;
	if (word) result.push(word);
	return result;
}

// whether a bash unit, as pi-permission-system reports it, runs no program of its own
function runsNoProgram(command: string): boolean {
	const first = command.trimStart().split(/\s/, 1)[0];
	// reserved words open a compound statement only as the first word, so the text alone is enough
	if (COMPOUND.has(first) || /^\w+\s*\(\)/.test(command.trimStart())) return true;
	const parts = words(command);
	if (!parts || parts.length === 0) return false;
	if (parts.every((part) => ASSIGNMENT.test(part))) return true;
	const [name, ...args] = parts;
	if (DECLARATIONS.has(name)) return args.every((arg) => ASSIGNMENT.test(arg) || NAME.test(arg) || arg.startsWith('-'));
	return BUILTINS.has(name);
}

// path and external_directory asks are left to the user; pi-permission-system would not honor an allow there anyway
const authorize: Authorizer['authorize'] = async ({ accessIntent }) =>
	accessIntent?.surface === 'bash' &&
	accessIntent.askingUnits?.length &&
	accessIntent.askingUnits.every(({ command }) => runsNoProgram(command))
		? { kind: 'allow' }
		: { kind: 'defer' };

// the slot getPermissionsService() reads; importing the package instead fails from ~/.pi/agent/extensions, where no
// node_modules resolves it
const SERVICES = Symbol.for('@gotgenes/pi-permission-system:session-services');

const servicesMap = (): Map<string, PermissionsService> | undefined => Reflect.get(globalThis, SERVICES);

export default function (pi: ExtensionAPI) {
	let dispose: (() => void) | undefined;
	let warned = false;

	// every extension has had its session_start by now, and no tool can have asked yet
	pi.on('before_agent_start', (_event, ctx) => {
		if (dispose) return;
		const service = servicesMap()?.get(ctx.sessionManager.getSessionId());
		if (service) {
			dispose = service.registerAuthorizer(LINK, authorize);
			return;
		}
		// staying quiet here is what made a link that never registered look like a working one
		if (warned) return;
		warned = true;
		ctx.ui.notify('bash-syntax: pi-permission-system published no service, so the link is not registered', 'warning');
	});

	pi.on('session_shutdown', () => {
		dispose?.();
		dispose = undefined;
		warned = false;
	});
}
