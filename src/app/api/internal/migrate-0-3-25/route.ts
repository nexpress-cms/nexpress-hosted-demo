import { Client } from "pg";

function bearerToken(request: Request): string | null {
  const header = request.headers.get("authorization");
  const match = header?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

function databaseUrl(): string {
  const url =
    process.env.DATABASE_URL_UNPOOLED ??
    process.env.DATABASE_POSTGRES_URL_NON_POOLING ??
    process.env.DATABASE_URL;

  if (!url) {
    throw new Error("DATABASE_URL is not configured");
  }

  return url;
}

async function runMigration(): Promise<void> {
  const client = new Client({ connectionString: databaseUrl() });
  await client.connect();
  try {
    await client.query(`
      alter table if exists "np_c_discussions"
        add column if not exists "published_at" timestamp with time zone;
    `);
    await client.query(`
      alter table if exists "np_c_pages"
        add column if not exists "published_at" timestamp with time zone;
    `);
  } finally {
    await client.end();
  }
}

export async function POST(request: Request): Promise<Response> {
  const token = process.env.NP_TEMP_MIGRATION_TOKEN;
  if (!token || bearerToken(request) !== token) {
    return Response.json({ ok: false }, { status: 403 });
  }

  await runMigration();
  return Response.json({ ok: true });
}

export const dynamic = "force-dynamic";
