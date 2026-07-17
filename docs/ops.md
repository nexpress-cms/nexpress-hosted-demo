# Operations

This file is the detailed command reference. Keep the root README focused on
the first-run path; come here when you need agent handoffs, deploy checks,
jobs, storage, plugins, releases, or incident runbooks.

## Deploy Bridge

Use this order when moving from local setup to a hosted site:

```bash
pnpm run deploy:plan -- --target vercel --brief --no-color
pnpm db:migrate
pnpm run ops:preflight -- --target vercel --brief --no-color
pnpm --silent run ops:release -- check --target vercel --json
# deploy / promote in your host
pnpm --silent run ops:release -- verify --url https://your-domain.example --json
```

`deploy:plan` explains host env, storage, runtime, and import/deploy steps.
`Start here` in the plan gives the first host-specific launch action: a
Vercel import URL, Railway dashboard / CLI path, Render web service /
Blueprint path, `fly launch`, or Docker image build command.
`pnpm db:migrate` must run where the production `DATABASE_URL` is available;
on Vercel that usually means CI, `pnpm db:migrate && pnpm build` as the build
command, or another trusted shell with production env injected.
`ops:preflight` is the blocking pre-deploy gate for deploy-plan, production
doctor, and migration-plan evidence. `ops:release check` captures the same
evidence for CI or agent handoff. `ops:release verify` is the first
post-deploy probe against the live URL.

## Runtime Status

```bash
pnpm --silent run ops:status -- --json
pnpm --silent run ops:contracts -- --json
pnpm run ops:status -- --brief --no-color
pnpm --silent run ops:preflight -- --target vercel --json
pnpm run ops:health -- --url http://localhost:3000 --brief --no-color
```

`ops:status` is the low-token handoff for agents and CI. It emits
`schemaVersion: "np.ops.v1"`, `status`, `summary`, stable
`checks[].id`, and a `nextCommand` when the site needs follow-up.
`ops:contracts` emits `schemaVersion: "np.ops-contracts.v1"` with the shipped
local ops commands, artifact behavior, approval requirements, and mutation
safety boundaries.
`ops:preflight` combines `deploy:plan`, the production doctor, and
`ops:migrate plan` into a single deployment gate. `ops:health` checks
`/api/health/ready` for a running local or hosted site.

## Migrations And Backups

```bash
pnpm --silent run ops:migrate -- plan --json
pnpm --silent run ops:migrate -- rollback-plan --json
pnpm --silent run ops:migrate -- apply --safe --json
pnpm --silent run ops:migrate -- apply --safe --execute --approve migrate-apply --json
pnpm --silent run ops:backup -- status --json
pnpm --silent run ops:backup -- create --json
pnpm --silent run ops:backup -- verify latest --json
pnpm --silent run ops:backup -- restore-plan latest --json
pnpm --silent run ops:backup -- restore apply latest --json
pnpm --silent run ops:backup -- restore apply latest --execute --approve restore-apply --json
```

`ops:migrate` reports local/applied migration state, destructive SQL risk,
backup/apply/verify handoff actions, approval-gated safe apply, and
backup-restore rollback plans.
`ops:backup` reports manifest freshness, records operator-provided backup
manifests, verifies artifact presence, exposes record/verify/restore handoff
actions, produces restore drill plans, and can apply isolated restore drills
against `RESTORE_DATABASE_URL` / `RESTORE_STORAGE_DIR`.
Backup and restore reports also include `plan.nextCommands` so release plans
and agent handoffs preserve the exact follow-up sequence.

## Jobs

```bash
pnpm --silent run ops:jobs -- --json
pnpm --silent run ops:jobs -- pause --reason "maintenance" --json
pnpm --silent run ops:jobs -- resume --json
pnpm --silent run ops:jobs -- retry-all --state failed --json
pnpm --silent run ops:jobs -- retry-all --state failed --execute --approve retry-all --json
pnpm --silent run ops:jobs -- drain --execute --approve drain --json
NP_ENABLE_JOBS=1 pnpm run worker
```

`ops:jobs` reports worker heartbeat, pause state, and pg-boss queue counts,
can pause/resume processing for maintenance windows, dry-run bulk retries, and
start a drain by pausing new claims. Jobs are optional locally; set
`NP_ENABLE_JOBS=1` on the process that owns the long-running worker.

## Storage

```bash
pnpm --silent run ops:storage -- --json
pnpm --silent run ops:storage -- verify --json
pnpm --silent run ops:storage -- missing-files --json
pnpm --silent run ops:storage -- orphaned-files --json
pnpm --silent run ops:storage -- migrate plan --target s3 --json
pnpm --silent run ops:storage -- migrate apply --target s3 --json
pnpm --silent run ops:storage -- migrate apply --target s3 --execute --approve storage-migrate --json
pnpm --silent run ops:storage -- test --json
pnpm --silent run ops:storage -- test --execute --approve storage-test --json
```

`ops:storage` reports storage adapter readiness and local media drift, while
`verify` re-runs the integrity gate. Drift-list commands show concrete
missing/orphaned paths, `migrate plan` prepares a local-to-S3 checklist,
`migrate apply` copies indexed local objects to S3 without deleting local
source files, and `test` can run an approval-gated storage probe.

## Plugins

```bash
pnpm --silent run ops:plugins -- list --json
pnpm --silent run ops:plugins -- doctor --json
pnpm --silent run ops:plugins -- inspect reading-time --json
pnpm --silent run ops:plugins -- upgrade-plan reading-time --json
pnpm --silent run ops:plugins -- disable reading-time --json
pnpm --silent run ops:plugins -- disable reading-time --execute --approve plugin-disable --json
pnpm --silent run ops:plugins -- enable reading-time --execute --approve plugin-enable --json
```

