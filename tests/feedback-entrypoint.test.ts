import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { resolve } from "node:path";

const repoRoot = resolve(import.meta.dirname, "..");
const feedbackUrl =
  "https://github.com/nexpress-cms/nexpress/issues/new?template=install_feedback.yml";

test("the hosted demo exposes the first-run feedback form without replacing the demo", async () => {
  const layout = await readFile(
    resolve(repoRoot, "src/app/(site)/layout.tsx"),
    "utf8",
  );
  const readme = await readFile(resolve(repoRoot, "README.md"), "utf8");

  assert.match(layout, /NP_DEMO_MODE !== "1"/);
  assert.match(layout, /Open demo admin/);
  assert.match(layout, /Share feedback/);
  assert.match(layout, /target="_blank"/);
  assert.match(layout, /rel="noreferrer"/);
  assert.ok(layout.includes(feedbackUrl));
  assert.ok(readme.includes(feedbackUrl));
});
