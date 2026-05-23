import { createNextConfig } from "@nexpress/app/config/next-config";
import type { NextConfig } from "next";

const config = createNextConfig();

export default {
  ...config,
  outputFileTracingIncludes: {
    ...(config.outputFileTracingIncludes ?? {}),
    "/api/internal/demo-migrate": ["./drizzle/**/*"],
  },
} satisfies NextConfig;
