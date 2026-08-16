import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { resolve } from "node:path";

import {
  analyzeNexpressRegistryMetadata,
  assertNexpressManifestUpdate,
  assertUpdateChangePaths,
  listNexpressPackageNames,
  nexpressDependenciesMatchVersion,
  parseNexpressVersion,
  parseUpdateArguments,
  verifyNexpressRegistryPackages,
} from "../scripts/update-nexpress.js";

const repoRoot = resolve(import.meta.dirname, "..");
const before = {
  dependencies: {
    "@nexpress/core": "0.4.3",
    next: "^16.0.0",
  },
  devDependencies: {
    "@nexpress/cli": "0.4.3",
    typescript: "^5.8.0",
  },
};

function registryMetadata(name: string, version = "0.4.4") {
  return {
    name,
    version,
    dist: {
      tarball: `https://registry.npmjs.org/${name}/-/${version}.tgz`,
      integrity: "sha512-example",
      attestations: {
        provenance: { predicateType: "https://slsa.dev/provenance/v1" },
      },
    },
  };
}

test("accepts one exact semver and rejects tags, ranges, and leading v", () => {
  assert.equal(parseNexpressVersion("0.4.4"), "0.4.4");
  assert.equal(parseNexpressVersion("1.0.0-rc.1"), "1.0.0-rc.1");
  for (const invalid of [undefined, "latest", "^0.4.4", "v0.4.4", "0.4"]) {
    assert.throws(() => parseNexpressVersion(invalid), /one exact npm version/);
  }
});

test("accepts pnpm run arguments with or without the separator", () => {
  assert.equal(parseUpdateArguments(["0.4.4"]), "0.4.4");
  assert.equal(parseUpdateArguments(["--", "0.4.4"]), "0.4.4");
  assert.throws(() => parseUpdateArguments([]), /Usage:/);
  assert.throws(() => parseUpdateArguments(["--"]), /Usage:/);
  assert.throws(() => parseUpdateArguments(["0.4.4", "0.4.5"]), /Usage:/);
});

test("selects every installed @nexpress package in stable order", () => {
  assert.deepEqual(listNexpressPackageNames(before), [
    "@nexpress/cli",
    "@nexpress/core",
  ]);
  assert.throws(
    () =>
      listNexpressPackageNames({
        dependencies: { "@nexpress/core": "0.4.3" },
        devDependencies: { "@nexpress/core": "0.4.3" },
      }),
    /must not appear in multiple/,
  );
});

test("recognizes an already synchronized exact package family", () => {
  const packageNames = listNexpressPackageNames(before);
  assert.equal(
    nexpressDependenciesMatchVersion(before, packageNames, "0.4.3"),
    true,
  );
  assert.equal(
    nexpressDependenciesMatchVersion(before, packageNames, "0.4.4"),
    false,
  );
  assert.equal(
    nexpressDependenciesMatchVersion(
      {
        dependencies: { ...before.dependencies, "@nexpress/core": "0.4.4" },
        devDependencies: before.devDependencies,
      },
      packageNames,
      "0.4.4",
    ),
    false,
  );
});

test("requires exact install metadata and provenance", () => {
  assert.deepEqual(
    analyzeNexpressRegistryMetadata(
      "@nexpress/core",
      "0.4.4",
      registryMetadata("@nexpress/core"),
    ),
    [],
  );
  assert.match(
    analyzeNexpressRegistryMetadata("@nexpress/core", "0.4.4", {
      ...registryMetadata("@nexpress/wrong", "0.4.3"),
      dist: {},
    }).join("\n"),
    /registry name.*registry version.*tarball.*integrity.*provenance/s,
  );
});

test("waits for both exact metadata and root package visibility", async () => {
  let attempts = 0;
  await verifyNexpressRegistryPackages(["@nexpress/core"], "0.4.4", {
    fetchImpl: async (input) => {
      const exact = String(input).endsWith("/0.4.4");
      if (exact) {
        attempts += 1;
        return new Response(
          JSON.stringify(registryMetadata("@nexpress/core")),
          { status: 200 },
        );
      }
      return new Response(
        JSON.stringify({
          name: "@nexpress/core",
          versions:
            attempts >= 2
              ? { "0.4.4": registryMetadata("@nexpress/core") }
              : {},
        }),
        { status: 200 },
      );
    },
    intervalMs: 0,
    maxIntervalMs: 0,
    timeoutMs: 1_000,
  });
  assert.equal(attempts, 2);
});

test("allows only exact NexPress dependency changes and migration artifacts", () => {
  assert.doesNotThrow(() =>
    assertNexpressManifestUpdate(
      before,
      {
        dependencies: { "@nexpress/core": "0.4.4", next: "^16.0.0" },
        devDependencies: { "@nexpress/cli": "0.4.4", typescript: "^5.8.0" },
      },
      ["@nexpress/cli", "@nexpress/core"],
      "0.4.4",
    ),
  );
  assert.throws(
    () =>
      assertNexpressManifestUpdate(
        before,
        {
          dependencies: { "@nexpress/core": "0.4.4", next: "^17.0.0" },
          devDependencies: { "@nexpress/cli": "0.4.4", typescript: "^5.8.0" },
        },
        ["@nexpress/cli", "@nexpress/core"],
        "0.4.4",
      ),
    /unrelated dependency next/,
  );
  assert.doesNotThrow(() =>
    assertUpdateChangePaths([
      "package.json",
      "pnpm-lock.yaml",
      "drizzle/0008_example.sql",
      "drizzle/meta/_journal.json",
    ]),
  );
  assert.throws(
    () => assertUpdateChangePaths(["src/config.ts"]),
    /unexpected paths/,
  );
});

test("automation opens a reviewed draft PR and verifies the exact production deployment", async () => {
  const updateWorkflow = await readFile(
    resolve(repoRoot, ".github/workflows/update-nexpress.yml"),
    "utf8",
  );
  const productionWorkflow = await readFile(
    resolve(repoRoot, ".github/workflows/production-smoke.yml"),
    "utf8",
  );

  assert.match(updateWorkflow, /workflow_dispatch:/);
  assert.match(updateWorkflow, /version:\s*\n\s+description:/);
  assert.match(updateWorkflow, /source_sha:\s*\n\s+description:/);
  assert.match(updateWorkflow, /run-name: Update NexPress.*source_sha/);
  assert.match(updateWorkflow, /\^\[0-9a-f\]\{40\}\$/);
  assert.match(updateWorkflow, /nexpress-cms\/nexpress@\$NP_UPDATE_SOURCE_SHA/);
  assert.match(updateWorkflow, /pull-requests: write/);
  assert.match(updateWorkflow, /actions: write/);
  assert.match(updateWorkflow, /gh pr create[\s\S]*--draft/);
  assert.match(updateWorkflow, /gh workflow run ci\.yml[^\n]*--ref/);
  assert.match(productionWorkflow, /deployment_status:/);
  assert.match(productionWorkflow, /environment == 'Production'/);
  assert.match(productionWorkflow, /deployment_status\.state == 'success'/);
  assert.match(productionWorkflow, /\/api\/health\/ready/);
});
