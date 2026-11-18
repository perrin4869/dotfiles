import { fileURLToPath } from 'node:url';
import { Language, Parser } from 'web-tree-sitter';

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

// pi-permission-system cuts a command into units with this grammar, so a link reads each unit the same way. pi
// installs its packages in a tree of its own, so there that copy is the extension's alone; where both resolve one
// copy, as in the tests, pi-permission-system has initialized it by the time anything parses, and a second init
// would swap the module-global runtime its parser runs on
async function loadParser() {
	if (!initialized()) await Parser.init({ locateFile: () => wasm('web-tree-sitter/web-tree-sitter.wasm') });
	const parser = new Parser();
	parser.setLanguage(await Language.load(wasm('tree-sitter-bash/tree-sitter-bash.wasm')));
	return parser;
}

// The parser lives in a process-wide slot: pi re-evaluates extension modules on every reload and session
// replacement, and each load instantiates the grammar wasm, about a megabyte that web-tree-sitter offers no way to
// free. The cached parser keeps its own copy of the runtime alive, so it still parses after a module is evaluated
// again, and the extensions that read bash share this one.
const PARSER = Symbol.for('pi-extensions:tree-sitter-bash:parser');

// the promise rather than the parser: concurrent callers share one load, and a load that fails is retried, not
// remembered
export function getParser(): Promise<Parser> {
	const pending: Promise<Parser> | undefined = Reflect.get(globalThis, PARSER);
	if (pending !== undefined) return pending;
	const load = loadParser().catch((error: unknown) => {
		Reflect.deleteProperty(globalThis, PARSER);
		throw error;
	});
	Reflect.set(globalThis, PARSER, load);
	return load;
}