`ops:plugins` reports plugin inventory, single-plugin manifests,
route/block conflicts, read-only upgrade plans, and approval-gated enable /
disable operations that write `np_plugins.enabled`. Doctor reports include
`nextCommand`, `projectNextCommand`, and `plan.nextCommands`.
Use the first suggested inspect command when a plugin-owned block, API route,
or page route conflict appears.

## Release And Runbooks

```bash
pnpm --silent run ops:release -- check --target vercel --json
pnpm --silent run ops:release -- plan --target vercel --json
pnpm --silent run ops:release -- apply --plan .nexpress/releases/<plan>.json --json
pnpm --silent run ops:release -- verify --url http://localhost:3000 --json
pnpm --silent run ops:runbook -- worker-not-draining --json
pnpm --silent run ops:runbook -- migration-crashed --json --out .nexpress/runbooks/migration-crashed.json
```

`release check` composes the pre-deploy gate. `release plan` persists
that gate as a replayable audit artifact under `.nexpress/releases`.
`release apply` validates the artifact and only executes commands with
`--execute --approve <planId>` after every command passes the NexPress
release-apply allowlist; execution uses structured argv specs rather than a
shell. `release verify` composes the post-deploy readiness gate. `runbook
--out <path>` writes a clean JSON artifact for common incidents with
evidence-backed diagnosis and next commands.

Release plans include global `command` values plus local `projectCommand`
values. Release apply artifacts include `execution.nextCommand` plus
`execution.projectNextCommand`. Runbooks include `nextCommands` plus
`projectNextCommands`. Ops reports and executable plans include
`projectNextCommand`, and plan steps include `projectCommand` when a
generated-app script form exists. All preserve nested `plan.nextCommands`
from migration rollback, backup restore, storage migration, and plugin
upgrade evidence so agent handoffs keep the concrete follow-up sequence.

## Doctor And Deploy Readiness

```bash
pnpm run doctor
pnpm run doctor -- --fix-plan
pnpm run deploy:plan -- --target vercel
pnpm run doctor:prod -- --target vercel
pnpm run doctor:prod -- --target vercel --fix-plan
pnpm run deploy:plan -- --target vercel --brief --no-color
pnpm run doctor:prod -- --target vercel --brief --no-color
pnpm run doctor:prod -- --target vercel --brief --no-color --fix-plan
pnpm --silent run deploy:plan -- --target vercel --json
pnpm --silent run doctor:prod -- --target vercel --json --fix-plan
```

`deploy:plan` includes `summary` and `nextCommands`. `doctor` /
`doctor:prod` include `nextCommand`, and `doctor:prod --fix-plan`
includes `blocksDeploy` plus `fixPlan[].nextCommand`. The production
doctor tightens defaults: `NP_SECRET` < 32 chars becomes an error,
`http://` SITE_URL warns, missing `NP_ENABLE_JOBS` warns, a noop error
reporter warns, and `local` storage on a multi-node platform errors.

## Vercel Checklist

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new?utm_source=nexpress&utm_campaign=oss)

Push this scaffold to GitHub, click the button, and import your repo in
Vercel. Set these env vars before the first production deploy:

- `DATABASE_URL`
- `NP_SECRET`
- `SITE_URL`
- `NP_STORAGE_ADAPTER=s3`
- `NP_S3_BUCKET`
- `NP_S3_REGION`
- `NP_S3_ENDPOINT` when using R2, MinIO, or another non-AWS S3 provider

Then run:

```bash
pnpm run deploy:plan -- --target vercel --brief --no-color
pnpm db:migrate
pnpm run ops:preflight -- --target vercel --brief --no-color
pnpm --silent run ops:release -- check --target vercel --json
```

Run `pnpm db:migrate` where Vercel's production env is already injected. Do
not depend on `vercel env pull` for sensitive `DATABASE_URL` values; Vercel
may return empty local placeholders. Preferred paths are a CI job with the
database secret, or a Vercel build command of `pnpm db:migrate && pnpm build`.

Vercel's filesystem is ephemeral, so media uploads require S3/R2/MinIO or
another S3-compatible store. For scheduled publishing, add `CRON_SECRET` in
Vercel and set `NP_SCHEDULER_TOKEN` to the same value. `vercel.json`
already points cron at `/api/internal/publish-scheduled`.

If you don't use scheduled publishing, the cron entry is a no-op. If you need
long-running background jobs, set `NP_ENABLE_JOBS=1` and run
`pnpm run worker` on a separate worker host. Vercel cron handles scheduled
HTTP calls, but not a long-lived pg-boss worker.

## Other Hosting Choices

- **Vercel** — fastest app hosting path. Start with the Vercel import URL from
  `deploy:plan --target vercel`; S3-compatible media storage is required.
- **Railway** — start with Railway's new project dashboard or
  `railway init && railway up`; add managed Postgres and durable media.
- **Render** — start with a Web Service from the scaffold repo; use a Blueprint
  if your project adds `render.yaml` for web/database/worker/cron resources.
- **Fly.io** — start with `fly launch` against the scaffold Dockerfile, then
  set secrets and run the release gate.
- **Docker self-host** — start with
  `docker build -f docker/Dockerfile -t nexpress .`; local uploads are safe
  only for one node with backed-up persistent disk.
