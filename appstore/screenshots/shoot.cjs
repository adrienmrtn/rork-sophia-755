// Screenshot one screen recreation: node shoot.cjs <screen-name> [out.png] [scale] [query]
// e.g. node shoot.cjs home out.png 2 lang=en
const { chromium } = require("playwright");
const path = require("node:path");
const { pathToFileURL } = require("node:url");
(async () => {
  const [name, out, scale, query] = process.argv.slice(2);
  const browser = await chromium.launch();
  const ipad = /(^|&)device=ipad/.test(query || "");
  const page = await browser.newPage({ viewport: ipad ? { width: 768, height: 1024 } : { width: 440, height: 956 }, deviceScaleFactor: Number(scale || 2) });
  page.on("console", (m) => { if (m.type() === "error") console.error("console:", m.text()); });
  page.on("requestfailed", (r) => console.error("failed:", r.url()));
  await page.goto(pathToFileURL(path.join(__dirname, "src/screens", name + ".html")).href + (query ? "?" + query : ""));
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(150);
  await page.screenshot({ path: out || path.join(__dirname, "preview-" + name + ".png") });
  await browser.close();
})();
