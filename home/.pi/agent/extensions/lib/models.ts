import type { Api, Model } from '@earendil-works/pi-ai';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';

// a model as `provider/id`; the id may contain further slashes
export const ModelRef = (defaultRef: string) =>
	Type.String({ pattern: '^[^/]+/.+$', default: defaultRef, description: 'a model as provider/id' });

export const modelRef = (model: Model<Api>) => `${model.provider}/${model.id}`;

export function findModel(ctx: ExtensionContext, ref: string) {
	const slash = ref.indexOf('/');
	return ctx.modelRegistry.find(ref.slice(0, slash), ref.slice(slash + 1));
}
