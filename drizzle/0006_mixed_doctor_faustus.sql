CREATE TABLE "np_community_realtime_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sequence" bigserial NOT NULL,
	"channel" text NOT NULL,
	"target_type" text,
	"target_id" uuid,
	"member_id" uuid,
	"site_id" text DEFAULT 'default' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_community_realtime_channel_check" CHECK ("np_community_realtime_events"."channel" in ('comments', 'reactions', 'notifications')),
	CONSTRAINT "np_community_realtime_route_check" CHECK ((
        ("np_community_realtime_events"."channel" in ('comments', 'reactions')
          and "np_community_realtime_events"."target_type" is not null
          and "np_community_realtime_events"."target_id" is not null
          and "np_community_realtime_events"."member_id" is null)
        or
        ("np_community_realtime_events"."channel" = 'notifications'
          and "np_community_realtime_events"."target_type" is null
          and "np_community_realtime_events"."target_id" is null
          and "np_community_realtime_events"."member_id" is not null)
      ))
);
--> statement-breakpoint
CREATE TABLE "np_content_views" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"target_type" text NOT NULL,
	"target_id" uuid NOT NULL,
	"viewer_hash" text NOT NULL,
	"viewed_on" date NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_content_views_daily_visitor_uq" UNIQUE("site_id","target_type","target_id","viewer_hash","viewed_on")
);
--> statement-breakpoint
CREATE TABLE "np_site_plugins" (
	"site_id" text NOT NULL,
	"plugin_id" text NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "np_site_plugins_site_id_plugin_id_pk" PRIMARY KEY("site_id","plugin_id")
);
--> statement-breakpoint
CREATE TABLE "np_c_forum-boards__categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"key" text NOT NULL,
	"label" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_forum-boards" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"key" text NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"skin" text DEFAULT 'classic' NOT NULL,
	"write_mode" text DEFAULT 'members' NOT NULL,
	"audience" text DEFAULT 'public' NOT NULL,
	"moderation" text DEFAULT 'published' NOT NULL,
	"comments_enabled" boolean DEFAULT true NOT NULL,
	"page_size" integer DEFAULT 20 NOT NULL,
	"attachments_enabled" boolean DEFAULT true NOT NULL,
	"max_attachments" integer DEFAULT 5 NOT NULL,
	"max_attachment_size_mb" integer DEFAULT 20 NOT NULL,
	"slug" text NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
CREATE TABLE "np_c_forum-posts__attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"file" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_forum-posts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"member_author_id" uuid,
	"board" uuid NOT NULL,
	"board_key" text,
	"title" text NOT NULL,
	"body" jsonb NOT NULL,
	"category" text,
	"audience" text DEFAULT 'public' NOT NULL,
	"moderation_hidden" boolean DEFAULT false NOT NULL,
	"pinned" boolean DEFAULT false,
	"locked" boolean DEFAULT false,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
