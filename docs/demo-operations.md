# Demo Operations

This repo runs the public NexPress hosted demo:

https://nexpress-hosted-demo.vercel.app

The demo should prove the same path a new operator uses: start from the
published `create-nexpress` package, connect managed infrastructure, deploy,
and let a visitor safely try the Admin UI.

## Goals

- Keep the public site inspectable without a login.
- Let visitors try Admin with a real session and real writes.
- Reset visitor changes automatically so the demo stays healthy.
- Keep all deployment and reset behavior reproducible from this repo.

## Non-Goals

- Do not expose a production admin account with durable authority.
- Do not let visitors manage users, secrets, outbound integrations, imports, or
  destructive operations.
- Do not promise persistent visitor content.
- Do not treat framework-monorepo `apps/web` as the demo. This repo is a
  scaffolded NexPress site on purpose.

## Runtime Shape

Recommended hosting:

| Surface  | Choice                   | Notes                                                    |
| -------- | ------------------------ | -------------------------------------------------------- |
| Web      | Vercel                   | Pushes to `main` deploy production; PRs create previews. |
| Database | Managed Postgres         | Must allow scheduled reset writes.                       |
| Media    | S3/R2-compatible storage | Vercel filesystem is ephemeral. Use a `demo/` prefix.    |
| Reset    | Vercel Cron              | Calls `/api/internal/demo-reset` with a bearer token.    |

Required environment:

```bash
DATABASE_URL=
NP_SECRET=
SITE_URL=https://nexpress-hosted-demo.vercel.app
NP_STORAGE_ADAPTER=s3
NP_S3_BUCKET=
NP_S3_REGION=
NP_DEMO_MODE=1
NP_DEMO_RESET_TOKEN=
NP_DEMO_THEME_ID=default
```

Recommended:

```bash
NP_S3_ENDPOINT=        # R2 / MinIO / non-AWS S3
NP_SCHEDULER_TOKEN=   # if scheduled publishing is shown
CRON_SECRET=          # same value as NP_DEMO_RESET_TOKEN for Vercel Cron
```

Before promoting a deployment:

```bash
pnpm run deploy:plan -- --target vercel
pnpm run doctor:prod -- --target vercel
pnpm db:check
pnpm demo:reset
```

When updating `@nexpress/*` versions, treat schema changes as part of the
release, not as a follow-up. Run `pnpm db:generate`, commit any new files under
`drizzle/`, apply `pnpm db:migrate` to the production database, and only then
promote or merge the deployment. The CI `db:check` step intentionally fails if
the generated schema wants a migration that is not committed.

`vercel.json` enforces that ordering in Vercel's secret-bearing build
environment with `pnpm db:migrate && pnpm build`. Keep the command in place so
clean production deploys cannot promote application code ahead of its schema.

## NexPress Version Update Checklist

Use this checklist immediately after the framework repo publishes a new npm
version. The goal is to keep the hosted demo proving the current public install
path, not yesterday's packages.

1. Create a branch from `main`.
2. Update every `@nexpress/*` dependency and `@nexpress/cli` to the same
   published version.
3. Update the README `create-nexpress@...` reference when `create-nexpress`
   changed in the same release.
4. Run `pnpm install` and commit the lockfile.
5. Run:

   ```bash
   pnpm typecheck
   pnpm build
   pnpm db:check
   ```

6. If `pnpm db:check` reports drift, run `pnpm db:generate`, review the
   generated migration, commit it, and apply `pnpm db:migrate` to the managed
   demo database before production promotion.
7. Open one PR, wait for GitHub CI and Vercel preview, then merge.
8. Wait for the production Vercel deployment attached to `main`.
9. Verify the live demo:

   ```bash
   curl -I -L https://nexpress-hosted-demo.vercel.app/api/health/ready
   curl -I -L https://nexpress-hosted-demo.vercel.app
   ```

10. If the release touched demo reset, auth, themes, or seeded content, run
    `pnpm demo:reset` against the configured production environment or trigger
    the protected reset endpoint once, then spot-check `/` and `/admin/demo-login`.

## Public Content

The public site should show a real NexPress surface, not a blank scaffold:

- Home page using the active theme.
- Blog index and several posts with rich text.
- A page-builder page with repeated blocks where available.
- Navigation that makes the demo discoverable.
- Admin entrypoint at `/admin/demo-login`.

