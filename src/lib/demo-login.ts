import type { NpAuthUser } from "@nexpress/core/auth";
import { NextResponse, type NextRequest } from "next/server";

interface DemoLoginAuthConfig {
  secret: string;
  tokenExpiration: number;
  refreshTokenExpiration: number;
}

interface DemoLoginSessionOptions {
  accessExpiration: number;
  refreshExpiration: number;
  userAgent?: string | null;
  ip?: string | null;
}

interface DemoLoginSessionTokens {
  sessionId: string;
  access: string;
  refresh: string;
}

interface DemoLoginCookieTokens {
  access: string;
  refresh: string;
  csrf: string;
}

export interface DemoLoginDependencies<SessionDb = unknown> {
  ensureWrite: () => Promise<void>;
  ensureAccounts: () => Promise<{ visitor: NpAuthUser }>;
  getAuthConfig: () => DemoLoginAuthConfig;
  getSessionDb: () => SessionDb;
  createSession: (
    user: NpAuthUser,
    secret: string,
    db: SessionDb,
    options: DemoLoginSessionOptions,
  ) => Promise<DemoLoginSessionTokens>;
  setCookies: (response: NextResponse, tokens: DemoLoginCookieTokens) => void;
}

/**
 * Issue a real DB-backed staff browser session for the shared demo visitor.
 *
 * `signToken()` alone is intentionally insufficient under NexPress' exact
 * session contract: `/admin` also requires the matching `np_sessions` row.
 * Keep this adapter on the same `createStaffSession()` path as setup, password
 * login, and OAuth so package upgrades cannot leave demo-only JWTs orphaned.
 */
export async function createDemoLoginResponse<SessionDb>(
  request: NextRequest,
  dependencies: DemoLoginDependencies<SessionDb>,
): Promise<Response> {
  await dependencies.ensureWrite();
  const { visitor } = await dependencies.ensureAccounts();
  const config = dependencies.getAuthConfig();
  const session = await dependencies.createSession(
    visitor,
    config.secret,
    dependencies.getSessionDb(),
    {
      accessExpiration: config.tokenExpiration,
      refreshExpiration: config.refreshTokenExpiration,
      userAgent: request.headers.get("user-agent"),
      ip: request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null,
    },
  );

  const response = NextResponse.redirect(new URL("/admin", request.url));
  dependencies.setCookies(response, {
    access: session.access,
    refresh: session.refresh,
    csrf: crypto.randomUUID(),
  });
  return response;
}
