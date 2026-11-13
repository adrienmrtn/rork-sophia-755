// Render the panorama sets and cut them into App Store panels (1320 x 2868 each).
//   node render-pano.cjs [version] [locale]     ->  <locale>/iphone-6.9-<version>/NN.png
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");
const { PANOS } = require("./src/pano.js");

(async () => {
  const [onlyV, onlyLocale] = process.argv.slice(2);
  const browser = await chromium.launch();
  for (const [name, V] of Object.entries(PANOS)) {
    if (onlyV && onlyV !== name) continue;
    for (const locale of Object.keys(V.copy)) {
      if (onlyLocale && onlyLocale !== locale) continue;
      const n = V.panels.length;
      const page = await browser.newPage({ viewport: { width: 440 * n, height: 956 }, deviceScaleFactor: 3 });
      page.on("requestfailed", (r) => console.error("failed:", r.url()));
      await page.goto(pathToFileURL(path.join(__dirname, "src/pano.html")).href + `?v=${name}&locale=${locale}`, { waitUntil: "load" });
      for (const f of page.frames()) { await f.waitForLoadState("load"); await f.evaluate(() => document.fonts.ready); }
      await page.evaluate(() => window.fitted);
      await page.waitForTimeout(500);
      const dir = path.join(__dirname, locale, "iphone-6.9" + V.dir);
      fs.mkdirSync(dir, { recursive: true });
      for (let i = 0; i < n; i++) {
        await page.screenshot({ path: path.join(dir, String(i + 1).padStart(2, "0") + ".png"), clip: { x: 440 * i, y: 0, width: 440, height: 956 } });
      }
      console.log(path.relative(__dirname, dir), n, "panels");
      await page.close();
    }
  }
  await browser.close();
})();
