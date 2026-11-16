import { test } from "node:test";
import assert from "node:assert/strict";
import worker, { handleRequest } from "../src/worker.js";

const site = "https://myhome.example.workers.dev";
const env = { API_ORIGIN: "https://demo-origin.trycloudflare.com", ASSETS: { fetch: async () => new Response("Flutter shell") } };

test("Cloudflare's third execution-context argument is not mistaken for fetch", async (context) => {
  context.mock.method(globalThis, "fetch", async () => Response.json({ status: "ok" }));
  const response = await worker.fetch(new Request(site + "/api/v1/health"), env, { waitUntil() {} });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: "ok" });
});

test("an optional assets binding can serve static files without a backend", async () => {
  const response = await handleRequest(new Request(site + "/"), { ASSETS: env.ASSETS });
  assert.equal(await response.text(), "Flutter shell");
});
test("the deployed gateway forwards Web files and API through the same configured origin", async () => {
  const response = await handleRequest(new Request(site + "/main.dart.js?v=current"), { API_ORIGIN: env.API_ORIGIN }, async (url) => {
    assert.equal(url, env.API_ORIGIN + "/main.dart.js?v=current");
    return new Response("Flutter app", { headers: { "Content-Type": "application/javascript" } });
  });
  assert.equal(response.status, 200);
  assert.equal(await response.text(), "Flutter app");
  assert.equal(response.headers.get("content-type"), "application/javascript");
});
test("API routing precedes SPA fallbacks and rejects unknown API versions", async () => {
  const response = await handleRequest(new Request(site + "/api/v2/properties"), env);
  assert.equal(response.status, 404);
});
test("private repository paths never serve an SPA shell or files", async () => {
  for (const path of ["/admin", "/admin/ADMIN_LOGIN.txt", "/admin/credentials.json", "/ADMIN/credentials.json", "/.env", "/.env.demo", "/.envlocal", "/.gitignore", "/.dev.vars.local", "/.git/config", "/artifacts/demo-accounts.json", "/tools/setup_local.py", "/%2Eenv", "/package.json"]) {
    assert.equal((await handleRequest(new Request(site + path), env)).status, 404, path);
  }
});
test("missing/unsafe backend configuration fails closed without forwarding credentials", async () => {
  for (const origin of [undefined, "http://localhost:3001", site, "https://demo-origin.trycloudflare.com.evil.test", "https://user:pass@demo-origin.trycloudflare.com", env.API_ORIGIN + "/api"]) {
    const response = await handleRequest(new Request(site + "/api/v1/health"), { ...env, API_ORIGIN: origin }, () => { throw new Error("must not fetch"); });
    assert.equal(response.status, 503);
  }
});
test("API proxy preserves bearer/body/query with a fixed target and no cache", async () => {
  const request = new Request(site + "/api/v1/deals?q=home", { method: "POST", body: '{"amount":"2000000"}',
    headers: { Authorization: "Bearer synthetic-test-token", Cookie: "private-cookie", "X-Forwarded-For": "forged" } });
  const response = await handleRequest(request, env, async (url, options) => {
    assert.equal(url, env.API_ORIGIN + "/api/v1/deals?q=home");
    assert.equal(options.headers.get("authorization"), "Bearer synthetic-test-token");
    assert.equal(options.headers.has("cookie"), false);
    assert.equal(options.headers.has("x-forwarded-for"), false);
    assert.equal(options.redirect, "manual");
    assert.equal(await new Response(options.body).text(), '{"amount":"2000000"}');
    return Response.json({ ok: true }, { headers: { "Set-Cookie": "must-not-set", "Cache-Control": "public, max-age=999" } });
  });
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.has("set-cookie"), false);
  assert.deepEqual(await response.json(), { ok: true });
});
test("local canonical API redirects stay on the public worker origin", async () => {
  const response = await handleRequest(new Request(site + "/api/v1/favorites/"), env,
    async () => new Response(null, { status: 307, headers: { Location: "http://demo-origin.trycloudflare.com/api/v1/favorites" } }));
  assert.equal(response.headers.get("location"), site + "/api/v1/favorites");
});
test("upstream redirects cannot send an authorization token to another host", async () => {
  const response = await handleRequest(new Request(site + "/api/v1/deals"), env,
    async () => new Response(null, { status: 302, headers: { Location: "https://other.example/" } }));
  assert.equal(response.status, 502);
  assert.equal(response.headers.has("location"), false);
});
test("offline backend returns an explicit uncached 503 instead of HTML or fake success", async () => {
  const response = await handleRequest(new Request(site + "/api/v1/health"), env, async () => { throw new Error("offline"); });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).detail, "BACKEND_UNAVAILABLE");
});
test("oversized declared and streamed API bodies are bounded", async () => {
  const declared = new Request(site + "/api/v1/assets", { method: "POST", body: "x", headers: { "Content-Length": "10485761" } });
  assert.equal((await handleRequest(declared, env)).status, 413);
  const body = new ReadableStream({ start(controller) {
    controller.enqueue(new Uint8Array(6 * 1024 * 1024));
    controller.enqueue(new Uint8Array(6 * 1024 * 1024)); controller.close();
  } });
  const streamed = new Request(site + "/api/v1/assets", { method: "POST", body, duplex: "half" });
  const response = await handleRequest(streamed, env, async (_, options) => {
    await new Response(options.body).arrayBuffer(); return new Response("unexpected");
  });
  assert.equal(response.status, 413);
});
