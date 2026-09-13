import { getSandbox } from "@cloudflare/sandbox";
export { Sandbox } from "@cloudflare/sandbox";
const headers = {
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
};
const json = (data: unknown, status = 200) =>
  Response.json(data, { status, headers });
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/api/health")
      return json({ compiler: "DCDart", execution: "browser-wasm" });
    if (url.pathname !== "/api/compile")
      return json({ error: "Not found" }, 404);
    if (request.method !== "POST") return json({ error: "Use POST" }, 405);
    const origin = request.headers.get("Origin");
    if (origin && origin !== url.origin)
      return json({ error: "Cross-origin compilation is not allowed." }, 403);
    if (
      !(
        await env.COMPILE_LIMIT.limit({
          key: request.headers.get("CF-Connecting-IP") || "local",
        })
      ).success
    )
      return json(
        { error: "Please wait a minute before compiling again." },
        429,
      );
    const reader = request.body?.getReader();
    if (!reader) return json({ error: "Source is required." }, 400);
    let size = 0;
    const chunks: Uint8Array[] = [];
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 40000) {
        await reader.cancel();
        return json({ error: "Source must be at most 32 KiB." }, 413);
      }
      chunks.push(value);
    }
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.length;
    }
    let payload: { source: string };
    try {
      payload = JSON.parse(new TextDecoder().decode(bytes));
    } catch {
      return json({ error: "Invalid JSON." }, 400);
    }
    if (
      typeof payload?.source !== "string" ||
      new TextEncoder().encode(payload.source).length > 32768
    )
      return json({ error: "Source must be at most 32 KiB." }, 400);
    const sandbox = getSandbox(env.Sandbox, crypto.randomUUID(), {
      sleepAfter: "1m",
      enableDefaultSession: false,
    });
    try {
      await sandbox.writeFile(
        "/tmp/input.json",
        JSON.stringify({ source: payload.source }),
      );
      const result = await sandbox.exec(
        "timeout -k 2 40 python3 /opt/dcdart/compile.py /tmp/input.json",
        { timeout: 50000 },
      );
      if (result.exitCode === 124 || result.exitCode === 137)
        return json(
          {
            error:
              "Compilation exceeded its time limit. Try a smaller program.",
          },
          422,
        );
      let output;
      try {
        output = JSON.parse(result.stdout);
      } catch {
        return json(
          {
            error: `Compiler process failed (${result.exitCode}): ${(result.stderr || result.stdout || "No diagnostics returned").slice(-2000)}`,
          },
          503,
        );
      }
      return json(output, result.success ? 200 : 422);
    } catch (error) {
      console.error(
        "compiler_unavailable",
        error instanceof Error ? error.name : "error",
      );
      return json(
        { error: "The compiler is starting or busy. Please retry shortly." },
        503,
      );
    } finally {
      await sandbox
        .destroy()
        .catch(() => console.error("compiler_cleanup_failed"));
    }
  },
};
