import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { delimiter, join } from "node:path";

const LSP_PACKAGE = /^npm:@narumitw\/pi-lsp(@|$)/;
const MASON_BIN = join(process.env.XDG_DATA_HOME || join(homedir(), ".local", "share"), "nvim", "mason", "bin");

// pi-lsp resolves servers from PATH when a tool runs, so Mason's servers are only needed from then on
export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		const tool = pi.getAllTools().find((t) => t.name === event.toolName);
		if (!tool || !LSP_PACKAGE.test(tool.sourceInfo.source)) return;
		const entries = (process.env.PATH ?? "").split(delimiter).filter(Boolean);
		if (!entries.includes(MASON_BIN)) process.env.PATH = [...entries, MASON_BIN].join(delimiter);
	});
}
