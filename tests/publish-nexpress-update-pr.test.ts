import assert from "node:assert/strict";
import test from "node:test";

import {
  publishNexpressUpdatePullRequest,
  runPublishNexpressUpdateCli,
  type PublishNexpressUpdateOptions,
} from "../scripts/publish-nexpress-update-pr.js";

const repository = "nexpress-cms/nexpress-hosted-demo";
const branch = "automation/nexpress-v0.4.6";
const headSha = "a".repeat(40);
const pullRequest = {
  number: 31,
  html_url: "https://github.com/nexpress-cms/nexpress-hosted-demo/pull/31",
  head: { sha: headSha },
};
const workflowRun = {
  id: 1001,
  head_sha: headSha,
  html_url:
    "https://github.com/nexpress-cms/nexpress-hosted-demo/actions/runs/1001",
  created_at: "2026-08-18T00:00:00.000Z",
};

function options(
  fetchImpl: NonNullable<PublishNexpressUpdateOptions["fetchImpl"]>,
) {
  return {
    token: "test-token",
    repository,
    branch,
    headSha,
    title: "chore: update NexPress to 0.4.6",
    body: "validated update",
    fetchImpl,
    sleepImpl: async () => {},
    discoveryDelayMs: 0,
    retryBaseDelayMs: 0,
  };
}

test("creates one draft PR and reuses its automatic exact-sha CI run", async () => {
  const calls: Array<{ url: string; init: RequestInit }> = [];
  const result = await publishNexpressUpdatePullRequest(
    options(async (input, init = {}) => {
      const url = String(input);
      calls.push({ url, init });
      if (url.includes("/pulls?") && !init.method) return json([]);
      if (url.endsWith("/pulls") && init.method === "POST")
        return json(pullRequest, 201);
      if (url.includes("/actions/workflows/ci.yml/runs?")) {
        return json({ workflow_runs: [workflowRun] });
      }
      return assert.fail(`unexpected request: ${init.method || "GET"} ${url}`);
    }),
  );

  assert.equal(result.pullRequest.html_url, pullRequest.html_url);
  assert.equal(result.workflowRun.html_url, workflowRun.html_url);
  assert.equal(result.dispatchedCi, false);
  const create = calls.find(
    ({ url, init }) => url.endsWith("/pulls") && init.method === "POST",
  );
  assert.ok(create);
  assert.deepEqual(JSON.parse(String(create.init.body)), {
    title: "chore: update NexPress to 0.4.6",
    head: branch,
    base: "main",
    body: "validated update",
    draft: true,
  });
  assert.equal(
    calls.some(({ url }) => url.endsWith("/dispatches")),
    false,
  );
});

test("reconciles an ambiguous PR create without creating a duplicate", async () => {
  let pullExists = false;
  let creates = 0;
  const result = await publishNexpressUpdatePullRequest({
    ...options(async (input, init = {}) => {
      const url = String(input);
      if (url.includes("/pulls?") && !init.method)
        return json(pullExists ? [pullRequest] : []);
      if (url.endsWith("/pulls") && init.method === "POST") {
        creates += 1;
        pullExists = true;
        return new Response("unavailable", { status: 503 });
      }
      if (url.includes("/actions/workflows/ci.yml/runs?")) {
        return json({ workflow_runs: [workflowRun] });
      }
      return assert.fail(`unexpected request: ${init.method || "GET"} ${url}`);
    }),
    discoveryAttempts: 2,
  });

  assert.equal(result.pullRequest.number, 31);
  assert.equal(creates, 1);
});

