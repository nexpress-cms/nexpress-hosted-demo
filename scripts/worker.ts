import "./_load-env.js";

import { runWorker } from "@nexpress/app/scripts/worker";
import { createBootstrap } from "@nexpress/next";

import nexpressConfig from "../src/nexpress.config.js";
import * as generatedSchema from "../src/db/generated/collections.js";
import { observabilityAdapters } from "../src/lib/observability.js";

const { ensureFor, shutdown } = createBootstrap({
  config: nexpressConfig,
  generatedSchema: generatedSchema as unknown as Record<string, unknown>,
  ...observabilityAdapters,
});

try {
  await runWorker({ ensureFor, shutdown });
} catch (error) {
  try {
    await shutdown();
  } catch (shutdownError) {
    throw new AggregateError(
      [error, shutdownError],
      "Worker startup and bootstrap shutdown both failed.",
      { cause: shutdownError },
    );
  }
  throw error;
}
