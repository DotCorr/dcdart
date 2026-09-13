import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./tests",
  testMatch: ["browser.spec.mjs", "editor.spec.mjs"],
  use: {
    baseURL: process.env.PLAYGROUND_URL || "http://127.0.0.1:8799",
    headless: true,
  },
  reporter: "list",
  workers: 1,
  webServer: process.env.PLAYGROUND_URL
    ? undefined
    : {
        command: "npm run dev -- --port 8799",
        url: "http://127.0.0.1:8799",
        reuseExistingServer: false,
      },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
