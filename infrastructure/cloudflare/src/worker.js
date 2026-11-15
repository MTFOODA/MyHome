const MAX_BODY = 10 * 1024 * 1024;
const API = /^\/api\/v1(?:\/|$)/;
const PRIVATE = /^\/(?:\.(?:env|git|dev\.vars|wrangler)[^/]*(?:\/|$)|(?:artifacts|infrastructure|backend_fastapi|tools|src|test|node_modules)(?:\/|$)|(?:package(?:-lock)?\.json|wrangler\.jsonc)$)/i;

function problem(status, detail) {
  return Response.json({ detail }, { status, headers: {
    "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff",
  } });
}

function backendOrigin(value, incoming) {
  try {
    const url = new URL(value);
    // The launcher supplies this operator-controlled, public demo tunnel origin.
    if (url.protocol !== "https:" || url.username || url.password || url.port ||
        url.pathname !== "/" || url.search || url.hash ||
        !/^[a-z0-9-]+\.trycloudflare\.com$/.test(url.hostname) || url.origin === incoming.origin) return null;
    return url;
  } catch { return null; }
}

export async function handleRequest(request, env, upstreamFetch = fetch) {
  const incoming = new URL(request.url);
  let path;
  try { path = decodeURIComponent(incoming.pathname); } catch { return problem(400, "INVALID_PATH"); }
  if (PRIVATE.test(path)) return problem(404, "NOT_FOUND");
  if (!API.test(incoming.pathname)) {
    if (/^\/api(?:\/|$)/.test(path)) return problem(404, "API_NOT_FOUND");
    if (!["GET", "HEAD"].includes(request.method)) return problem(405, "METHOD_NOT_ALLOWED");
    if (env.ASSETS) return env.ASSETS.fetch(request);
  }
  const target = backendOrigin(env.API_ORIGIN, incoming);
  if (!target) return problem(503, "BACKEND_NOT_CONFIGURED");
  target.pathname = incoming.pathname;
  target.search = incoming.search;
  const length = request.headers.get("content-length");
  if (length !== null && (!/^\d+$/.test(length) || Number(length) > MAX_BODY)) {
    return problem(413, "REQUEST_TOO_LARGE");
  }
  const headers = new Headers(request.headers);
  for (const name of ["host", "cookie", "referer", "connection", "proxy-connection", "keep-alive",
    "transfer-encoding", "te", "trailer", "upgrade", "forwarded", "x-forwarded-for",
    "x-forwarded-host", "x-forwarded-proto", "x-real-ip", "cf-access-client-id", "cf-access-client-secret"]) {
    headers.delete(name);
  }
  let tooLarge = false;
  let size = 0;
  const body = request.body?.pipeThrough(new TransformStream({
    transform(chunk, controller) {
      size += chunk.byteLength;
      if (size > MAX_BODY) { tooLarge = true; controller.error(new Error("REQUEST_TOO_LARGE")); }
      else controller.enqueue(chunk);
    },
  }));
  const abort = new AbortController();
  const timeout = setTimeout(() => abort.abort(), 30000);
  try {
    const upstream = await upstreamFetch(target.toString(), {
      method: request.method, headers, body: ["GET", "HEAD"].includes(request.method) ? undefined : body,
      redirect: "manual", signal: abort.signal, cf: { cacheTtl: 0, cacheEverything: false },
    });
    const responseHeaders = new Headers(upstream.headers);
    responseHeaders.set("Cache-Control", "no-store");
    responseHeaders.set("Pragma", "no-cache");
    responseHeaders.set("X-Content-Type-Options", "nosniff");
    responseHeaders.set("Referrer-Policy", "strict-origin-when-cross-origin");
    for (const name of ["set-cookie", "content-length", "access-control-allow-origin",
      "access-control-allow-credentials", "access-control-allow-headers", "access-control-allow-methods"]) responseHeaders.delete(name);
    const location = responseHeaders.get("location");
    if (location && upstream.status >= 300 && upstream.status < 400) {
      const redirect = new URL(location, target);
      // A canonical API slash redirect may be generated as HTTP by the local origin.
      // Rewrite only this same-backend API path; never follow a credential-bearing redirect elsewhere.
      if (redirect.hostname !== target.hostname || redirect.port || redirect.username || redirect.password ||
          !["http:", "https:"].includes(redirect.protocol) ||
          (API.test(incoming.pathname) && !API.test(redirect.pathname)) || PRIVATE.test(redirect.pathname)) {
        await upstream.body?.cancel();
        return problem(502, "INVALID_BACKEND_REDIRECT");
      }
      const destination = new URL(incoming.origin);
      destination.pathname = redirect.pathname;
      destination.search = redirect.search;
      responseHeaders.set("location", destination.toString());
    }
    return new Response(upstream.body, { status: upstream.status, statusText: upstream.statusText, headers: responseHeaders });
  } catch {
    return problem(tooLarge ? 413 : 503, tooLarge ? "REQUEST_TOO_LARGE" : "BACKEND_UNAVAILABLE");
  } finally { clearTimeout(timeout); }
}

export default { fetch(request, env) { return handleRequest(request, env); } };
