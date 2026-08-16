import { type ReactNode } from "react";
import BaseSiteLayout from "@nexpress/app/site/group/layout";

export const dynamic = "force-dynamic";

function DemoSiteBar() {
  if (process.env.NP_DEMO_MODE !== "1") return null;

  return (
    <div className="border-b border-slate-200 bg-slate-950 px-4 py-2 text-sm text-white">
      <div className="mx-auto flex max-w-6xl flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <span>
          NexPress hosted demo. Explore the default theme, seeded content, and
          admin workflow.
        </span>
        <div className="flex items-center gap-4">
          <a
            className="font-semibold text-white underline underline-offset-4 hover:text-amber-200"
            href="/admin/demo-login"
          >
            Open demo admin
          </a>
          <a
            className="font-semibold text-white underline underline-offset-4 hover:text-amber-200"
            href="https://github.com/nexpress-cms/nexpress/issues/new?template=install_feedback.yml"
            rel="noreferrer"
            target="_blank"
          >
            Share feedback
          </a>
        </div>
      </div>
    </div>
  );
}

export default function SiteLayout({ children }: { children: ReactNode }) {
  return (
    <BaseSiteLayout>
      <DemoSiteBar />
      {children}
    </BaseSiteLayout>
  );
}
