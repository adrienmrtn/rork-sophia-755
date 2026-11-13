// Render the iPad 13" set (2064 x 2752): node render-ipad.cjs [variant]  ->  en-US/ipad-13-<variant>/NN.png
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");
const { PANOS } = require("./src/pano.js");
(async () => {
  const v = process.argv[2] || "showcase-bold";
  const V = PANOS[v], n = V.panels.length, locale = Object.keys(V.copy)[0];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 516 * n, height: 688 }, deviceScaleFactor: 4 });
  page.on("requestfailed", (r) => console.error("failed:", r.url()));
  await page.goto(pathToFileURL(path.join(__dirname, "src/pano-ipad.html")).href + "?v=" + v, { waitUntil: "load" });
  for (const f of page.frames()) { await f.waitForLoadState("load"); await f.evaluate(() => document.fonts.ready); }
  await page.waitForTimeout(600);
  const dir = path.join(__dirname, locale, "ipad-13-" + v);
  fs.mkdirSync(dir, { recursive: true });
  for (let i = 0; i < n; i++) {
    await page.screenshot({ path: path.join(dir, String(i + 1).padStart(2, "0") + ".png"), clip: { x: 516 * i, y: 0, width: 516, height: 688 } });
  }
  console.log(path.relative(__dirname, dir), n, "panels");
  await browser.close();
})();
