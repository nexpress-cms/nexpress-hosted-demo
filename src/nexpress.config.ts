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

export default defineConfig({
  site: {
    name: "nexpress-published-smoke-20260523-023815",
    url: process.env.SITE_URL || "http://localhost:3000",
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
    secret: process.env.NP_SECRET!,
  },
  plugins: [
    ...defaultPlugins,
    // @nexpress:plugins-list-start
    // @nexpress:plugins-list-end
  ],
});
