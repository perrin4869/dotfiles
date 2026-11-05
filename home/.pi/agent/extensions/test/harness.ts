import {
	fauxProvider,
	type FauxModelDefinition,
	type FauxResponseStep,
	InMemoryCredentialStore,
	InMemoryModelsStore,
} from '@earendil-works/pi-ai';
import {
	type AgentSession,
	createAgentSession,
	DefaultResourceLoader,
	type ExtensionFactory,
	type ExtensionUIContext,
	ModelRuntime,
	SessionManager,
	SettingsManager,
} from '@earendil-works/pi-coding-agent';
import { join } from 'node:path';
import { env } from 'node:process';
import { Type } from 'typebox';

export const extension = (name: string) => join(import.meta.dirname, '..', `${name}.ts`);

export type HarnessOptions = {
	extensions: string[];
	factories?: ExtensionFactory[];
	provider?: string;
	models?: FauxModelDefinition[];
	model?: string;
	globalSettings?: object;
	projectSettings?: object;
	// pi leaves project settings out until the project is trusted
	projectTrusted?: boolean;
	// pretend these tools came from a package, e.g. { lsp_hover: 'npm:@narumitw/pi-lsp@1.0.0' }
	toolSources?: Record<string, string>;
};

// dispose with `using`: it disposes the session and removes the temporary directories
export type Harness = Disposable & {
	session: AgentSession;
	sessionManager: SessionManager;
	notifications: string[];
	respond: (...steps: FauxResponseStep[]) => void;
};

// Everything lives in memory, so these paths are never created: pi only needs them to look for resources there.
const agentDir = '/nonexistent/pi-test/agent';
const cwd = '/nonexistent/pi-test/project';

type SettingsStorage = Parameters<typeof SettingsManager.fromStorage>[0];

// pi's settings files, held in memory per scope
function settingsStorage(files: Record<'global' | 'project', object>): SettingsStorage {
	const contents: Record<string, string | undefined> = {
		global: JSON.stringify(files.global),
		project: JSON.stringify(files.project),
	};
	return {
		withLock: (scope, update) => {
			contents[scope] = update(contents[scope]) ?? contents[scope];
		},
	};
}

// a real in-process pi session: extensions load from their files, the model is scripted
export async function startSession(options: HarnessOptions): Promise<Harness> {
	// releases what was set up so far if setup fails; on success the harness takes it over
	using cleanup = new DisposableStack();

	const faux = fauxProvider({ provider: options.provider ?? 'faux', models: options.models });
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
	const loaded = resourceLoader.getExtensions();
	if (loaded.errors.length > 0) throw new Error(`extensions failed to load: ${JSON.stringify(loaded.errors)}`);
	for (const ext of loaded.extensions) {
		for (const [name, tool] of ext.tools) {
			const source = options.toolSources?.[name];
			if (source !== undefined) tool.sourceInfo = { ...tool.sourceInfo, source };
		}
	}
	// pi only switches to models whose provider has credentials
	// in memory: file-backed stores write after the session is disposed, recreating the temporary directory
	const modelRuntime = await ModelRuntime.create({
		credentials: new InMemoryCredentialStore(),
		modelsStore: new InMemoryModelsStore(),
		modelsPath: null,
	});
	await modelRuntime.setRuntimeApiKey(faux.provider.id, 'test');

	const sessionManager = SessionManager.inMemory(cwd);
	const model = options.model === undefined ? faux.getModel() : faux.getModel(options.model);
	const { session } = await createAgentSession({
		cwd,
		agentDir,
		modelRuntime,
		resourceLoader,
		settingsManager,
		sessionManager,
		model,
	});
	const notifications: string[] = [];
	cleanup.defer(() => session.dispose());
	await session.bindExtensions({ uiContext: recordingUI(notifications) });
	const resources = cleanup.move();

	return {
		session,
		sessionManager,
		notifications,
		respond: (...steps) => faux.setResponses(steps),
		[Symbol.dispose]: () => resources.dispose(),
	};
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

// records notify(); every other UI call answers nothing, like a UI the user ignores
function recordingUI(notifications: string[]): ExtensionUIContext {
	const ui: Partial<ExtensionUIContext> = { notify: (message) => void notifications.push(message) };
	// oxlint-disable-next-line typescript/no-unsafe-type-assertion -- the proxy supplies the missing methods
	return new Proxy(ui, { get: (target, key) => Reflect.get(target, key) ?? (() => undefined) }) as ExtensionUIContext;
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
