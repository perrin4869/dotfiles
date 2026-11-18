// ===================================================================================================================
// DELETE THIS EXTENSION IF pi-permission-system STOPS ASKING ABOUT SHELL-SYNTAX UNITS: gotgenes/pi-packages#1129.
//
// The gap: pi-permission-system enumerates an assignment (`T=$(mktemp -d)`) and a compound statement
// (`for …; do …; done`) as command units of their own, besides the commands inside them. A wildcard pattern cannot say
// "this unit runs no program, judge what is inside it", so the wrapper lands on `*: ask` and prompts even when every
// command it contains is already decided. This link allows those units and nothing else.
//
// What would retire this file is a change inside the package, one of two shapes:
//   1. the enumerator stops emitting syntax-only units, or
//   2. they gain a floor exemption, the way `time`, `timeout`, `nice`, `stdbuf` and `setsid` did in #963.
//      FloorExemption in src/types.ts names core-reader, execution-modifier and no-command today; a syntax member would
//      be this case.
// Either way, delete this file, its test, and the "bash-syntax" entry in the authorizerChain.
//
// Adjacent upstream work that would NOT retire it on its own:
//   #804 structured command rules: changes how a rule names a command, not which units ask. A structured rule still
//        needs a unit to match, and a syntax-only unit matches nothing.
//   #620 allow-capable adjudicator: builds a link for opaque commands (`bash -c`, `eval`, unparsed subtrees), a
//        different gap. The chain seam it builds on (#599) is the seam this link uses.
//   #1101 tracks the verdict that would let a link accept part of a chain (`allow_units`). Until then this link can
//        only allow a whole ask, so a chain that mixes syntax with a command still asking prompts for both.
//   #1128 matches a floor-exempt wrapper's inner command without its spellings: the same gap, seen from `timeout`.
// ===================================================================================================================

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import type { Authorizer } from '@gotgenes/pi-permission-system';
import { fileURLToPath } from 'node:url';
import { Language, type Node, Parser } from 'web-tree-sitter';

// An authorizer link for pi-permission-system: allows a bash ask when every unit still asking is shell syntax that
// runs no program itself. Commands nested in those units are units of their own, so one still asking keeps the ask.
// Enable with `"authorizerChain": ["bash-syntax"]` in pi-permission-system's config.json.
const LINK = 'bash-syntax';

// statements that run only the commands inside them, which pi-permission-system gates as units of their own
const COMPOUND = new Set([
	'compound_statement', // { … } and (( … ))
	'subshell',
	'if_statement',
	'while_statement', // while and until
	'case_statement',
	'c_style_for_statement',
	'test_command', // [ … ] and [[ … ]]
	'negated_command',
	'function_definition', // binds a name; the body runs only when something calls it
]);
// builtins that run no program and only change the shell's own state
const BUILTINS = new Set(['cd', 'pushd', 'popd', 'true', 'false', ':', 'test', 'shift', 'set']);

// variables a later command reads to find or configure the program it runs, so setting one is as good as running it
const PROGRAM_VARIABLES = new Set([
	'PATH',
	'IFS',
	'BASH_ENV',
	'ENV',
	'SHELLOPTS',
	'BASHOPTS',
	'SHELL',
	'EDITOR',
	'VISUAL',
	'PAGER',
	'HOME',
	'XDG_CONFIG_HOME',
	'SUDO_ASKPASS',
	'SSH_ASKPASS',
	'NODE_OPTIONS',
	'NODE_PATH',
]);
// the same by family: the dynamic loader, git, npm, and the interpreters' startup code and module search paths
const PROGRAM_PREFIX = /^(?:LD_|DYLD_|GIT_|npm_config_|LUA_|PYTHON|PERL5|RUBY)/;
const isProgramVariable = (name: string) => PROGRAM_VARIABLES.has(name) || PROGRAM_PREFIX.test(name);

const wasm = (specifier: string) => fileURLToPath(import.meta.resolve(specifier));

// Parser's constructor needs the runtime, so it throws only before init
function initialized() {
	try {
		new Parser().delete();
		return true;
	} catch {
		return false;
	}
}

// pi-permission-system cuts a command into units with this grammar, so the link reads each unit the same way. pi
// installs its packages in a tree of its own, so there this copy is the link's alone; where both resolve one copy, as
// in the tests, pi-permission-system has initialized it by the time an ask arrives, and a second init would swap the
// module-global runtime its parser runs on
async function loadParser() {
	if (!initialized()) await Parser.init({ locateFile: () => wasm('web-tree-sitter/web-tree-sitter.wasm') });
	const parser = new Parser();
	parser.setLanguage(await Language.load(wasm('tree-sitter-bash/tree-sitter-bash.wasm')));
	return parser;
}

