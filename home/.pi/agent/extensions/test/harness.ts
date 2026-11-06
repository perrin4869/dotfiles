import {
	createFauxCore,
	fauxProvider,
	type FauxModelDefinition,
	type FauxProviderHandle,
	type FauxResponseStep,
	InMemoryCredentialStore,
	InMemoryModelsStore,
} from '@earendil-works/pi-ai';
import { createProvider, registerApiProvider, unregisterApiProviders } from '@earendil-works/pi-ai/compat';
import {
	type AgentSession,
	createAgentSession,
	DefaultResourceLoader,
	type ExtensionError,
	type ExtensionFactory,
	type ExtensionUIContext,
	ModelRuntime,
	SessionManager,
	SettingsManager,
} from '@earendil-works/pi-coding-agent';
import { findPackageJSON } from 'node:module';
import { dirname, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { env } from 'node:process';
import { Type } from 'typebox';
import { Value } from 'typebox/value';

export const extension = (name: string) => join(import.meta.dirname, '..', `${name}.ts`);

const PiManifest = Type.Object({ pi: Type.Object({ extensions: Type.Array(Type.String(), { minItems: 1 }) }) });

// where an installed package lives, e.g. <repo>/node_modules/pi-memory
export function packageDir(name: string) {
	const manifest = findPackageJSON(name, import.meta.url);
	if (manifest === undefined) throw new Error(`${name} is not installed`);
	return dirname(manifest);
}

const fileUrl = (dir: string, path: string) => pathToFileURL(join(dir, path)).href;

// an installed package's pi extension entry point, as pi resolves it from the package's `pi.extensions` manifest
export async function packageExtension(name: string) {
	const dir = packageDir(name);
	const { default: manifest }: { default: unknown } = await import(fileUrl(dir, 'package.json'), {
		with: { type: 'json' },
	});
	if (!Value.Check(PiManifest, manifest)) throw new Error(`${name} declares no pi extension`);
	return join(dir, manifest.pi.extensions[0]);
}

// a module inside an installed package, past its `exports` map, for contract tests against its internals
export const packageModule = <T>(name: string, path: string): Promise<T> => import(fileUrl(packageDir(name), path));

// what the harness needs from a scripted model; FauxProviderHandle and scriptedFaux both fit
export type HarnessFaux = {
	provider: FauxProviderHandle['provider'];
	getModel(id?: string): ReturnType<FauxProviderHandle['getModel']>;
	setResponses(steps: FauxResponseStep[]): void;
};

export type HarnessOptions = {
	extensions: string[];
	factories?: ExtensionFactory[];
	// the scripted model; defaults to pi-ai's fauxProvider built from provider/models; see scriptedFaux
	faux?: HarnessFaux;
	provider?: string;
	models?: FauxModelDefinition[];
	model?: string;
	globalSettings?: object;
	projectSettings?: object;
	// pi leaves project settings out until the project is trusted
	projectTrusted?: boolean;
};

export type NotifyListener = ExtensionUIContext['notify'];

export type StartOptions = {
	// receives every ctx.ui.notify()
	onNotify?: NotifyListener;
	// receives errors thrown by extension handlers; by default they fail whatever fired the event
	onError?: (error: ExtensionError) => void;
};

// dispose with `using`, which disposes the session
export type Harness = Disposable & {
	session: AgentSession;
	respond: (...steps: FauxResponseStep[]) => void;
};

// Everything lives in memory, so these paths are never created: pi only needs them to look for resources there.
const agentDir = '/nonexistent/pi-test/agent';
const cwd = '/nonexistent/pi-test/project';

type SettingsStorage = Parameters<typeof SettingsManager.fromStorage>[0];

// pi's settings files, held in memory per scope. pi reads and writes through withLock: the callback receives the
// current contents and returns new ones to store, or undefined to leave them as they are.
function settingsStorage(files: Record<'global' | 'project', object>): SettingsStorage {
	const contents: Record<string, string | undefined> = {
		global: JSON.stringify(files.global),
		project: JSON.stringify(files.project),
	};
	return {
		withLock: (scope, access) => {
			contents[scope] = access(contents[scope]) ?? contents[scope];
		},
	};
}

// A scripted model that also serves pi-ai's global completion functions (complete, completeSimple), which
// extensions such as pi-memory call directly; pi-ai resolves those through a registry only this constructor fills.
export function scriptedFaux(
	options: { provider?: string; models?: FauxModelDefinition[] } = {},
): HarnessFaux & Disposable {
	const core = createFauxCore({ provider: options.provider ?? 'faux', models: options.models });
	const provider = createProvider({
		id: core.provider,
		auth: { apiKey: { name: 'Faux', resolve: () => Promise.resolve({ auth: { apiKey: 'test' } }) } },
		models: core.models,
		api: { stream: core.stream, streamSimple: core.streamSimple },
	});
	const sourceId = `pi-extensions-${core.provider}`;
	registerApiProvider({ api: core.api, stream: core.stream, streamSimple: core.streamSimple }, sourceId);
	return {
		provider,
		getModel: (id?: string) => (id === undefined ? core.getModel() : core.getModel(id)),
		setResponses: (steps: FauxResponseStep[]) => core.setResponses(steps),
		[Symbol.dispose]: () => unregisterApiProviders(sourceId),
	};
}

// a real in-process pi session, not yet started: extensions load from their files, the model is scripted
export async function createHarness(options: HarnessOptions): Promise<Harness> {
	const faux: HarnessFaux =
		options.faux ?? fauxProvider({ provider: options.provider ?? 'faux', models: options.models });
	const settingsManager = SettingsManager.fromStorage(
		settingsStorage({ global: options.globalSettings ?? {}, project: options.projectSettings ?? {} }),
		{ projectTrusted: options.projectTrusted ?? true },
	);
	const resourceLoader = new DefaultResourceLoader({
		cwd,
		agentDir,
		settingsManager,
		additionalExtensionPaths: options.extensions,
		extensionFactories: [(pi) => pi.registerProvider(faux.provider), ...(options.factories ?? [])],
		noSkills: true,
		noPromptTemplates: true,
		noThemes: true,
		noContextFiles: true,
	});
	await resourceLoader.reload();
	const loadErrors = resourceLoader.getExtensions().errors;
	if (loadErrors.length > 0) throw new Error(`extensions failed to load: ${JSON.stringify(loadErrors)}`);
	// in-memory stores, so nothing is written to agentDir; pi only switches to models whose provider has credentials
	const modelRuntime = await ModelRuntime.create({
		credentials: new InMemoryCredentialStore(),
		modelsStore: new InMemoryModelsStore(),
		modelsPath: null,
	});
	await modelRuntime.setRuntimeApiKey(faux.provider.id, 'test');

	const model = options.model === undefined ? faux.getModel() : faux.getModel(options.model);
	const { session } = await createAgentSession({
		cwd,
		agentDir,
		modelRuntime,
		resourceLoader,
		settingsManager,
		sessionManager: SessionManager.inMemory(cwd),
		model,
	});

	return {
		session,
		respond: (...steps) => faux.setResponses(steps),
		// the faux belongs to whoever built it, so a scriptedFaux is disposed where it was created
		[Symbol.dispose]: () => session.dispose(),
	};
}

// binds the extensions, which fires session_start; startSession does it right away, createHarness leaves it to the test
export function startHarness({ session }: Harness, { onNotify, onError = rethrow }: StartOptions = {}) {
	// pi's own do-nothing UI, which it uses until one is bound
	const ui = session.extensionRunner.getUIContext();
	return session.bindExtensions({ uiContext: onNotify ? { ...ui, notify: onNotify } : ui, onError });
}

// pi reports errors thrown by extension handlers to onError and carries on; rethrowing rejects whatever fired the
// event, so the test fails where the handler did
function rethrow(error: ExtensionError): never {
	throw new Error(`${error.extensionPath} failed on ${error.event}: ${error.error}`, { cause: error });
}

// a started session, for the tests that need nothing between creating and starting it
export async function startSession(options: HarnessOptions & StartOptions) {
	// disposes the session if starting it fails
	using cleanup = new DisposableStack();
	const harness = cleanup.use(await createHarness(options));
	await startHarness(harness, options);
	cleanup.move();
	return harness;
}

// Pretend the extension that registered this tool came from a package, e.g. 'npm:@narumitw/pi-lsp@1.0.0'. pi shares
// the extension's source with all its tools and the session, so this relabels the whole extension, in place; call it
// before startHarness, since extensions may read tool sources on session_start.
export function setToolSource(session: AgentSession, name: string, source: string) {
	const tool = session.extensionRunner.getAllRegisteredTools().find(({ definition }) => definition.name === name);
	if (tool === undefined) throw new Error(`no extension registered ${name}`);
	tool.sourceInfo.source = source;
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

// stand-ins for other packages' tools, accepting any input
export function stubTools(...names: string[]): ExtensionFactory {
	return (pi) => {
		for (const name of names) {
			pi.registerTool({
				name,
				label: name,
				description: name,
				parameters: Type.Object({}, { additionalProperties: true }),
				execute: () => Promise.resolve({ content: [{ type: 'text', text: 'ran' }], details: {} }),
			});
		}
	};
}

export function toolResults(session: AgentSession) {
	return session.messages.flatMap((m) =>
		m.role === 'toolResult'
			? [{ isError: m.isError, text: m.content.map((c) => (c.type === 'text' ? c.text : '')).join('') }]
			: [],
	);
}
