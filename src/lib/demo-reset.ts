import {
  NP_DEFAULT_SITE_ID,
  deleteDocument,
  findDocuments,
  getDb,
  getRegisteredThemes,
  getThemeById,
  npNavigation,
  setActiveThemeId,
  withCurrentSite,
  withDeferredPostCommit,
  type NpTransaction,
} from "@nexpress/core";
import { eq } from "drizzle-orm";

import { seedAll } from "@/lib/seed-content";

import { ensureDemoAccounts } from "./demo-mode";

export interface DemoResetResult {
  themeId: string;
  wiped: {
    pages: number;
    posts: number;
    tags: number;
    categories: number;
    navItems: number;
  };
  seeded: {
    pages: number;
    posts: number;
    tags: number;
    categories: number;
    navItems: number;
  };
}

type DemoCollection = "pages" | "posts" | "tags" | "categories";

const RESET_COLLECTIONS: DemoCollection[] = ["pages", "posts", "tags", "categories"];

async function wipeCollection(
  collection: DemoCollection,
  actorId: string,
  tx: NpTransaction,
): Promise<number> {
  const result = await findDocuments<{ id: string }>(collection, { limit: 10_000 });
  let deleted = 0;
  for (const doc of result.docs) {
    if (typeof doc.id !== "string") continue;
    await deleteDocument(
      collection,
      doc.id,
      {
        id: actorId,
        email: "demo@nexpress.local",
        name: "Demo Visitor",
        role: "admin",
        tokenVersion: 0,
      },
      { tx },
    );
    deleted += 1;
  }
  return deleted;
}

async function wipeDemoContent(actorId: string, tx: NpTransaction): Promise<DemoResetResult["wiped"]> {
  const counts: DemoResetResult["wiped"] = {
    pages: 0,
    posts: 0,
    tags: 0,
    categories: 0,
    navItems: 0,
  };

  for (const collection of RESET_COLLECTIONS) {
    counts[collection] = await wipeCollection(collection, actorId, tx);
  }

  const db = getDb();
  const deletedNav = await db
    .delete(npNavigation)
    .where(eq(npNavigation.siteId, NP_DEFAULT_SITE_ID))
    .returning({ id: npNavigation.id });
  counts.navItems = deletedNav.length;

  return counts;
}

function resolveDemoTheme(themeId?: string) {
  const requested = themeId ?? process.env.NP_DEMO_THEME_ID;
  const theme = requested ? getThemeById(requested) : getRegisteredThemes()[0];
  if (!theme) {
    throw new Error(
      requested
        ? `Demo theme "${requested}" is not registered`
        : "No registered theme is available for the demo reset",
    );
  }
  return theme;
}

export async function runDemoReset(options: { themeId?: string } = {}): Promise<DemoResetResult> {
  const { visitor } = await ensureDemoAccounts();
  const theme = resolveDemoTheme(options.themeId);

  const result = await withCurrentSite(NP_DEFAULT_SITE_ID, async () => {
    const db = getDb();
    return await withDeferredPostCommit(async () =>
      db.transaction(async (innerTx) => {
        const tx = innerTx as unknown as NpTransaction;
        const wiped = await wipeDemoContent(visitor.id, tx);
        await setActiveThemeId(theme.manifest.id, visitor.id, { tx });
        const seeded = await seedAll(visitor, theme, { tx });
        return { wiped, seeded };
      }),
    );
  });

  return {
    themeId: theme.manifest.id,
    wiped: {
      pages: result.wiped.pages,
      posts: result.wiped.posts,
      tags: result.wiped.tags,
      categories: result.wiped.categories,
      navItems: result.wiped.navItems,
    },
    seeded: {
      pages: result.seeded.pages.created,
      posts: result.seeded.posts.created,
      tags: result.seeded.terms.tagsCreated,
      categories: result.seeded.terms.categoriesCreated,
      navItems: result.seeded.navigation.header + result.seeded.navigation.footer,
    },
  };
}
