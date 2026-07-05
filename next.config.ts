import { createNextConfig } from "@nexpress/app/config/next-config";

export default createNextConfig({
  outputFileTracingIncludes: {
    "/*": [
      "./node_modules/.pnpm/sharp@0.35.3*/node_modules/sharp/**/*",
      "./node_modules/.pnpm/@img+sharp-linux-x64@0.35.3/node_modules/@img/sharp-linux-x64/**/*",
      "./node_modules/.pnpm/@img+sharp-libvips-linux-x64@1.3.2/node_modules/@img/sharp-libvips-linux-x64/**/*",
    ],
  },
});
