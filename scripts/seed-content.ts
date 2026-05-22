import "./_load-env.js";

import { eq } from "drizzle-orm";

import {
  createDbConnection,
  getActiveTheme,
  getSiteById,
  npUsers,
  withCurrentSite,
} from "@nexpress/core";
import type { NpAuthUser } from "@nexpress/core";
import { createBootstrap } from "@nexpress/next";
import { seedAll } from "@nexpress/app/lib/seed-content";

import nexpressConfig from "../src/nexpress.config.js";
import * as generatedSchema from "../src/db/generated/collections.js";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("DATABASE_URL is not set. Copy .env.example to .env first.");
  process.exit(1);
}

const { ensureCoreServices, ensurePluginsLoaded } = createBootstrap({
  config: nexpressConfig,
  generatedSchema: generatedSchema as unknown as Record<string, unknown>,
});

async function findFirstAdmin(): Promise<NpAuthUser | null> {
  const db = createDbConnection({ connectionString: databaseUrl as string });
  const rows = await db
    .select({
      id: npUsers.id,
      email: npUsers.email,
      name: npUsers.name,
      role: npUsers.role,
      tokenVersion: npUsers.tokenVersion,
    })
    .from(npUsers)
    .where(eq(npUsers.role, "admin"))
    .limit(1);
  const row = rows[0];
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    role: row.role as NpAuthUser["role"],
    tokenVersion: row.tokenVersion,
  };
}

function parseSiteFlag(argv: string[]): string {
  const arg = argv.slice(2).find((a) => a.startsWith("--site="));
  if (!arg) return "default";
  return arg.slice("--site=".length).trim() || "default";
}

async function main(): Promise<void> {
  ensureCoreServices();
  await ensurePluginsLoaded();

  const siteId = parseSiteFlag(process.argv);
  if (siteId !== "default") {
    const target = await getSiteById(siteId);
    if (!target) {
      console.error(`Site "${siteId}" not found. Create it via /admin/sites or the API first.`);
      process.exit(1);
    }
  }

  const actor = await findFirstAdmin();
  if (!actor) {
    console.error("No admin user found. Run `pnpm seed:admin` first.");
    process.exit(1);
  }
  const theme = await getActiveTheme();
  if (!theme) {
    console.error("No active theme — pick one in the admin or setup wizard before seeding content.");
    process.exit(1);
  }

  const { terms, pages, posts, navigation } = await withCurrentSite(
    siteId,
    async () => seedAll(actor, theme),
  );

  console.log(
    `Done. Created ${pages.created} pages, ${posts.created} posts, ${terms.tagsCreated} tags, ${terms.categoriesCreated} categories, ${navigation.header + navigation.footer} nav items.`,
  );
  process.exit(0);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