The baseline content should be deterministic. Re-running reset should recreate
the same pages, posts, navigation, active theme, plugin config, and sample
media references.

Content rules:

- Keep slugs stable. Reset should update or recreate the same slugs, not mint
  timestamped rows.
- Mark demo-owned rows with seed metadata where the framework supports it.
- Keep baseline media under `demo/baseline/`.
- Keep visitor uploads under `demo/uploads/`.
- Avoid real outbound webhooks in baseline config.
- Keep copy short enough that visitors understand Admin in one minute.

## Admin Demo Model

The first public demo uses a shared reset-style Admin account. It is less
isolated than per-session sandboxes, but simple and transparent.

Flow:

1. Visitor opens `/admin/demo-login`.
2. The route only works when `NP_DEMO_MODE=1`.
3. The route creates or reuses the demo staff user and issues a normal admin
   session cookie.
4. The visitor lands in `/admin` with a visible demo banner.
5. Scheduled reset restores the site to the baseline.

The demo account may:

- create and edit posts/pages
- upload media under the demo storage prefix
- preview and publish content
- edit navigation and non-secret theme settings
- inspect plugin admin surfaces that do not perform outbound work

The demo account must not:

- manage users or super-admin state
- edit OAuth, SMTP, webhook, storage, or scheduler secrets
- run imports, exports, or destructive cleanup jobs
- change site membership or cross-site access
- delete the active site or manually reset baseline rows

## Server-Side Guard

Prefer structural guards over UI-only hiding.

- Gate demo behavior behind `NP_DEMO_MODE=1`.
- Identify the demo user with a stable marker such as
  `demo@nexpress.local`.
- Enforce restrictions in API routes and server actions.
- Keep normal capabilities intact for real admins.
- Return `403` with a clear message when a demo user hits a disabled surface.

## Reset Contract

Reset cadence:

- daily on Vercel Hobby
- every 30 minutes for the public production demo if/when it moves to Vercel Pro
- manually triggerable by an operator
- idempotent

Reset scope:

- demo-owned content collections
- navigation
- active theme and theme settings
- public-safe plugin config rows
- demo user session version
- media rows and objects under the demo prefix
- safe-to-prune jobs created by demo activity

Reset must not touch:

- operator admin accounts
- production secrets
- migration tables
- database connection state
- non-demo storage prefixes

Reset entrypoints:

```bash
pnpm demo:reset
```

```http
GET /api/internal/demo-reset
Authorization: Bearer $NP_DEMO_RESET_TOKEN
```

Tokens in query strings are not accepted.

Reset algorithm:

1. Verify `NP_DEMO_MODE=1`.
2. Acquire a lock so overlapping resets do not corrupt state.
3. Disable active demo sessions by bumping the demo user's token version.
4. Delete visitor-created demo content.
5. Delete demo-owned navigation rows.
6. Delete demo-owned plugin config and plugin storage rows.
7. Delete demo media rows and storage objects under `demo/uploads/`.
8. Recreate or verify baseline media under `demo/baseline/`.
9. Activate the baseline theme and settings.
10. Run the theme seed where it fits.
11. Recreate header/footer navigation.
12. Recreate the demo user with only allowed permissions.
13. Record reset completion.

Failure behavior:

- If the lock is held, return `409` for manual/API calls.
- If baseline seed fails, return non-2xx so Vercel Cron records the failure.
- Never partially delete operator accounts or non-demo storage prefixes.
- Log reset start/end/error without exposing secrets.

## Security Checklist

- Demo login disabled unless `NP_DEMO_MODE=1`.
- Demo login issues only the demo principal.
- Demo restrictions enforced server-side.
- Demo admin banner visible on protected Admin pages.
- Secret-bearing forms disabled or redacted for demo users.
- Outbound plugin examples disabled or pointed at local/no-op sinks.
- Reset token stored only in host secrets.
- Media cleanup limited to the configured demo prefix.
- Admin audit log records demo login and reset events.

## Success Criteria

- Public pages render real NexPress content and media.
- A visitor can log into Admin, edit content, preview, and publish.
- Restricted demo actions fail safely.
- Reset can be run manually and by cron.
- The deployment can be rebuilt from documented env and commands.
