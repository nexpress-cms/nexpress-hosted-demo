import { createStaffSession } from "@nexpress/core/auth";
import { getDb } from "@nexpress/core/db";
import type { NextRequest } from "next/server";

import { npErrorResponse } from "@/lib/api-response";
import { getAuthRuntimeConfig, setAuthCookies } from "@/lib/auth-helpers";
import { createDemoLoginResponse } from "@/lib/demo-login";
import { ensureDemoAccounts } from "@/lib/demo-mode";
import { ensureFor } from "@/lib/init-core";

export async function GET(request: NextRequest): Promise<Response> {
  try {
    return await createDemoLoginResponse(request, {
      ensureWrite: () => ensureFor("write"),
      ensureAccounts: ensureDemoAccounts,
      getAuthConfig: getAuthRuntimeConfig,
      getSessionDb: getDb,
      createSession: createStaffSession,
      setCookies: setAuthCookies,
    });
  } catch (error) {
    return npErrorResponse(error instanceof Error ? error : new Error("Unknown error"));
  }
}

export const dynamic = "force-dynamic";
