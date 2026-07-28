import {
  NP_DEFAULT_SITE_ID,
  NpConflictError,
  getThemeById,
  setActiveThemeId,
  withCurrentSite,
  withDeferredPostCommit,
  type NpRegisteredTheme,
  type NpTransaction,
} from "@nexpress/core";
import { getDb } from "@nexpress/core/db";
import { sql } from "drizzle-orm";

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

const DEFAULT_DEMO_THEME_ID = "default";

interface DemoThemeSeedFixture {
  pages?: readonly unknown[];
  posts?: readonly unknown[];
}

function getQueryRows(result: unknown, operation: string): unknown[] {
  if (
    !result ||
    typeof result !== "object" ||
    !("rows" in result) ||
    !Array.isArray(result.rows)
  ) {
    throw new Error(`Unexpected database result while ${operation}`);
  }

  return result.rows;
}

function getDemoSeedFixture(theme: NpRegisteredTheme): DemoThemeSeedFixture {
  const impl = theme.impl as { seedContent?: DemoThemeSeedFixture } | null;
  return impl?.seedContent ?? {};
}

function assertDemoSeedFixture(theme: NpRegisteredTheme): void {
  const seedContent = getDemoSeedFixture(theme);
  const pageCount = seedContent.pages?.length ?? 0;
  const postCount = seedContent.posts?.length ?? 0;

  if (pageCount === 0 || postCount === 0) {
    throw new Error(
      `Demo theme "${theme.manifest.id}" must include baseline page and post seed content before reset can run`,
    );
  }
}

async function wipeDemoContent(tx: NpTransaction): Promise<DemoResetResult["wiped"]> {
  const counts: DemoResetResult["wiped"] = {
    pages: 0,
    posts: 0,
    tags: 0,
    categories: 0,
    navItems: 0,
  };

  await tx.execute(sql`
    delete from np_comments
    where site_id = ${NP_DEFAULT_SITE_ID}
      and target_type in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_follows
    where site_id = ${NP_DEFAULT_SITE_ID}
      and target_type in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_reactions
    where site_id = ${NP_DEFAULT_SITE_ID}
      and target_type in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_reports
    where site_id = ${NP_DEFAULT_SITE_ID}
      and target_type in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_media_refs
    where collection in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_revisions
    where collection in ('pages', 'posts', 'tags', 'categories')
  `);
  await tx.execute(sql`
    delete from np_slug_history
    where site_id = ${NP_DEFAULT_SITE_ID}
      and collection in ('pages', 'posts', 'tags', 'categories')
  `);

  counts.pages = getQueryRows(
    await tx.execute(sql`
      delete from np_c_pages
      where site_id = ${NP_DEFAULT_SITE_ID}
      returning id
    `),
    "deleting demo pages",
  ).length;

  counts.posts = getQueryRows(
    await tx.execute(sql`
      delete from np_c_posts
      where site_id = ${NP_DEFAULT_SITE_ID}
      returning id
    `),
    "deleting demo posts",
  ).length;

  counts.tags = getQueryRows(
    await tx.execute(sql`
      delete from np_c_tags
      where site_id = ${NP_DEFAULT_SITE_ID}
      returning id
    `),
    "deleting demo tags",
  ).length;

  counts.categories = getQueryRows(
    await tx.execute(sql`
      delete from np_c_categories
      where site_id = ${NP_DEFAULT_SITE_ID}
      returning id
    `),
    "deleting demo categories",
  ).length;

  counts.navItems = getQueryRows(
    await tx.execute(sql`
      delete from np_navigation
      where site_id = ${NP_DEFAULT_SITE_ID}
      returning id
    `),
    "deleting demo navigation",
  ).length;

  return counts;
}

async function acquireResetLock(tx: NpTransaction): Promise<void> {
  const rows = getQueryRows(
    await tx.execute(sql`
      select pg_try_advisory_xact_lock(hashtext('nexpress-hosted-demo-reset')) as acquired
    `),
    "acquiring the demo reset lock",
  );
  const firstRow = rows[0];
  const acquired =
    firstRow && typeof firstRow === "object" && "acquired" in firstRow
      ? firstRow.acquired
      : undefined;

  if (acquired === false) {
    throw new NpConflictError("Demo reset is already running");
  }
  if (acquired !== true) {
    throw new Error("Unexpected database result while acquiring the demo reset lock");
  }
}

function resolveDemoTheme(themeId?: string) {
  const requested = themeId || process.env.NP_DEMO_THEME_ID || DEFAULT_DEMO_THEME_ID;
  const theme = getThemeById(requested);
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
  const theme = resolveDemoTheme(options.themeId);
  assertDemoSeedFixture(theme);
  const { visitor } = await ensureDemoAccounts();

  const result = await withCurrentSite(NP_DEFAULT_SITE_ID, async () => {
    const db = getDb();
    return await withDeferredPostCommit(async () =>
      db.transaction(async (lockTx) => {
        await acquireResetLock(lockTx as unknown as NpTransaction);

        // The shared seed helpers perform their idempotency reads through the
        // framework DB singleton. Commit the wipe first so those reads cannot
        // observe the rows being deleted on another pooled connection. The
        // outer transaction holds the advisory lock across both phases, while
        // the seed writes remain atomic in their own transaction.
        const wiped = await db.transaction(async (wipeTx) =>
          wipeDemoContent(wipeTx as unknown as NpTransaction),
        );
        const seeded = await db.transaction(async (seedTx) => {
          const tx = seedTx as unknown as NpTransaction;
          await setActiveThemeId(theme.manifest.id, visitor.id, { tx });
          const next = await seedAll(visitor, theme, { tx });
          if (next.pages.created === 0 || next.posts.created === 0) {
            throw new Error(
              `Demo reset for theme "${theme.manifest.id}" did not recreate baseline pages and posts`,
            );
          }
          return next;
        });

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
