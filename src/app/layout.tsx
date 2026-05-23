import "./globals.css";

import { Analytics } from "@vercel/analytics/next";
import { type ReactNode } from "react";
import BaseRootLayout from "@nexpress/app/root/layout";

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <BaseRootLayout>
      {children}
      <Analytics />
    </BaseRootLayout>
  );
}
