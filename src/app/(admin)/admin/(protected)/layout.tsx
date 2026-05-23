import { type ReactNode } from "react";
import BaseAdminLayout from "@nexpress/app/admin/protected/layout";

function DemoModeBanner() {
  if (process.env.NP_DEMO_MODE !== "1") return null;

  return (
    <div className="mb-4 rounded-md border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-950 shadow-sm dark:border-amber-700 dark:bg-amber-950 dark:text-amber-100">
      <strong className="font-semibold">Demo mode</strong>
      <span className="block sm:ml-2 sm:inline">
        This shared admin is reset on a schedule. High-risk settings are disabled, and uploaded
        media may be temporary until object storage is configured.
      </span>
    </div>
  );
}

export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <BaseAdminLayout>
      <DemoModeBanner />
      {children}
    </BaseAdminLayout>
  );
}
