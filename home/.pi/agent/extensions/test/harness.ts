import { fauxProvider, type FauxModelDefinition, type FauxResponseStep } from '@earendil-works/pi-ai';
import {
	type AgentSession,
	createAgentSession,
	DefaultResourceLoader,
	type ExtensionFactory,
	ModelRuntime,
	SessionManager,
	SettingsManager,
} from '@earendil-works/pi-coding-agent';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
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
	// pretend these tools came from a package, e.g. { lsp_hover: 'npm:@narumitw/pi-lsp@1.0.0' }
	toolSources?: Record<string, string>;
};

export type Harness = {
	session: AgentSession;
	sessionManager: SessionManager;
	respond: (...steps: FauxResponseStep[]) => void;
	dispose: () => void;
};

// a real in-process pi session: extensions load from their files, the model is scripted
export async function startSession(options: HarnessOptions): Promise<Harness> {
	const root = mkdtempSync(join(tmpdir(), 'pi-test-'));
	const agentDir = join(root, 'agent');
	const cwd = join(root, 'project');
	mkdirSync(agentDir);
	mkdirSync(join(cwd, '.pi'), { recursive: true });
	writeFileSync(join(agentDir, 'settings.json'), JSON.stringify(options.globalSettings ?? {}));
	writeFileSync(join(cwd, '.pi', 'settings.json'), JSON.stringify(options.projectSettings ?? {}));
	// extensions that read settings themselves resolve the global file through this
	const previousAgentDir = env.PI_CODING_AGENT_DIR;
	env.PI_CODING_AGENT_DIR = agentDir;

	const faux = fauxProvider({ provider: options.provider ?? 'faux', models: options.models });
	const settingsManager = SettingsManager.create(cwd, agentDir, { projectTrusted: true });
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
	const modelRuntime = await ModelRuntime.create({
		authPath: join(agentDir, 'auth.json'),
		modelsPath: join(agentDir, 'models.json'),
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
	await session.bindExtensions({});

	return {
		session,
		sessionManager,
		respond: (...steps) => faux.setResponses(steps),
		dispose: () => {
			session.dispose();
			if (previousAgentDir === undefined) delete env.PI_CODING_AGENT_DIR;
			else env.PI_CODING_AGENT_DIR = previousAgentDir;
			rmSync(root, { recursive: true, force: true });
		},
	};
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