test("retries an idempotent PR update after a transient response", async () => {
  let patches = 0;
  const delays: number[] = [];
  const result = await publishNexpressUpdatePullRequest({
    ...options(async (input, init = {}) => {
      const url = String(input);
      if (url.includes("/pulls?") && !init.method) return json([pullRequest]);
      if (url.endsWith("/pulls/31") && init.method === "PATCH") {
        patches += 1;
        return patches === 1
          ? new Response("unavailable", { status: 502 })
          : json(pullRequest);
      }
      if (url.includes("/actions/workflows/ci.yml/runs?")) {
        return json({ workflow_runs: [workflowRun] });
      }
      return assert.fail(`unexpected request: ${init.method || "GET"} ${url}`);
    }),
    sleepImpl: async (delayMs) => {
      delays.push(delayMs);
    },
    retryBaseDelayMs: 9,
  });

  assert.equal(result.pullRequest.number, 31);
  assert.equal(patches, 2);
  assert.deepEqual(delays, [9]);
});

test("reconciles an ambiguous CI dispatch and never dispatches the same SHA twice", async () => {
  let ciExists = false;
  let dispatches = 0;
  const result = await publishNexpressUpdatePullRequest({
    ...options(async (input, init = {}) => {
      const url = String(input);
      if (url.includes("/pulls?") && !init.method) return json([pullRequest]);
      if (url.endsWith("/pulls/31") && init.method === "PATCH")
        return json(pullRequest);
      if (url.includes("/actions/workflows/ci.yml/runs?")) {
        return json({ workflow_runs: ciExists ? [workflowRun] : [] });
      }
      if (
        url.endsWith("/actions/workflows/ci.yml/dispatches") &&
        init.method === "POST"
      ) {
        dispatches += 1;
        ciExists = true;
        return new Response("unavailable", { status: 504 });
      }
      return assert.fail(`unexpected request: ${init.method || "GET"} ${url}`);
    }),
    discoveryAttempts: 2,
  });

  assert.equal(result.workflowRun.id, 1001);
  assert.equal(dispatches, 1);
});

test("does not retry a permanent PR creation rejection", async () => {
  let creates = 0;
  await assert.rejects(
    publishNexpressUpdatePullRequest(
      options(async (input, init = {}) => {
        const url = String(input);
        if (url.includes("/pulls?") && !init.method) return json([]);
        if (url.endsWith("/pulls") && init.method === "POST") {
          creates += 1;
          return new Response("invalid", { status: 422 });
        }
        return assert.fail(
          `unexpected request: ${init.method || "GET"} ${url}`,
        );
      }),
    ),
    /failed \(422\)/,
  );
  assert.equal(creates, 1);
});

test("CLI publishes the exact workflow inputs and writes correlated links", async () => {
  let published: PublishNexpressUpdateOptions | undefined;
  let summary = "";
  const result = await runPublishNexpressUpdateCli({
    argv: [branch, headSha, "/tmp/update-body.md"],
    env: {
      GH_TOKEN: "workflow-token",
      GITHUB_REPOSITORY: repository,
      GITHUB_API_URL: "https://github.test/api/v3",
      GITHUB_STEP_SUMMARY: "/tmp/step-summary.md",
      NP_UPDATE_VERSION: "0.4.6",
    },
    readFileImpl: async (path, encoding) => {
      assert.equal(path, "/tmp/update-body.md");
      assert.equal(encoding, "utf8");
      return "validated update";
    },
    appendFileImpl: async (path, contents, encoding) => {
      assert.equal(path, "/tmp/step-summary.md");
      assert.equal(encoding, "utf8");
      summary += contents;
    },
    publishImpl: async (input) => {
      published = input;
      return { pullRequest, workflowRun, dispatchedCi: false };
    },
  });

  assert.equal(result.pullRequest.number, 31);
  assert.deepEqual(published, {
    token: "workflow-token",
    repository,
    branch,
    headSha,
    title: "chore: update NexPress to 0.4.6",
    body: "validated update",
    apiUrl: "https://github.test/api/v3",
  });
  assert.match(summary, /pull\/31/);
  assert.match(summary, /actions\/runs\/1001/);
});

function json(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "content-type": "application/json" },
  });
}