DELETE FROM "np_comments" WHERE "target_type" = 'discussions';--> statement-breakpoint
DELETE FROM "np_follows" WHERE "target_type" = 'discussions';--> statement-breakpoint
DELETE FROM "np_reactions" WHERE "target_type" = 'discussions';--> statement-breakpoint
DELETE FROM "np_reports" WHERE "target_type" = 'discussions';--> statement-breakpoint
DELETE FROM "np_media_refs" WHERE "collection" = 'discussions';--> statement-breakpoint
DELETE FROM "np_revisions" WHERE "collection" = 'discussions';--> statement-breakpoint
DELETE FROM "np_slug_history" WHERE "collection" = 'discussions';--> statement-breakpoint
ALTER TABLE "np_c_discussions" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
DROP TABLE "np_c_discussions" CASCADE;--> statement-breakpoint
ALTER TABLE "np_media" ADD COLUMN "site_id" text DEFAULT 'default' NOT NULL;--> statement-breakpoint
ALTER TABLE "np_media_folders" ADD COLUMN "site_id" text DEFAULT 'default' NOT NULL;--> statement-breakpoint
ALTER TABLE "np_media_refs" ADD COLUMN "site_id" text DEFAULT 'default' NOT NULL;--> statement-breakpoint
ALTER TABLE "np_community_realtime_events" ADD CONSTRAINT "np_community_realtime_events_member_id_np_members_id_fk" FOREIGN KEY ("member_id") REFERENCES "public"."np_members"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-boards__categories" ADD CONSTRAINT "np_c_forum-boards__categories_parent_id_np_c_forum-boards_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_forum-boards"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-boards" ADD CONSTRAINT "np_c_forum-boards_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-boards" ADD CONSTRAINT "np_c_forum-boards_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts__attachments" ADD CONSTRAINT "np_c_forum-posts__attachments_parent_id_np_c_forum-posts_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_forum-posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts__attachments" ADD CONSTRAINT "np_c_forum-posts__attachments_file_np_media_id_fk" FOREIGN KEY ("file") REFERENCES "public"."np_media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD CONSTRAINT "np_c_forum-posts_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD CONSTRAINT "np_c_forum-posts_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD CONSTRAINT "np_c_forum-posts_member_author_id_np_members_id_fk" FOREIGN KEY ("member_author_id") REFERENCES "public"."np_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD CONSTRAINT "np_c_forum-posts_board_np_c_forum-boards_id_fk" FOREIGN KEY ("board") REFERENCES "public"."np_c_forum-boards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "np_community_realtime_document_idx" ON "np_community_realtime_events" USING btree ("site_id","target_type","target_id","sequence");--> statement-breakpoint
CREATE INDEX "np_community_realtime_inbox_idx" ON "np_community_realtime_events" USING btree ("site_id","member_id","sequence");--> statement-breakpoint
CREATE UNIQUE INDEX "np_community_realtime_sequence_uidx" ON "np_community_realtime_events" USING btree ("sequence");--> statement-breakpoint
CREATE INDEX "np_community_realtime_retention_idx" ON "np_community_realtime_events" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "np_content_views_target_idx" ON "np_content_views" USING btree ("site_id","target_type","target_id");--> statement-breakpoint
CREATE INDEX "np_content_views_day_idx" ON "np_content_views" USING btree ("site_id","viewed_on");--> statement-breakpoint
CREATE INDEX "np_site_plugins_plugin_id_idx" ON "np_site_plugins" USING btree ("plugin_id");--> statement-breakpoint
CREATE INDEX "np_site_plugins_site_id_idx" ON "np_site_plugins" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-boards__categories_parent_idx" ON "np_c_forum-boards__categories" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-boards_status_idx" ON "np_c_forum-boards" USING btree ("status");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_forum-boards_site_slug_idx" ON "np_c_forum-boards" USING btree ("site_id","slug");--> statement-breakpoint
CREATE INDEX "np_c_forum-boards_site_idx" ON "np_c_forum-boards" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-posts__attachments_parent_idx" ON "np_c_forum-posts__attachments" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-posts_status_idx" ON "np_c_forum-posts" USING btree ("status");--> statement-breakpoint
CREATE INDEX "np_c_forum-posts_member_author_idx" ON "np_c_forum-posts" USING btree ("member_author_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-posts_site_idx" ON "np_c_forum-posts" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_forum-posts_board_list_idx" ON "np_c_forum-posts" USING btree ("site_id","board","status","pinned","created_at" DESC);--> statement-breakpoint
CREATE INDEX "np_media_site_created_idx" ON "np_media" USING btree ("site_id","created_at");--> statement-breakpoint
CREATE INDEX "np_media_site_hash_idx" ON "np_media" USING btree ("site_id","hash");--> statement-breakpoint
CREATE INDEX "np_media_folders_site_parent_idx" ON "np_media_folders" USING btree ("site_id","parent_id");--> statement-breakpoint
CREATE INDEX "np_media_refs_site_document_idx" ON "np_media_refs" USING btree ("site_id","collection","document_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_reports_unresolved_reporter_target_uidx" ON "np_reports" USING btree ("site_id","reporter_id","target_type","target_id") WHERE "np_reports"."resolved_at" is null;--> statement-breakpoint
INSERT INTO "np_site_plugins" ("site_id", "plugin_id", "enabled", "updated_at")
SELECT "sites"."id", "np_plugins"."id", false, "np_plugins"."updated_at"
FROM (
	SELECT "id" FROM "np_sites"
	UNION ALL
	SELECT 'default' WHERE NOT EXISTS (SELECT 1 FROM "np_sites")
) AS "sites"
CROSS JOIN "np_plugins"
WHERE "np_plugins"."enabled" = false
ON CONFLICT ("site_id", "plugin_id") DO NOTHING;--> statement-breakpoint
ALTER TABLE "np_plugins" DROP COLUMN "enabled";
