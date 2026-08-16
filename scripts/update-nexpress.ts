import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

interface PackageManifest {
  dependencies?: unknown;
  devDependencies?: unknown;
  name?: unknown;
  version?: unknown;
}

interface UpdateNexpressOptions {
  fetchImpl?: typeof fetch;
  intervalMs?: number;
  maxIntervalMs?: number;
  timeoutMs?: number;
}

const exactVersionPattern =
  /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;
const dependencyFields = ["dependencies", "devDependencies"] as const;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function readManifest(repoRoot: string): PackageManifest {
  return JSON.parse(
    readFileSync(resolve(repoRoot, "package.json"), "utf8"),
  ) as PackageManifest;
}

function dependencyMap(
  manifest: PackageManifest,
  field: (typeof dependencyFields)[number],
) {
  const value = manifest[field];
  if (value === undefined) return {};
  const record = asRecord(value);
  if (
    !record ||
    Object.values(record).some((specifier) => typeof specifier !== "string")
  ) {
    throw new Error(`package.json ${field} must be a string map.`);
  }
  return record as Record<string, string>;
}

export function parseNexpressVersion(value: string | undefined): string {
  const version = value?.trim();
  if (!version || !exactVersionPattern.test(version)) {
    throw new Error(
      "Pass one exact npm version such as 0.4.4 (without a leading v or range).",
    );
  }
  return version;
}

export function parseUpdateArguments(args: string[]): string {
  const normalizedArgs = args[0] === "--" ? args.slice(1) : args;
  if (normalizedArgs.length !== 1) {
    throw new Error("Usage: pnpm run update:nexpress -- <exact-version>");
  }
  return parseNexpressVersion(normalizedArgs[0]);
}

export function listNexpressPackageNames(manifest: PackageManifest): string[] {
  const names: string[] = [];
  const seen = new Set<string>();
  for (const field of dependencyFields) {
    for (const name of Object.keys(dependencyMap(manifest, field))) {
      if (!name.startsWith("@nexpress/")) continue;
      if (seen.has(name))
        throw new Error(
          `${name} must not appear in multiple dependency fields.`,
        );
      seen.add(name);
      names.push(name);
    }
  }
  if (names.length === 0)
    throw new Error(
      "The hosted demo must depend on at least one @nexpress package.",
    );
  return names.sort((left, right) => left.localeCompare(right));
}

export function nexpressDependenciesMatchVersion(
  manifest: PackageManifest,
  packageNames: string[],
  version: string,
): boolean {
  const specifiers = new Map<string, string>();
  for (const field of dependencyFields) {
    for (const [name, specifier] of Object.entries(
      dependencyMap(manifest, field),
    )) {
      specifiers.set(name, specifier);
    }
  }
  return packageNames.every((name) => specifiers.get(name) === version);
}

export function analyzeNexpressRegistryMetadata(
  expectedName: string,
  expectedVersion: string,
  value: unknown,
): string[] {
  const metadata = asRecord(value);
  if (!metadata)
    return [`${expectedName}@${expectedVersion}: metadata is not an object`];
  const problems: string[] = [];
  if (metadata.name !== expectedName) {
    problems.push(
      `${expectedName}@${expectedVersion}: registry name is ${String(metadata.name)}`,
    );
  }
  if (metadata.version !== expectedVersion) {
    problems.push(
      `${expectedName}@${expectedVersion}: registry version is ${String(metadata.version)}`,
    );
  }
  const dist = asRecord(metadata.dist);
  if (typeof dist?.tarball !== "string" || dist.tarball.length === 0) {
    problems.push(`${expectedName}@${expectedVersion}: tarball is missing`);
  }
  if (typeof dist?.integrity !== "string" || dist.integrity.length === 0) {
    problems.push(`${expectedName}@${expectedVersion}: integrity is missing`);
  }
  const attestations = asRecord(dist?.attestations);
  const provenance = asRecord(attestations?.provenance);
  if (
    typeof provenance?.predicateType !== "string" ||
    provenance.predicateType.length === 0
  ) {
    problems.push(`${expectedName}@${expectedVersion}: provenance is missing`);
  }
  return problems;
}

function registryPackagePath(packageName: string): string {
  return packageName.startsWith("@")
    ? packageName.replace("/", "%2f")
    : packageName;
}

async function inspectRegistryPackage(
  packageName: string,
  version: string,
  fetchImpl: typeof fetch,
): Promise<string[]> {
  const packagePath = registryPackagePath(packageName);
  const exactUrl = `https://registry.npmjs.org/${packagePath}/${encodeURIComponent(version)}`;
  const packumentUrl = `https://registry.npmjs.org/${packagePath}`;
  try {
    const [exactResponse, packumentResponse] = await Promise.all([
      fetchImpl(exactUrl, {
        headers: { accept: "application/json" },
        signal: AbortSignal.timeout(15_000),
      }),
      fetchImpl(packumentUrl, {
        headers: { accept: "application/vnd.npm.install-v1+json" },
        signal: AbortSignal.timeout(15_000),
      }),
    ]);
    const problems: string[] = [];
    if (!exactResponse.ok) {
      problems.push(
        `${packageName}@${version}: exact metadata returned HTTP ${exactResponse.status}`,
      );
    } else {
      problems.push(
        ...analyzeNexpressRegistryMetadata(
          packageName,
          version,
          await exactResponse.json(),
        ),
      );
    }
    if (!packumentResponse.ok) {
      problems.push(
        `${packageName}@${version}: package metadata returned HTTP ${packumentResponse.status}`,
      );
    } else {
      const packument = asRecord((await packumentResponse.json()) as unknown);
      const versions = asRecord(packument?.versions);
      if (packument?.name !== packageName || !asRecord(versions?.[version])) {
        problems.push(
          `${packageName}@${version}: package metadata omits the exact version`,
        );
      }
    }
    return problems;
  } catch (error) {
    return [
      `${packageName}@${version}: registry request failed: ${
        error instanceof Error ? error.message : String(error)
      }`,
    ];
  }
}

