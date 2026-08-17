import { appendFile, readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";

const transientStatuses = new Set([502, 503, 504]);
const repositoryPattern = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const branchPattern = /^automation\/nexpress-v[0-9A-Za-z.+-]+$/;
const commitShaPattern = /^[0-9a-f]{40}$/;

type FetchLike = typeof fetch;

type RetryEvent = {
  attempt: number;
  attempts: number;
  delayMs: number;
  status: number;
  phase: string;
};

type PullRequest = {
  number: number;
  html_url: string;
  head?: { sha?: string };
};

type WorkflowRun = {
  id: number;
  head_sha: string;
  html_url: string;
  created_at: string;
};

export type PublishNexpressUpdateOptions = {
  token: string;
  repository: string;
  branch: string;
  headSha: string;
  title: string;
  body: string;
  base?: string;
  workflowFile?: string;
  apiUrl?: string;
  fetchImpl?: FetchLike;
  sleepImpl?: (delayMs: number) => Promise<void>;
  attempts?: number;
  retryBaseDelayMs?: number;
  retryMaxDelayMs?: number;
  discoveryAttempts?: number;
  discoveryDelayMs?: number;
  lookupTimeoutMs?: number;
  onRetry?: (event: RetryEvent) => void;
};

type PublishResult = Awaited<
  ReturnType<typeof publishNexpressUpdatePullRequest>
>;

type PublishCliOptions = {
  argv?: string[];
  env?: Record<string, string | undefined>;
  readFileImpl?: (path: string, encoding: "utf8") => Promise<string>;
  appendFileImpl?: (
    path: string,
    contents: string,
    encoding: "utf8",
  ) => Promise<unknown>;
  publishImpl?: (
    options: PublishNexpressUpdateOptions,
  ) => Promise<PublishResult>;
};

export async function publishNexpressUpdatePullRequest({
  token,
  repository,
  branch,
  headSha,
  title,
  body,
  base = "main",
  workflowFile = "ci.yml",
  apiUrl = "https://api.github.com",
  fetchImpl = fetch,
  sleepImpl = sleep,
  attempts = 6,
  retryBaseDelayMs = 1_000,
  retryMaxDelayMs = 30_000,
  discoveryAttempts = 6,
  discoveryDelayMs = 2_000,
  lookupTimeoutMs = 60_000,
  onRetry = ({ attempt, attempts: total, delayMs, status, phase }) => {
    console.warn(
      `[nexpress-update] ${phase} received GitHub ${status}; retry ${attempt}/${total} in ${delayMs}ms.`,
    );
  },
}: PublishNexpressUpdateOptions) {
  requireInputs({ token, repository, branch, headSha, title, body });
  const [owner] = repository.split("/");
  const workflowPath = encodeURIComponent(workflowFile);
  const request = <T>(path: string, init: RequestInit = {}) =>
    githubRequest<T>({ apiUrl, repository, path, token, fetchImpl, init });
  const findPullRequest = async () => {
    const params = new URLSearchParams({
      state: "open",
      head: `${owner}:${branch}`,
      base,
      per_page: "20",
    });
    const pulls = await request<PullRequest[]>(`/pulls?${params.toString()}`);
    return pulls.find((pull) => pull.head?.sha === headSha) ?? pulls[0] ?? null;
  };

  let pullRequest = await retryRequest(findPullRequest, {
    attempts,
    retryBaseDelayMs,
    retryMaxDelayMs,
    sleepImpl,
    onRetry,
    phase: "pull request lookup",
  });
  if (pullRequest) {
    pullRequest = await retryRequest(
      () =>
        request<PullRequest>(`/pulls/${pullRequest!.number}`, {
          method: "PATCH",
          body: JSON.stringify({ title, body }),
        }),
      {
        attempts,
        retryBaseDelayMs,
        retryMaxDelayMs,
        sleepImpl,
        onRetry,
        phase: "pull request update",
      },
    );
  } else {
    const createdPullRequest = await createWithReconciliation({
      create: () =>
        request<PullRequest>("/pulls", {
          method: "POST",
          body: JSON.stringify({
            title,
            head: branch,
            base,
            body,
            draft: true,
          }),
        }),
      lookup: findPullRequest,
      attempts,
      retryBaseDelayMs,
      retryMaxDelayMs,
      discoveryAttempts,
      discoveryDelayMs,
      sleepImpl,
      onRetry,
      phase: "pull request creation",
    });
    if (!createdPullRequest)
      throw new Error("Pull request creation returned no result.");
    pullRequest = createdPullRequest;
  }

  const findWorkflowRun = async () => {
    const params = new URLSearchParams({ branch, per_page: "100" });
    const result = await request<{ workflow_runs?: WorkflowRun[] }>(
      `/actions/workflows/${workflowPath}/runs?${params.toString()}`,
    );
    return (
      result.workflow_runs
        ?.filter((run) => run.head_sha === headSha && run.html_url)
        .sort(
          (left, right) =>
            Date.parse(right.created_at) - Date.parse(left.created_at),
        )[0] ?? null
    );
  };
  const discovered = await discoverResource({
    lookup: findWorkflowRun,
    attempts: discoveryAttempts,
    delayMs: discoveryDelayMs,
    sleepImpl,
    onRetry,
    phase: "CI run discovery",
  });
  let workflowRun = discovered.resource;
  let dispatchedCi = false;
  if (!workflowRun) {
    if (!discovered.observedSuccessfulLookup) {
      throw new Error(
        "Cannot safely dispatch CI without a successful existing-run lookup.",
      );
    }
    workflowRun = await createWithReconciliation({
      create: async () => {
        dispatchedCi = true;
        await request<null>(`/actions/workflows/${workflowPath}/dispatches`, {
          method: "POST",
          body: JSON.stringify({ ref: branch }),
        });
        return null;
      },
      lookup: findWorkflowRun,
      attempts,
      retryBaseDelayMs,
      retryMaxDelayMs,
      discoveryAttempts,
      discoveryDelayMs,
      sleepImpl,
      onRetry,
      phase: "CI workflow dispatch",
      allowNullCreateResult: true,
    });
    if (!workflowRun) {
      const startedAt = Date.now();
      while (Date.now() - startedAt < lookupTimeoutMs) {
        try {
          workflowRun = await findWorkflowRun();
          if (workflowRun) break;
        } catch (error) {
          if (!isTransientGitHubError(error)) throw error;
          onRetry({
            attempt: 1,
            attempts: 1,
            delayMs: 5_000,
            status: error.status,
            phase: "dispatched CI run lookup",
          });
        }
        await sleepImpl(5_000);
      }
    }
  }
  if (!workflowRun)
    throw new Error(`Timed out waiting for CI run for ${headSha}.`);

  return { pullRequest, workflowRun, dispatchedCi };
}

async function createWithReconciliation<T>({
  create,
  lookup,
  attempts,
  retryBaseDelayMs,
  retryMaxDelayMs,
  discoveryAttempts,
  discoveryDelayMs,
  sleepImpl,
  onRetry,
  phase,
  allowNullCreateResult = false,
}: {
  create: () => Promise<T | null>;
  lookup: () => Promise<T | null>;
  attempts: number;
  retryBaseDelayMs: number;
  retryMaxDelayMs: number;
  discoveryAttempts: number;
  discoveryDelayMs: number;
  sleepImpl: (delayMs: number) => Promise<void>;
  onRetry: (event: RetryEvent) => void;
  phase: string;
  allowNullCreateResult?: boolean;
}) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      const created = await create();
      if (created !== null || allowNullCreateResult) return created;
      throw new Error(`${phase} returned no result.`);
    } catch (error) {
      if (!isTransientGitHubError(error)) throw error;
      const reconciled = await discoverResource({
        lookup,
        attempts: discoveryAttempts,
        delayMs: discoveryDelayMs,
        initialDelay: true,
        sleepImpl,
        onRetry,
        phase: `${phase} reconciliation`,
      });
      if (reconciled.resource) return reconciled.resource;
      if (!reconciled.observedSuccessfulLookup || attempt === attempts)
        throw error;

      const delayMs = Math.min(
        retryMaxDelayMs,
        retryBaseDelayMs * 2 ** (attempt - 1),
      );
      onRetry({
        attempt,
        attempts,
        delayMs,
        status: error.status,
        phase,
      });
      await sleepImpl(delayMs);
    }
  }
  throw new Error(`${phase} retry exhausted unexpectedly.`);
}

