import "./_load-env.js";

import { createBootstrap } from "@nexpress/next";

import { runDemoReset } from "../src/lib/demo-reset.js";
import nexpressConfig from "../src/nexpress.config.js";
import * as generatedSchema from "../src/db/generated/collections.js";

function parseThemeFlag(argv: string[]): string | undefined {
  const value = argv.slice(2).find((arg) => arg.startsWith("--theme="));
  return value?.slice("--theme=".length).trim() || undefined;
}

async function main(): Promise<void> {
  const { ensureCoreServices, ensurePluginsLoaded } = createBootstrap({
    config: nexpressConfig,
    generatedSchema: generatedSchema as unknown as Record<string, unknown>,
  });

  ensureCoreServices();
  await ensurePluginsLoaded();

  const result = await runDemoReset({ themeId: parseThemeFlag(process.argv) });
  console.log(
    `Demo reset complete. Theme=${result.themeId}; wiped ${result.wiped.pages} pages and ${result.wiped.posts} posts; seeded ${result.seeded.pages} pages, ${result.seeded.posts} posts, ${result.seeded.tags} tags, ${result.seeded.categories} categories, ${result.seeded.navItems} nav items.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
