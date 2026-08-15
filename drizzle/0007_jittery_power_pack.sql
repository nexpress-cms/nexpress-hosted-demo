CREATE TABLE "np_c_shop-categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"image" uuid,
	"featured" boolean DEFAULT false,
	"display_order" integer DEFAULT 0 NOT NULL,
	"slug" text NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-product-reviews__photos" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"file" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-product-reviews" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"member_author_id" uuid,
	"product" uuid NOT NULL,
	"purchase_key" text NOT NULL,
	"rating" integer NOT NULL,
	"title" text NOT NULL,
	"body" text NOT NULL,
	"verified_purchase" boolean DEFAULT true NOT NULL,
	"moderation_hidden" boolean DEFAULT false NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-products__categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shop_products_id" uuid NOT NULL,
	"target_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-products__gallery" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"image" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"name" text NOT NULL,
	"summary" text,
	"description" jsonb NOT NULL,
	"primary_image" uuid,
	"currency" text DEFAULT 'KRW' NOT NULL,
	"price_minor" integer DEFAULT 0 NOT NULL,
	"compare_at_price_minor" integer,
	"tax_included" boolean DEFAULT true,
	"sku" text,
	"track_inventory" boolean DEFAULT true,
	"stock_quantity" integer DEFAULT 0 NOT NULL,
	"low_stock_threshold" integer DEFAULT 5 NOT NULL,
	"featured" boolean DEFAULT false,
	"available" boolean DEFAULT false NOT NULL,
	"inventory_state" text DEFAULT 'out-of-stock' NOT NULL,
	"skin" text DEFAULT 'classic' NOT NULL,
	"slug" text NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-products__variants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"name" text NOT NULL,
	"sku" text NOT NULL,
	"option_summary" text,
	"price_minor" integer,
	"stock_quantity" integer DEFAULT 0 NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-promotions__categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shop_promotions_id" uuid NOT NULL,
	"target_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-promotions__products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shop_promotions_id" uuid NOT NULL,
	"target_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-promotions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"name" text NOT NULL,
	"code" text,
	"automatic" boolean DEFAULT false NOT NULL,
	"kind" text DEFAULT 'fixed' NOT NULL,
	"currency" text DEFAULT 'KRW' NOT NULL,
	"value" integer DEFAULT 1 NOT NULL,
	"maximum_discount_minor" integer,
	"minimum_subtotal_minor" integer DEFAULT 0 NOT NULL,
	"target" text DEFAULT 'order' NOT NULL,
	"starts_at" timestamp with time zone,
	"ends_at" timestamp with time zone,
	"priority" integer DEFAULT 0 NOT NULL,
	"stackable" boolean DEFAULT false NOT NULL,
	"total_usage_limit" integer DEFAULT 0 NOT NULL,
	"per_owner_usage_limit" integer DEFAULT 0 NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-shipping-policies__administrativeAreas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"area" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-shipping-policies__categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shop_shipping_policies_id" uuid NOT NULL,
	"target_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-shipping-policies__postalPrefixes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"parent_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"prefix" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-shipping-policies__products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shop_shipping_policies_id" uuid NOT NULL,
	"target_id" uuid NOT NULL,
	"order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "np_c_shop-shipping-policies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"visibility" text DEFAULT 'public' NOT NULL,
	"name" text NOT NULL,
	"method_code" text NOT NULL,
	"kind" text DEFAULT 'base' NOT NULL,
	"label" text NOT NULL,
	"currency" text DEFAULT 'KRW' NOT NULL,
	"amount_minor" integer DEFAULT 0 NOT NULL,
	"free_threshold_minor" integer,
	"threshold_basis" text DEFAULT 'discounted-subtotal' NOT NULL,
	"minimum_days" integer,
	"maximum_days" integer,
	"destination_scope" text DEFAULT 'all' NOT NULL,
	"country_code" text,
	"cart_scope" text DEFAULT 'all' NOT NULL,
	"starts_at" timestamp with time zone,
	"ends_at" timestamp with time zone,
	"priority" integer DEFAULT 0 NOT NULL,
	"site_id" text DEFAULT 'default' NOT NULL,
	"published_at" timestamp with time zone,
	"search_vector" "tsvector"
);
--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "context_type" text;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "context_id" text;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "context_label" text;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "context_href" text;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "context_proof" text;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "answer_body" jsonb;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "answered_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "np_c_forum-posts" ADD COLUMN "answered_by_user_id" text;--> statement-breakpoint
ALTER TABLE "np_c_shop-categories" ADD CONSTRAINT "np_c_shop-categories_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-categories" ADD CONSTRAINT "np_c_shop-categories_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-categories" ADD CONSTRAINT "np_c_shop-categories_image_np_media_id_fk" FOREIGN KEY ("image") REFERENCES "public"."np_media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews__photos" ADD CONSTRAINT "np_c_shop-product-reviews__photos_parent_id_np_c_shop-product-reviews_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_shop-product-reviews"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews__photos" ADD CONSTRAINT "np_c_shop-product-reviews__photos_file_np_media_id_fk" FOREIGN KEY ("file") REFERENCES "public"."np_media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews" ADD CONSTRAINT "np_c_shop-product-reviews_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews" ADD CONSTRAINT "np_c_shop-product-reviews_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews" ADD CONSTRAINT "np_c_shop-product-reviews_member_author_id_np_members_id_fk" FOREIGN KEY ("member_author_id") REFERENCES "public"."np_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-product-reviews" ADD CONSTRAINT "np_c_shop-product-reviews_product_np_c_shop-products_id_fk" FOREIGN KEY ("product") REFERENCES "public"."np_c_shop-products"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products__categories" ADD CONSTRAINT "np_c_shop-products__categories_shop_products_id_np_c_shop-products_id_fk" FOREIGN KEY ("shop_products_id") REFERENCES "public"."np_c_shop-products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products__categories" ADD CONSTRAINT "np_c_shop-products__categories_target_id_np_c_shop-categories_id_fk" FOREIGN KEY ("target_id") REFERENCES "public"."np_c_shop-categories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products__gallery" ADD CONSTRAINT "np_c_shop-products__gallery_parent_id_np_c_shop-products_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_shop-products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products__gallery" ADD CONSTRAINT "np_c_shop-products__gallery_image_np_media_id_fk" FOREIGN KEY ("image") REFERENCES "public"."np_media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products" ADD CONSTRAINT "np_c_shop-products_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products" ADD CONSTRAINT "np_c_shop-products_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products" ADD CONSTRAINT "np_c_shop-products_primary_image_np_media_id_fk" FOREIGN KEY ("primary_image") REFERENCES "public"."np_media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-products__variants" ADD CONSTRAINT "np_c_shop-products__variants_parent_id_np_c_shop-products_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_shop-products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions__categories" ADD CONSTRAINT "np_c_shop-promotions__categories_shop_promotions_id_np_c_shop-promotions_id_fk" FOREIGN KEY ("shop_promotions_id") REFERENCES "public"."np_c_shop-promotions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions__categories" ADD CONSTRAINT "np_c_shop-promotions__categories_target_id_np_c_shop-categories_id_fk" FOREIGN KEY ("target_id") REFERENCES "public"."np_c_shop-categories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions__products" ADD CONSTRAINT "np_c_shop-promotions__products_shop_promotions_id_np_c_shop-promotions_id_fk" FOREIGN KEY ("shop_promotions_id") REFERENCES "public"."np_c_shop-promotions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions__products" ADD CONSTRAINT "np_c_shop-promotions__products_target_id_np_c_shop-products_id_fk" FOREIGN KEY ("target_id") REFERENCES "public"."np_c_shop-products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions" ADD CONSTRAINT "np_c_shop-promotions_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-promotions" ADD CONSTRAINT "np_c_shop-promotions_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__administrativeAreas" ADD CONSTRAINT "np_c_shop-shipping-policies__administrativeAreas_parent_id_np_c_shop-shipping-policies_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_shop-shipping-policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__categories" ADD CONSTRAINT "np_c_shop-shipping-policies__categories_shop_shipping_policies_id_np_c_shop-shipping-policies_id_fk" FOREIGN KEY ("shop_shipping_policies_id") REFERENCES "public"."np_c_shop-shipping-policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__categories" ADD CONSTRAINT "np_c_shop-shipping-policies__categories_target_id_np_c_shop-categories_id_fk" FOREIGN KEY ("target_id") REFERENCES "public"."np_c_shop-categories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__postalPrefixes" ADD CONSTRAINT "np_c_shop-shipping-policies__postalPrefixes_parent_id_np_c_shop-shipping-policies_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."np_c_shop-shipping-policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__products" ADD CONSTRAINT "np_c_shop-shipping-policies__products_shop_shipping_policies_id_np_c_shop-shipping-policies_id_fk" FOREIGN KEY ("shop_shipping_policies_id") REFERENCES "public"."np_c_shop-shipping-policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies__products" ADD CONSTRAINT "np_c_shop-shipping-policies__products_target_id_np_c_shop-products_id_fk" FOREIGN KEY ("target_id") REFERENCES "public"."np_c_shop-products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies" ADD CONSTRAINT "np_c_shop-shipping-policies_created_by_np_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "np_c_shop-shipping-policies" ADD CONSTRAINT "np_c_shop-shipping-policies_updated_by_np_users_id_fk" FOREIGN KEY ("updated_by") REFERENCES "public"."np_users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "np_c_shop-categories_status_idx" ON "np_c_shop-categories" USING btree ("status");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-categories_site_slug_idx" ON "np_c_shop-categories" USING btree ("site_id","slug");--> statement-breakpoint
CREATE INDEX "np_c_shop-categories_site_idx" ON "np_c_shop-categories" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-product-reviews__photos_parent_idx" ON "np_c_shop-product-reviews__photos" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-product-reviews_status_idx" ON "np_c_shop-product-reviews" USING btree ("status");--> statement-breakpoint
CREATE INDEX "np_c_shop-product-reviews_member_author_idx" ON "np_c_shop-product-reviews" USING btree ("member_author_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-product-reviews_site_purchase_key_uidx" ON "np_c_shop-product-reviews" USING btree ("site_id","purchase_key");--> statement-breakpoint
CREATE INDEX "np_c_shop-product-reviews_site_idx" ON "np_c_shop-product-reviews" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-products__categories_shop_products_id_idx" ON "np_c_shop-products__categories" USING btree ("shop_products_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-products__categories_parent_target_uidx" ON "np_c_shop-products__categories" USING btree ("shop_products_id","target_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-products__gallery_parent_idx" ON "np_c_shop-products__gallery" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-products_status_idx" ON "np_c_shop-products" USING btree ("status");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-products_site_sku_uidx" ON "np_c_shop-products" USING btree ("site_id","sku");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-products_site_slug_idx" ON "np_c_shop-products" USING btree ("site_id","slug");--> statement-breakpoint
CREATE INDEX "np_c_shop-products_site_idx" ON "np_c_shop-products" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-products__variants_parent_idx" ON "np_c_shop-products__variants" USING btree ("parent_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-products__variants_parent_sku_uidx" ON "np_c_shop-products__variants" USING btree ("parent_id","sku");--> statement-breakpoint
CREATE INDEX "np_c_shop-promotions__categories_shop_promotions_id_idx" ON "np_c_shop-promotions__categories" USING btree ("shop_promotions_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-promotions__categories_parent_target_uidx" ON "np_c_shop-promotions__categories" USING btree ("shop_promotions_id","target_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-promotions__products_shop_promotions_id_idx" ON "np_c_shop-promotions__products" USING btree ("shop_promotions_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-promotions__products_parent_target_uidx" ON "np_c_shop-promotions__products" USING btree ("shop_promotions_id","target_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-promotions_status_idx" ON "np_c_shop-promotions" USING btree ("status");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-promotions_site_code_uidx" ON "np_c_shop-promotions" USING btree ("site_id","code");--> statement-breakpoint
CREATE INDEX "np_c_shop-promotions_site_idx" ON "np_c_shop-promotions" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies__administrativeAreas_parent_idx" ON "np_c_shop-shipping-policies__administrativeAreas" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies__categories_shop_shipping_policies_id_idx" ON "np_c_shop-shipping-policies__categories" USING btree ("shop_shipping_policies_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-shipping-policies__categories_parent_target_uidx" ON "np_c_shop-shipping-policies__categories" USING btree ("shop_shipping_policies_id","target_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies__postalPrefixes_parent_idx" ON "np_c_shop-shipping-policies__postalPrefixes" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies__products_shop_shipping_policies_id_idx" ON "np_c_shop-shipping-policies__products" USING btree ("shop_shipping_policies_id");--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_shop-shipping-policies__products_parent_target_uidx" ON "np_c_shop-shipping-policies__products" USING btree ("shop_shipping_policies_id","target_id");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies_status_idx" ON "np_c_shop-shipping-policies" USING btree ("status");--> statement-breakpoint
CREATE INDEX "np_c_shop-shipping-policies_site_idx" ON "np_c_shop-shipping-policies" USING btree ("site_id");--> statement-breakpoint
CREATE INDEX "np_plugin_storage_plugin_site_expiry_idx" ON "np_plugin_storage" USING btree ("plugin_id","site_id","expires_at");--> statement-breakpoint
CREATE INDEX "np_plugin_storage_order_id_hash_idx" ON "np_plugin_storage" USING hash (("value"->>'orderId')) WHERE ("np_plugin_storage"."value"->>'orderId') is not null;--> statement-breakpoint
CREATE UNIQUE INDEX "np_c_forum-boards_site_key_uidx" ON "np_c_forum-boards" USING btree ("site_id","key");