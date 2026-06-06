import { defineConfig } from "@nexpress/core";
import {
  defaultCollections,
  defaultI18n,
  defaultPlugins,
  defaultThemes,
  storageFromEnv,
} from "@nexpress/app/config-defaults";

// @nexpress:plugins-imports-start
// @nexpress:plugins-imports-end
// @nexpress:themes-imports-start
// @nexpress:themes-imports-end

const siteUrl =
  process.env.SITE_URL ||
  (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : "http://localhost:3000");

// Preview deployments are public smoke builds; production and local setups still require NP_SECRET.
const authSecret =
  process.env.NP_SECRET ||
  (process.env.VERCEL_ENV === "preview"
    ? "nexpress-hosted-demo-preview-only-auth-secret"
    : undefined);

export default defineConfig({
  site: {
    name: "NexPress Hosted Demo",
    url: siteUrl,
  },
  db: {
    connectionString: process.env.DATABASE_URL!,
  },
  storage: storageFromEnv(),
  collections: [...defaultCollections],
  themes: [
    ...defaultThemes,
    // @nexpress:themes-list-start
    // @nexpress:themes-list-end
  ],
  i18n: defaultI18n,
  auth: {
    secret: authSecret!,
  },
  plugins: [
    ...defaultPlugins,
    // @nexpress:plugins-list-start
    // @nexpress:plugins-list-end
  ],
});
