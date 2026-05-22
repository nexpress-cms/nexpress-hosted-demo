import "./_load-env.js";

import { runWorker } from "@nexpress/app/scripts/worker";
import { createBootstrap } from "@nexpress/next";

import nexpressConfig from "../src/nexpress.config.js";
import * as generatedSchema from "../src/db/generated/collections.js";

const { ensureCoreServices, ensurePluginsLoaded } = createBootstrap({
  config: nexpressConfig,
  generatedSchema: generatedSchema as unknown as Record<string, unknown>,
});

async function ensureFor(intent: "read" | "plugins" | "write"): Promise<void> {
  ensureCoreServices();
  if (intent === "read") return;
  await ensurePluginsLoaded();
  // "write" intent would also wire email + jobs producer, but
  // the worker only invokes ensureFor("plugins") on first call.
}

await runWorker({ ensureFor });
