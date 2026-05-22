import { randomUUID } from "node:crypto";

import { eq, sql } from "drizzle-orm";

import {
  NP_DEFAULT_SITE_ID,
  NpForbiddenError,
  ensureDefaultSite,
  getDb,
  grantSiteMembership,
  hashPassword,
  npUsers,
  type NpAuthUser,
  type NpUserRole,
} from "@nexpress/core";

export const DEMO_OPERATOR_EMAIL =
  process.env.NP_DEMO_OPERATOR_EMAIL ?? "operator@nexpress.local";
export const DEMO_USER_EMAIL = process.env.NP_DEMO_USER_EMAIL ?? "demo@nexpress.local";

export function isDemoMode(): boolean {
  return process.env.NP_DEMO_MODE === "1";
}

export function requireDemoMode(): void {
  if (!isDemoMode()) {
    throw new NpForbiddenError("demo", "execute");
  }
}

export function requireDemoResetToken(token: string | null): void {
  const expected = process.env.NP_DEMO_RESET_TOKEN;
  if (!expected || token !== expected) {
    throw new NpForbiddenError("demo-reset", "execute");
  }
}

async function upsertDemoAccount(input: {
  email: string;
  name: string;
  role: NpUserRole;
  isSuperAdmin: boolean;
}): Promise<NpAuthUser> {
  const db = getDb();
  const password = await hashPassword(randomUUID());
  const now = new Date();
  const [user] = await db
    .insert(npUsers)
    .values({
      email: input.email,
      password,
      name: input.name,
      role: input.role,
      isSuperAdmin: input.isSuperAdmin,
      updatedAt: now,
    })
    .onConflictDoUpdate({
      target: npUsers.email,
      set: {
        password,
        name: input.name,
        role: input.role,
        isSuperAdmin: input.isSuperAdmin,
        loginAttempts: 0,
        lockUntil: null,
        tokenVersion: sql`${npUsers.tokenVersion} + 1`,
        updatedAt: now,
      },
    })
    .returning({
      id: npUsers.id,
      email: npUsers.email,
      name: npUsers.name,
      role: npUsers.role,
      tokenVersion: npUsers.tokenVersion,
    });

  if (!user) {
    throw new Error(`Failed to prepare demo account ${input.email}`);
  }

  await grantSiteMembership(NP_DEFAULT_SITE_ID, user.id, input.role);

  return {
    id: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    tokenVersion: user.tokenVersion,
  };
}

export async function ensureDemoAccounts(): Promise<{
  operator: NpAuthUser;
  visitor: NpAuthUser;
}> {
  requireDemoMode();
  await ensureDefaultSite();

  const operator = await upsertDemoAccount({
    email: DEMO_OPERATOR_EMAIL,
    name: "Demo Operator",
    role: "admin",
    isSuperAdmin: true,
  });

  const visitor = await upsertDemoAccount({
    email: DEMO_USER_EMAIL,
    name: "Demo Visitor",
    role: "admin",
    isSuperAdmin: false,
  });

  return { operator, visitor };
}

export async function findDemoVisitor(): Promise<NpAuthUser | null> {
  const db = getDb();
  const [user] = await db
    .select({
      id: npUsers.id,
      email: npUsers.email,
      name: npUsers.name,
      role: npUsers.role,
      tokenVersion: npUsers.tokenVersion,
    })
    .from(npUsers)
    .where(eq(npUsers.email, DEMO_USER_EMAIL))
    .limit(1);

  return user
    ? {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        tokenVersion: user.tokenVersion,
      }
    : null;
}