// the variable an assignment writes: `a` in `a=1`, `a+=1` and `a[1]=1`
function assignedName(assignment: Node) {
	const name = assignment.childForFieldName('name');
	return name?.type === 'subscript' ? name.childForFieldName('name')?.text : name?.text;
}

// an assignment to a variable no program reads to decide what it runs
function plainAssignment(assignment: Node | null) {
	const name = assignment && assignedName(assignment);
	return name !== undefined && name !== null && !isProgramVariable(name);
}

// one argument of export, local, declare, typeset or readonly
function plainDeclaration(arg: Node | null) {
	switch (arg?.type) {
		case 'variable_assignment':
			return plainAssignment(arg);
		case 'variable_name':
			return !isProgramVariable(arg.text);
		// -n makes a nameref, whose later plain-looking assignment writes whatever variable it names, PATH included
		case 'word':
			return /^[-+]/.test(arg.text) && !arg.text.includes('n');
		default:
			return false;
	}
}

// whether a statement runs no program of its own
function runsNoProgram(statement: Node): boolean {
	switch (statement.type) {
		case 'variable_assignment':
			return plainAssignment(statement);
		case 'variable_assignments':
			return statement.namedChildren.every(plainAssignment);
		case 'declaration_command':
			return statement.namedChildren.every(plainDeclaration);
		case 'unset_command':
			return true;
		// for and select assign their loop variable, so `for PATH in …` sets PATH like an assignment does
		case 'for_statement': {
			const variable = statement.childForFieldName('variable');
			return variable !== null && !isProgramVariable(variable.text);
		}
		case 'command': {
			const name = statement.childForFieldName('name');
			const prefixes = statement.namedChildren.filter((child) => child?.type === 'variable_assignment');
			return name !== null && BUILTINS.has(name.text) && prefixes.every(plainAssignment);
		}
		default:
			return COMPOUND.has(statement.type);
	}
}

// whether a bash unit, as pi-permission-system reports it, is one statement that runs no program of its own
function unitRunsNoProgram(parser: Parser, unit: string) {
	using trees = new DisposableStack();
	const tree = trees.adopt(parser.parse(unit), (parsed) => parsed?.delete());
	const root = tree?.rootNode;
	const [statement, ...rest] = root?.namedChildren ?? [];
	return root?.hasError === false && statement != null && rest.length === 0 && runsNoProgram(statement);
}

// path and external_directory asks are left to the user; pi-permission-system would not honor an allow there anyway
const authorizeWith =
	(parser: () => Promise<Parser>): Authorizer['authorize'] =>
	async ({ accessIntent }, _query, log) => {
		const units = accessIntent?.surface === 'bash' ? accessIntent.askingUnits : undefined;
		if (!units?.length) return { kind: 'defer' };
		// a link that throws is a gate_error, which blocks the call, so a grammar that will not load asks instead
		const bash = await parser().catch((error: unknown) => {
			log.review('bash_syntax_grammar_unavailable', { error: String(error) });
			return undefined;
		});
		return bash && units.every(({ command }) => unitRunsNoProgram(bash, command))
			? { kind: 'allow' }
			: { kind: 'defer' };
	};

export default function (pi: ExtensionAPI) {
	let registration: AsyncDisposableStack | undefined;
	let warned = false;

	// every extension has had its session_start by now, so the service is published and no tool can have asked yet
	pi.on('before_agent_start', async (_event, ctx) => {
		if (registration) return;
		// staying quiet about a link that never registered is what made one look like it worked
		const warn = (why: string) => {
			if (warned) return;
			warned = true;
			ctx.ui.notify(`bash-syntax: ${why}, so the link is not registered`, 'warning');
		};
		const service = await import('@gotgenes/pi-permission-system')
			.then(({ getPermissionsService }) => getPermissionsService(ctx.sessionManager.getSessionId()))
			.catch(() => undefined);
		if (!service) return warn('pi-permission-system published no service');
		const stack = new AsyncDisposableStack();
		// built on the first ask rather than here: a parse has run by then, so a shared copy is already initialized
		let loading: Promise<Parser> | undefined;
		const parser = () =>
			(loading ??= loadParser().catch((error: unknown) => {
				// a load that fails is retried on the next ask rather than remembered
				loading = undefined;
				throw error;
			}));
		// a load still in flight is awaited, since its parser would otherwise outlive the session; a failed load left nothing
		stack.defer(async () => (await loading?.catch(() => undefined))?.delete());
		stack.defer(service.registerAuthorizer(LINK, authorizeWith(parser)));
		registration = stack;
	});

	pi.on('session_shutdown', async () => {
		await registration?.disposeAsync();
		registration = undefined;
		warned = false;
	});
}
