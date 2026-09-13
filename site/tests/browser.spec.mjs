import { test, expect } from "@playwright/test";
test("landing page runs genuine WASM and changes its output", async ({
  page,
}) => {
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto("/");
  await page.getByRole("button", { name: "Run ↗", exact: true }).click();
  await expect(page.locator("#quick-result")).toHaveText("4950");
  await page.locator("#quick-n").fill("11");
  await page.locator("#quick-button").click();
  await expect(page.locator("#quick-result")).toHaveText("55");
  expect(errors).toEqual([]);
});
test("all demos, real heap accounting, traps, unsigned precision and reset", async ({
  page,
}) => {
  await page.goto("/examples");
  await expect(page.locator("#playground")).toBeVisible();
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("4950");
  await page.locator("[data-id=collatz]").click();
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("59542");
  await expect(page.locator("#heap-status")).toHaveText(
    "Live allocations after return: 0",
  );
  await page.locator("#function").selectOption("collatzSteps");
  await page.locator("#arg-0").fill("18446744073709551615");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("Runtime trap");
  await page.locator("#reset").click();
  await expect(page.locator("#arg-0")).toHaveValue("27");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("111");
  await page.locator("[data-id=recursion]").click();
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("5050");
  await expect(page.locator("#heap-status")).toContainText(": 0");
  await page.locator("[data-id=arith]").click();
  await page.locator("#function").selectOption("divU64");
  await page.locator("#arg-0").fill("18446744073709551615");
  await page.locator("#arg-1").fill("1");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("18446744073709551615");
  await page.locator("#arg-1").fill("0");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("Runtime trap");
  await page.locator("#arg-0").fill("-1");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("unsigned whole number");
  await page.locator("#arg-0").fill("18446744073709551616");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("exceeds");
  await page.locator("[data-id=float]").click();
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("0.30000000000000004");
  await page.locator("#function").selectOption("divF64");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("Infinity");
});
test("long execution is terminated and next run works", async ({ page }) => {
  await page.goto("/examples");
  await page.locator("#arg-0").fill("1000000000000");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText(
    "stopped after 2 seconds",
    { timeout: 10000 },
  );
  await page.locator("#reset").click();
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("4950");
});
test("missing binary is reported rather than replaced with canned output", async ({
  page,
}) => {
  await page.route("**/runtime/loop.wasm", (route) =>
    route.fulfill({ status: 404, body: "missing" }),
  );
  await page.goto("/examples");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("download failed");
});
test("tampered binary fails integrity validation", async ({ page }) => {
  await page.route("**/runtime/loop.wasm", (route) =>
    route.fulfill({ status: 200, body: "invalid" }),
  );
  await page.goto("/examples");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toContainText("integrity check failed");
});
test("mobile layouts and docs remain usable", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  for (const route of ["/", "/examples", "/docs"]) {
    await page.goto(route);
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
  }
  await page.goto("/examples");
  await page.locator("#run").click();
  await expect(page.locator("#result")).toHaveText("4950");
});
test("public content and runtime responses have correct headers", async ({
  request,
}) => {
  const wasm = await request.get("/runtime/loop.wasm");
  expect(wasm.ok()).toBe(true);
  expect(wasm.headers()["content-type"]).toContain("application/wasm");
  const home = await request.get("/");
  expect(home.headers()["content-security-policy"]).toContain(
    "worker-src 'self'",
  );
  const missing = await request.get("/not-a-real-page");
  expect(missing.status()).toBe(404);
});
