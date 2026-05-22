import { NextResponse, type NextRequest } from "next/server";

import { npErrorResponse } from "@/lib/api-response";
import { requireDemoMode, requireDemoResetToken } from "@/lib/demo-mode";
import { runDemoReset } from "@/lib/demo-reset";
import { ensureFor } from "@/lib/init-core";

function bearerToken(request: NextRequest): string | null {
  const header = request.headers.get("authorization");
  const match = header?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? request.nextUrl.searchParams.get("token");
}

async function handleDemoReset(request: NextRequest): Promise<Response> {
  try {
    requireDemoMode();
    requireDemoResetToken(bearerToken(request));
    await ensureFor("write");
    const result = await runDemoReset({
      themeId: request.nextUrl.searchParams.get("themeId") ?? undefined,
    });
    return NextResponse.json({ ok: true, result });
  } catch (error) {
    return npErrorResponse(error instanceof Error ? error : new Error("Unknown error"));
  }
}

export async function GET(request: NextRequest): Promise<Response> {
  return handleDemoReset(request);
}

export async function POST(request: NextRequest): Promise<Response> {
  return handleDemoReset(request);
}

export const dynamic = "force-dynamic";
