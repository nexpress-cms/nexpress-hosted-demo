import assert from "node:assert/strict";
import test from "node:test";

import type { NpAuthUser } from "@nexpress/core/auth";
import { NextRequest } from "next/server";

import {
  createDemoLoginResponse,
  type DemoLoginDependencies,
} from "../src/lib/demo-login.js";

const visitor: NpAuthUser = {
  id: "0e4610e0-6319-44b6-8789-6005f10ca4e7",
  email: "demo@nexpress.local",
  name: "Demo Visitor",
  role: "admin",
  tokenVersion: 7,
};

test("demo login creates a DB-backed staff session before redirecting", async () => {
  const db = {};
  let ensured = false;
  let sessionInput:
    | {
        user: NpAuthUser;
        secret: string;
        database: unknown;
        accessExpiration: number;
        refreshExpiration: number;
        userAgent: string | null | undefined;
        ip: string | null | undefined;
      }
    | undefined;
  let cookies:
    | {
        access: string;
        refresh: string;
        csrf: string;
      }
    | undefined;

  const dependencies: DemoLoginDependencies<typeof db> = {
    ensureWrite: async () => {
      ensured = true;
    },
    ensureAccounts: async () => ({ operator: visitor, visitor }),
    getAuthConfig: () => ({
      secret: "test-secret-test-secret-test-secret",
      tokenExpiration: 7_200,
      refreshTokenExpiration: 604_800,
    }),
    getSessionDb: () => db,
    createSession: async (user, secret, database, options) => {
      sessionInput = {
        user,
        secret,
        database,
        accessExpiration: options.accessExpiration,
        refreshExpiration: options.refreshExpiration,
        userAgent: options.userAgent,
        ip: options.ip,
      };
      return {
        sessionId: "f52906dc-6469-4b68-a7c0-fbf07a041a71",
        access: "persisted-access-token",
        refresh: "persisted-refresh-token",
      };
    },
    setCookies: (_response, tokens) => {
      cookies = tokens;
    },
  };

  const response = await createDemoLoginResponse(
    new NextRequest("https://demo.example.com/api/admin/demo-login", {
      headers: {
        "user-agent": "demo-login-test",
        "x-forwarded-for": "203.0.113.9, 10.0.0.1",
      },
    }),
    dependencies,
  );

  assert.equal(ensured, true);
  assert.deepEqual(sessionInput, {
    user: visitor,
    secret: "test-secret-test-secret-test-secret",
    database: db,
    accessExpiration: 7_200,
    refreshExpiration: 604_800,
    userAgent: "demo-login-test",
    ip: "203.0.113.9",
  });
  assert.equal(response.status, 307);
  assert.equal(response.headers.get("location"), "https://demo.example.com/admin");
  assert.equal(cookies?.access, "persisted-access-token");
  assert.equal(cookies?.refresh, "persisted-refresh-token");
  assert.match(cookies?.csrf ?? "", /^[0-9a-f-]{36}$/);
});