async function discoverResource<T>({
  lookup,
  attempts,
  delayMs,
  initialDelay = false,
  sleepImpl,
  onRetry,
  phase,
}: {
  lookup: () => Promise<T | null>;
  attempts: number;
  delayMs: number;
  initialDelay?: boolean;
  sleepImpl: (delayMs: number) => Promise<void>;
  onRetry: (event: RetryEvent) => void;
  phase: string;
}) {
  let observedSuccessfulLookup = false;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    if (initialDelay || attempt > 1) await sleepImpl(delayMs);
    try {
      const resource = await lookup();
      observedSuccessfulLookup = true;
      if (resource) return { resource, observedSuccessfulLookup };
    } catch (error) {
      if (!isTransientGitHubError(error)) throw error;
      onRetry({ attempt, attempts, delayMs, status: error.status, phase });
    }
  }
  return { resource: null, observedSuccessfulLookup };
}

async function retryRequest<T>(
  request: () => Promise<T>,
  {
    attempts,
    retryBaseDelayMs,
    retryMaxDelayMs,
    sleepImpl,
    onRetry,
    phase,
  }: {
    attempts: number;
    retryBaseDelayMs: number;
    retryMaxDelayMs: number;
    sleepImpl: (delayMs: number) => Promise<void>;
    onRetry: (event: RetryEvent) => void;
    phase: string;
  },
) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await request();
    } catch (error) {
      if (!isTransientGitHubError(error) || attempt === attempts) throw error;
      const delayMs = Math.min(
        retryMaxDelayMs,
        retryBaseDelayMs * 2 ** (attempt - 1),
      );
      onRetry({ attempt, attempts, delayMs, status: error.status, phase });
      await sleepImpl(delayMs);
    }
  }
  throw new Error(`${phase} retry exhausted unexpectedly.`);
}

