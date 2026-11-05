import type { Api, Model } from '@earendil-works/pi-ai';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';

// a model as `provider/id`; the id may contain further slashes
export const ModelRef = (defaultRef: string) =>
	Type.String({ pattern: '^[^/]+/.+$', default: defaultRef, description: 'a model as provider/id' });

export const modelRef = (model: Model<Api>) => `${model.provider}/${model.id}`;

// splits at the first slash only, unlike split('/')
export function parseModelRef(ref: string): [provider: string, id: string] {
	const slash = ref.indexOf('/');
	return [ref.slice(0, slash), ref.slice(slash + 1)];
}

export const findModel = (ctx: ExtensionContext, ref: string) => ctx.modelRegistry.find(...parseModelRef(ref));
