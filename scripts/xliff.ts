import "./_load-env.js";

import type { NpAuthUser } from "@nexpress/core";
import { runCli } from "@nexpress/xliff";
import { createBootstrap } from "@nexpress/next";

import nexpressConfig from "../src/nexpress.config.js";
import * as generatedSchema from "../src/db/generated/collections.js";

import { observabilityAdapters } from "../src/lib/observability.js";

async function shutdownAndExit(code: number): Promise<never> {
  let exitCode = code;
  try {
    await shutdown();
  } catch (error) {
    process.stderr.write(
      `xliff: bootstrap shutdown failed: ${String(error)}\n`,
    );
    exitCode = 1;
  }
  process.exit(exitCode);
}

const { ensureFor, shutdown } = createBootstrap({
  config: nexpressConfig,
  generatedSchema: generatedSchema as unknown as Record<string, unknown>,
  ...observabilityAdapters,
});

async function main(): Promise<void> {
  await ensureFor("plugins");

  const user: NpAuthUser = {
    id: "00000000-0000-0000-0000-000000000000",
    email: "xliff-import@local",
    name: "XLIFF importer",
    role: "admin",
    tokenVersion: 0,
  };
  const io = {
    out(message: string): void {
      process.stdout.write(message);
    },
    err(message: string): void {
      process.stderr.write(message);
    },
  };
  const result = await runCli(io, process.argv.slice(2), { user });
  await shutdownAndExit(result.exitCode);
}

void main().catch(async (error) => {
  process.stderr.write(`xliff: ${(error as Error).stack ?? String(error)}\n`);
  await shutdownAndExit(1);
});
