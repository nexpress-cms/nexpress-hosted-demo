// Next 16 middleware — mostly the framework-shared implementation.
// This hosted-demo override adds one thin guard before delegating to
// NexPress' standard CSRF / rate-limit / security-header / i18n logic.
import { proxy as nexpressProxy } from "@nexpress/app/proxy";
import { NextResponse, type NextRequest } from "next/server";

const DEMO_BLOCKED_MUTATION_PREFIXES = [
  "/api/admin/audit",
  "/api/admin/community/bans",
  "/api/admin/jobs",
  "/api/admin/plugins",
  "/api/admin/sites",
  "/api/admin/users",
  "/api/export",
  "/api/import",
  "/api/settings",
];

function isDemoMutationBlocked(request: NextRequest): boolean {
  if (process.env.NP_DEMO_MODE !== "1") return false;
  if (!["POST", "PUT", "PATCH", "DELETE"].includes(request.method))
    return false;

  const pathname = request.nextUrl.pathname;
  return DEMO_BLOCKED_MUTATION_PREFIXES.some((prefix) =>
    pathname.startsWith(prefix),
  );
}

export function proxy(request: NextRequest): Response | Promise<Response> {
  if (isDemoMutationBlocked(request)) {
    return NextResponse.json(
      {
        error: {
          code: "FORBIDDEN",
          message:
            "This hosted demo resets automatically, so this admin action is disabled.",
        },
      },
      { status: 403 },
    );
  }

  return nexpressProxy(request);
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
