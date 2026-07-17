import "./globals.css";

import { Analytics } from "@vercel/analytics/next";
import { type ReactNode } from "react";
import BaseRootLayout, { viewport } from "@nexpress/app/root/layout";

export { viewport };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <BaseRootLayout>
      {children}
      <Analytics />
    </BaseRootLayout>
  );
}