export async function verifyNexpressRegistryPackages(
  packageNames: string[],
  version: string,
  options: UpdateNexpressOptions = {},
): Promise<void> {
  const fetchImpl = options.fetchImpl ?? fetch;
  const timeoutMs = options.timeoutMs ?? 120_000;
  const intervalMs = options.intervalMs ?? 5_000;
  const maxIntervalMs = Math.max(intervalMs, options.maxIntervalMs ?? 20_000);
  const deadline = Date.now() + timeoutMs;
  let retryIntervalMs = intervalMs;

  while (true) {
    const problems = (
      await Promise.all(
        packageNames.map((packageName) =>
          inspectRegistryPackage(packageName, version, fetchImpl),
        ),
      )
    ).flat();
    if (problems.length === 0) return;
    if (Date.now() >= deadline) {
      throw new Error(
        `NexPress registry verification timed out:\n${problems.join("\n")}`,
      );
    }
    console.warn(
      `[update:nexpress] npm is not ready (${problems.length} issue(s)); retrying in ${retryIntervalMs}ms.`,
    );
    await new Promise((resolvePromise) =>
      setTimeout(resolvePromise, retryIntervalMs),
    );
    retryIntervalMs = Math.min(
      maxIntervalMs,
      Math.max(retryIntervalMs * 2, intervalMs),
    );
  }
}

export function assertNexpressManifestUpdate(
  before: PackageManifest,
  after: PackageManifest,
  packageNames: string[],
  version: string,
): void {
  const expectedNames = new Set(packageNames);
  for (const field of dependencyFields) {
    const beforeDependencies = dependencyMap(before, field);
    const afterDependencies = dependencyMap(after, field);
    if (
      Object.keys(beforeDependencies).length !==
      Object.keys(afterDependencies).length
    ) {
      throw new Error(
        `pnpm changed the ${field} package inventory unexpectedly.`,
      );
    }
    for (const [name, beforeSpecifier] of Object.entries(beforeDependencies)) {
      const afterSpecifier = afterDependencies[name];
      if (expectedNames.has(name)) {
        if (afterSpecifier !== version) {
          throw new Error(
            `${name} must resolve to exact version ${version}, got ${afterSpecifier}.`,
          );
        }
      } else if (afterSpecifier !== beforeSpecifier) {
        throw new Error(`pnpm changed unrelated dependency ${name}.`);
      }
    }
  }
}

export function assertUpdateChangePaths(paths: string[]): void {
  const unexpected = paths.filter(
    (path) =>
      path !== "package.json" &&
      path !== "pnpm-lock.yaml" &&
      !path.startsWith("drizzle/"),
  );
  if (unexpected.length > 0) {
    throw new Error(
      `Update produced unexpected paths:\n${unexpected.join("\n")}`,
    );
  }
}

function changedPaths(repoRoot: string): string[] {
  const output = execFileSync(
    "git",
    ["status", "--porcelain=v1", "--untracked-files=all"],
    { cwd: repoRoot, encoding: "utf8" },
  );
  return output
    .split("\n")
    .filter((line) => line.length >= 4)
    .map((line) => line.slice(3).split(" -> ").at(-1) ?? line.slice(3));
}

export async function updateNexpress(
  repoRoot: string,
  version: string,
): Promise<void> {
  const initialPaths = changedPaths(repoRoot);
  if (initialPaths.length > 0) {
    throw new Error("Refusing to update NexPress from a dirty working tree.");
  }

  const before = readManifest(repoRoot);
  const packageNames = listNexpressPackageNames(before);
  console.log(
    `[update:nexpress] verifying ${packageNames.length} package(s) at exact version ${version}.`,
  );
  await verifyNexpressRegistryPackages(packageNames, version);
  if (nexpressDependenciesMatchVersion(before, packageNames, version)) {
    console.log(
      `[update:nexpress] ${packageNames.length} package(s) are already synchronized to ${version}.`,
    );
    return;
  }
  execFileSync(
    "pnpm",
    ["up", ...packageNames.map((name) => `${name}@${version}`), "--save-exact"],
    { cwd: repoRoot, stdio: "inherit" },
  );
  assertNexpressManifestUpdate(
    before,
    readManifest(repoRoot),
    packageNames,
    version,
  );
  execFileSync("pnpm", ["db:generate"], { cwd: repoRoot, stdio: "inherit" });
  assertUpdateChangePaths(changedPaths(repoRoot));
  console.log(
    `[update:nexpress] synchronized ${packageNames.length} package(s) to ${version}.`,
  );
}

const entrypoint = process.argv[1]
  ? pathToFileURL(resolve(process.argv[1])).href
  : undefined;
if (entrypoint === import.meta.url) {
  const main = async () => {
    await updateNexpress(
      resolve(import.meta.dirname, ".."),
      parseUpdateArguments(process.argv.slice(2)),
    );
  };
  main().catch((error: unknown) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
