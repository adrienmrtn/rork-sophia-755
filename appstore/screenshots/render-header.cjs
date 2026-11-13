// Render the product page headers: node render-header.cjs  ->  header/header-<variant>.png (3840 x 1646)
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 823 }, deviceScaleFactor: 2 });
  page.on("requestfailed", (r) => console.error("failed:", r.url()));
  fs.mkdirSync(path.join(__dirname, "header"), { recursive: true });
  for (const v of ["cards", "cards-cream", "cream", "blue"]) {
    await page.goto(pathToFileURL(path.join(__dirname, "src/header.html")).href + "?v=" + v, { waitUntil: "load" });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(400);
    await page.screenshot({ path: path.join(__dirname, "header", `header-${v}.png`) });
    console.log("header/header-" + v + ".png");
  }
  await browser.close();
})();
