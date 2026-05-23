import { migrate } from "drizzle-orm/node-postgres/migrator";
import { drizzle } from "drizzle-orm/node-postgres";
import { NextResponse, type NextRequest } from "next/server";
import pg from "pg";

import { npErrorResponse } from "@/lib/api-response";
import { requireDemoMode, requireDemoResetToken } from "@/lib/demo-mode";

function bearerToken(request: NextRequest): string | null {
  const header = request.headers.get("authorization");
  const match = header?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

export async function POST(request: NextRequest): Promise<Response> {
  let client: pg.Client | null = null;

  try {
    requireDemoMode();
    requireDemoResetToken(bearerToken(request));

    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) {
      throw new Error("DATABASE_URL is not configured");
    }

    client = new pg.Client({ connectionString: databaseUrl });
    await client.connect();

    await migrate(drizzle(client), { migrationsFolder: "./drizzle" });
    return NextResponse.json({ ok: true });
  } catch (error) {
    return npErrorResponse(error instanceof Error ? error : new Error("Unknown error"));
  } finally {
    if (client) {
      await client.end().catch(() => {});
    }
  }
}

export const dynamic = "force-dynamic";