class GitHubRequestError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function isTransientGitHubError(error: unknown): error is GitHubRequestError {
  return (
    error instanceof GitHubRequestError && transientStatuses.has(error.status)
  );
}

async function githubRequest<T>({
  apiUrl,
  repository,
  path,
  token,
  fetchImpl,
  init = {},
}: {
  apiUrl: string;
  repository: string;
  path: string;
  token: string;
  fetchImpl: FetchLike;
  init?: RequestInit;
}) {
  const response = await fetchImpl(`${apiUrl}/repos/${repository}${path}`, {
    ...init,
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      "x-github-api-version": "2022-11-28",
      ...(init.headers || {}),
    },
  });
  if (response.status === 204) return null as T;
  const responseBody = await response.text();
  if (!response.ok) {
    throw new GitHubRequestError(
      response.status,
      `${init.method || "GET"} ${path} failed (${response.status}): ${responseBody}`,
    );
  }
  return (responseBody ? JSON.parse(responseBody) : null) as T;
}

function requireInputs({
  token,
  repository,
  branch,
  headSha,
  title,
  body,
}: Pick<
  PublishNexpressUpdateOptions,
  "token" | "repository" | "branch" | "headSha" | "title" | "body"
>) {
  if (!token) throw new Error("GH_TOKEN is required.");
  if (!repositoryPattern.test(repository))
    throw new Error("Invalid GitHub repository.");
  if (!branchPattern.test(branch))
    throw new Error("Invalid NexPress update branch.");
  if (!commitShaPattern.test(headSha))
    throw new Error("Invalid NexPress update commit SHA.");
  if (!title.trim() || !body.trim())
    throw new Error("Pull request title and body are required.");
}

export async function runPublishNexpressUpdateCli({
  argv = process.argv.slice(2),
  env = process.env,
  readFileImpl = readFile,
  appendFileImpl = appendFile,
  publishImpl = publishNexpressUpdatePullRequest,
}: PublishCliOptions = {}) {
  const [branch, headSha, bodyFile, extraArgument] = argv;
  if (!branch || !headSha || !bodyFile || extraArgument) {
    throw new Error(
      "Usage: tsx scripts/publish-nexpress-update-pr.ts <branch> <head-sha> <body-file>",
    );
  }
  const version = env.NP_UPDATE_VERSION || "";
  if (!version) throw new Error("NP_UPDATE_VERSION is required.");

  const result = await publishImpl({
    token: env.GH_TOKEN || "",
    repository: env.GITHUB_REPOSITORY || "",
    branch,
    headSha,
    title: `chore: update NexPress to ${version}`,
    body: await readFileImpl(bodyFile, "utf8"),
    apiUrl: env.GITHUB_API_URL || "https://api.github.com",
  });
  const summary = [
    `Draft update PR: [${result.pullRequest.html_url}](${result.pullRequest.html_url}).`,
    `Correlated CI run: [${result.workflowRun.html_url}](${result.workflowRun.html_url}).`,
  ].join("\n");
  if (env.GITHUB_STEP_SUMMARY) {
    await appendFileImpl(env.GITHUB_STEP_SUMMARY, `${summary}\n`, "utf8");
  }
  console.log(summary);
  return result;
}

const entrypoint = process.argv[1]
  ? pathToFileURL(process.argv[1]).href
  : undefined;
if (entrypoint === import.meta.url) {
  runPublishNexpressUpdateCli().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}

function sleep(delayMs: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, delayMs));
}
