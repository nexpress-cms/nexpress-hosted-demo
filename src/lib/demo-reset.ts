import {
  NP_DEFAULT_SITE_ID,
  NpConflictError,
  getDb,
  getThemeById,
  npNavigation,
  setActiveThemeId,
  withCurrentSite,
  withDeferredPostCommit,
  type NpRegisteredTheme,
  type NpTransaction,
} from "@nexpress/core";
import { eq, sql } from "drizzle-orm";

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

  const deletedPages = await tx.execute<{ id: string }>(sql`
    delete from np_c_pages
    where site_id = ${NP_DEFAULT_SITE_ID}
    returning id
  `);
  counts.pages = deletedPages.rows.length;

  const deletedPosts = await tx.execute<{ id: string }>(sql`
    delete from np_c_posts
    where site_id = ${NP_DEFAULT_SITE_ID}
    returning id
  `);
  counts.posts = deletedPosts.rows.length;

  const deletedTags = await tx.execute<{ id: string }>(sql`
    delete from np_c_tags
    where site_id = ${NP_DEFAULT_SITE_ID}
    returning id
  `);
  counts.tags = deletedTags.rows.length;

  const deletedCategories = await tx.execute<{ id: string }>(sql`
    delete from np_c_categories
    where site_id = ${NP_DEFAULT_SITE_ID}
    returning id
  `);
  counts.categories = deletedCategories.rows.length;

  const deletedNav = await tx
    .delete(npNavigation)
    .where(eq(npNavigation.siteId, NP_DEFAULT_SITE_ID))
    .returning({ id: npNavigation.id });
  counts.navItems = deletedNav.length;

  return counts;
}

async function acquireResetLock(tx: NpTransaction): Promise<void> {
  const result = await tx.execute<{ acquired: boolean }>(sql`
    select pg_try_advisory_xact_lock(hashtext('nexpress-hosted-demo-reset')) as acquired
  `);

  if (!result.rows[0]?.acquired) {
    throw new NpConflictError("Demo reset is already running");
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
      db.transaction(async (innerTx) => {
        const tx = innerTx as unknown as NpTransaction;
        await acquireResetLock(tx);
        const wiped = await wipeDemoContent(tx);
        await setActiveThemeId(theme.manifest.id, visitor.id, { tx });
        const seeded = await seedAll(visitor, theme, { tx });
        if (seeded.pages.created === 0 || seeded.posts.created === 0) {
          throw new Error(
            `Demo reset for theme "${theme.manifest.id}" did not recreate baseline pages and posts`,
          );
        }
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
