# NexPress Hosted Demo

Public demo app scaffolded with `create-nexpress@0.1.23`.

The demo account is reset on a schedule and is intentionally not a
production admin account.

## Demo mode

Required demo env:

```bash
NP_DEMO_MODE=1
NP_DEMO_RESET_TOKEN=<long random token>
NP_DEMO_THEME_ID=docs
```

Useful commands:

```bash
pnpm demo:reset
```

Routes:

- `/admin/demo-login` issues the shared demo admin session.
- `GET /api/internal/demo-reset` resets seeded demo content when called with
  `Authorization: Bearer $NP_DEMO_RESET_TOKEN`. Tokens in query strings are not
  accepted.

Vercel cron calls `/api/internal/demo-reset` every 30 minutes.
Set Vercel's `CRON_SECRET` to the same value as `NP_DEMO_RESET_TOKEN`.

## Getting started

```bash
pnpm install
# ensure DATABASE_URL points at a running Postgres
pnpm run setup          # browser env wizard (DB / NP_SECRET / storage / migrations)
pnpm dev
```

> `pnpm run setup`, not `pnpm setup` — `pnpm setup`, `pnpm doctor`,
> and `pnpm init` are all pnpm built-ins that shadow our package
> scripts of the same name. Invoke ours with `pnpm run <name>`.

#### Headless / SSH / CI?

`pnpm run setup` auto-detects an SSH session or headless Linux and
falls back to terminal prompts. To force it:

```bash
pnpm run setup -- --cli              # terminal prompts, no browser
pnpm run setup -- --non-interactive  # read everything from env vars
```

Non-interactive mode reads `DATABASE_URL` (required), and optional
`NP_SECRET` (auto-generated if absent), `SITE_URL`,
`NP_STORAGE_ADAPTER`, `NP_S3_*`, `NP_SETUP_RUN_MIGRATIONS` (set to
`false` to write only `.env` without running migrations).

### Stuck? Run the doctor.

```bash
pnpm run doctor
```

A read-only diagnosis of the runtime: Node / pnpm versions, `.env`
presence, required env vars, Postgres reachability, whether
migrations are applied. Green `✓` / yellow `⚠` / red `✗` with a
one-line hint for each non-OK line.

Before deploying, run the production-readiness pass:

```bash
pnpm run deploy:plan -- --target vercel
pnpm run doctor:prod -- --target vercel
```

Tightens the dev defaults: `NP_SECRET` < 32 chars becomes an error,
`http://` SITE_URL warns, missing `NP_ENABLE_JOBS` warns,
`local` storage on a multi-node platform errors. Wire this into
your release pipeline so a bad config fails CI before it ships.

The first time you visit `http://localhost:3000/admin` on an empty
DB, a 2-step wizard collects your admin account, site name, and
optional sample content — no manual `pnpm seed:admin` needed.

## First-site checklist

1. Run `pnpm run setup` and let it apply migrations.
2. Start `pnpm dev` and open `/admin`.
3. Name the site, pick a theme, and seed sample content if useful.
4. Publish the first page or post, then open it on the public site.
5. Run `pnpm run doctor:prod -- --target vercel` before deploying.

### Manual flow (no wizard)

```bash
cp .env.example .env    # then edit DATABASE_URL / NP_SECRET / SITE_URL
pnpm db:generate        # regen collection schema and SQL migrations
pnpm db:migrate         # apply migrations
pnpm seed:admin         # create first admin (interactive)
pnpm dev
```

## Options

- Docker setup: No

- Site: http://localhost:3000
- Admin: http://localhost:3000/admin
- OpenAPI spec: http://localhost:3000/api/openapi.json

## Background jobs (pg-boss)

Optional. Enable when you want async content hooks, scheduled pruning, or
image post-processing.

```bash
# in .env
NP_ENABLE_JOBS=1

# in a second terminal
pnpm worker
```

With jobs off, `enqueueJob` is a no-op — simpler dev, fewer moving parts.

## Deploy

See [docs/deployment.md](https://github.com/nexpress-cms/nexpress/blob/main/docs/deployment.md)
for full Docker / Vercel / Fly.io recipes plus multi-node notes.

### Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new?utm_source=nexpress&utm_campaign=oss)

Push this scaffold to GitHub, click the button, and import your repo in
Vercel. Before promoting the deployment:

```bash
pnpm run deploy:plan -- --target vercel
pnpm run doctor:prod -- --target vercel
```

Required Vercel env vars:

- `DATABASE_URL`
- `NP_SECRET`
- `SITE_URL`
- `NP_STORAGE_ADAPTER=s3`
- `NP_S3_BUCKET`
- `NP_S3_REGION`

Vercel's filesystem is ephemeral, so media uploads require S3/R2/MinIO
or another S3-compatible store. Scheduled publishing also needs
`NP_SCHEDULER_TOKEN` matching Vercel's `CRON_SECRET`.

Quick choice:

- **Vercel** — fastest app hosting path, but requires S3-compatible storage
  for media because the filesystem is ephemeral.
- **Railway / Render** — straightforward Docker deploys with managed
  Postgres; still use S3-compatible storage for durable media.
- **Fly.io / Docker self-host** — best when you want to own the runtime;
  local uploaded files are acceptable only for single-node deployments.

### Vercel

`vercel.json` is included with a cron entry for `/api/internal/publish-scheduled`
(scheduled publishing). On Vercel:

1. Push the repo and import it in the Vercel dashboard.
2. Set env vars: `DATABASE_URL`, `NP_SECRET`, `SITE_URL`,
   `NP_STORAGE_ADAPTER=s3`, `NP_S3_BUCKET`, and `NP_S3_REGION`.
3. Add `CRON_SECRET` in the Vercel env, then set
   `NP_SCHEDULER_TOKEN` to the same value — Vercel signs cron requests
   with `Authorization: Bearer $CRON_SECRET`, and the scheduler route
   verifies against `NP_SCHEDULER_TOKEN`.
4. If you need long-running background jobs, run `pnpm worker` on a
   separate worker host and set `NP_ENABLE_JOBS=1` there. Vercel cron
   handles scheduled HTTP calls, but not a long-lived pg-boss worker.

If you don't use scheduled publishing, the cron entry is a no-op (the
endpoint short-circuits when `NP_SCHEDULER_TOKEN` is unset).
