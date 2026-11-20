import { fileURLToPath } from 'node:url';
import { Language, Parser } from 'web-tree-sitter';
import { memoGlobal } from './memo.ts';

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

// the grammar costs about a megabyte that web-tree-sitter offers no way to free, so one instance outlives a reload
export const getParser = memoGlobal(loadParser, Symbol.for('pi-extensions:tree-sitter-bash:parser'));
