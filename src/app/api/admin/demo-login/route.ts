import { signToken } from "@nexpress/core";
import { NextResponse, type NextRequest } from "next/server";

import { npErrorResponse } from "@/lib/api-response";
import { getAuthRuntimeConfig, setAuthCookies } from "@/lib/auth-helpers";
import { ensureDemoAccounts } from "@/lib/demo-mode";
import { ensureFor } from "@/lib/init-core";

export async function GET(request: NextRequest): Promise<Response> {
  try {
    await ensureFor("write");
    const { visitor } = await ensureDemoAccounts();
    const config = getAuthRuntimeConfig();
    const access = await signToken(visitor, config.secret, config.tokenExpiration, "access");
    const refresh = await signToken(
      visitor,
      config.secret,
      config.refreshTokenExpiration,
      "refresh",
    );

    const response = NextResponse.redirect(new URL("/admin", request.url));
    setAuthCookies(response, {
      access,
      refresh,
      csrf: crypto.randomUUID(),
    });
    return response;
  } catch (error) {
    return npErrorResponse(error instanceof Error ? error : new Error("Unknown error"));
  }
}

export const dynamic = "force-dynamic";
