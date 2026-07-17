-- NexPress 0.4 validates persisted site settings as one exact, closed object.
-- The hosted demo previously accepted arbitrary JSON (including non-canonical
-- site URLs), so reset the runtime-only values to their safe defaults before
-- the new bootstrap reads them. The public origin still comes from SITE_URL.
UPDATE "np_sites"
SET "settings" = '{"siteUrl":null,"defaultLocale":null,"timezone":null}'::jsonb
WHERE "settings" IS DISTINCT FROM '{"siteUrl":null,"defaultLocale":null,"timezone":null}'::jsonb;--> statement-breakpoint

-- These values moved onto np_sites before 0.4 and are no longer valid rows in
-- the closed framework setting registry.
DELETE FROM "np_settings" WHERE "key" IN ('site', 'description');
