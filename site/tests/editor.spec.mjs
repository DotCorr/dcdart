import { test, expect } from "@playwright/test";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
const exec = promisify(execFile);
test("new landing and editor fit desktop and mobile", async ({ page }) => {
  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: 900 });
    for (const route of ["/", "/playground"]) {
      await page.goto(route);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
      ).toBe(true);
    }
  }
  await expect(page.locator(".cm-content")).toBeVisible();
  await expect(
    page.getByRole("button", { name: "▶ Run", exact: true }),
  ).toBeVisible();
});
test("source edits compile, errors stay errors, loops stop, and drafts survive reload", async ({
  page,
}) => {
  test.skip(
    !process.env.PLAYGROUND_URL && !process.env.DCDART_LOCAL_COMPILER,
    "Set a hosted URL or a real local DCDart compiler.",
  );
  test.setTimeout(240000);
  if (process.env.DCDART_LOCAL_COMPILER) {
    await page.route("**/api/compile", async (route) => {
      const dir = await mkdtemp(path.join(tmpdir(), "dcdart-editor-test-"));
      try {
        const input = path.join(dir, "input.json");
        await writeFile(input, route.request().postData());
        let output;
        try {
          output = (
            await exec("python3", ["compiler/compile.py", input], {
              env: process.env,
            })
          ).stdout;
        } catch (e) {
          output = e.stdout;
        }
        const result = JSON.parse(output);
        await route.fulfill({
          status: result.error ? 422 : 200,
          contentType: "application/json",
          body: output,
        });
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    });
  }
  await page.goto("/playground");
  const editor = page.locator(".cm-content");
  async function source(text) {
    await editor.fill(text);
  }
  async function run() {
    await page.locator("#run-code").click();
    await expect(page.locator("#run-code")).toBeEnabled({ timeout: 100000 });
  }
  await source("@bare\nu64 answer() { return u64(42); }");
  await run();
  await expect(page.locator("#code-output")).toHaveText("42");
  await source("@bare\nu64 answer() { return u64(90) + u64(7); }");
  await run();
  await expect(page.locator("#code-output")).toHaveText("97");
  await source("@bare\nu64 answer() { return u64(; }");
  await run();
  await expect(page.locator("#pad-status")).toHaveText("Error");
  await expect(page.locator("#code-output")).toBeEmpty();
  await source(
    "@bare\nu64 answer() { var i = u64(0); while (i < u64(1)) { i = i + u64(0); } return i; }",
  );
  await run();
  await expect(page.locator("#code-diagnostics")).toContainText(
    "stopped after 2 seconds",
  );
  await source("@bare\nu64 answer() { return u64(123); }");
  await page.reload();
  await expect(editor).toContainText("123");
  await run();
  await expect(page.locator("#code-output")).toHaveText("123");
});
