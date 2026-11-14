// Render the store assets of every locale (or the ones named): iPhone 6.9", iPad 13", header.
//   node render-store.cjs [locale ...]
//   -> <locale>/iphone-6.9-store/NN.png, <locale>/ipad-13-store/NN.png, <locale>/header-store.png
// These folders are not committed: the "App Store screenshots" workflow renders them itself.
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");
const { PANOS, STORE_LOCALES, STORE_SOURCES } = require("./src/pano.js");

const url = (file, query) => pathToFileURL(path.join(__dirname, "src", file)).href + "?" + query;
async function settle(page) {
  for (const f of page.frames()) { await f.waitForLoadState("load"); await f.evaluate(() => document.fonts.ready); }
  await page.evaluate(() => window.fitted);
  await page.waitForTimeout(500);
}
async function panels(browser, file, v, w, h, scale, n, dir) {
  const page = await browser.newPage({ viewport: { width: w * n, height: h }, deviceScaleFactor: scale });
  page.on("requestfailed", (r) => { console.error("failed:", r.url()); process.exitCode = 1; });
  page.on("pageerror", (e) => { console.error("page error:", e.message); process.exitCode = 1; });
  await page.goto(url(file, "v=" + v), { waitUntil: "load" });
  await settle(page);
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  for (let i = 0; i < n; i++) {
    await page.screenshot({ path: path.join(dir, String(i + 1).padStart(2, "0") + ".png"), clip: { x: w * i, y: 0, width: w, height: h } });
  }
  await page.close();
}
(async () => {
  const locales = process.argv.slice(2).length ? process.argv.slice(2) : STORE_LOCALES;
  const browser = await chromium.launch();
  for (const locale of locales) {
    const v = "store-" + locale, V = PANOS[v];
    if (!V) { console.error("no store set for", locale); process.exitCode = 1; continue; }
    const root = path.join(__dirname, locale);
    await panels(browser, "pano.html", v, 440, 956, 3, V.panels.length, path.join(root, "iphone-6.9-store"));
    const nPad = V.panels.filter((p) => p.text !== "blocker").length;
    await panels(browser, "pano-ipad.html", v, 516, 688, 4, nPad, path.join(root, "ipad-13-store"));
    const page = await browser.newPage({ viewport: { width: 1920, height: 823 }, deviceScaleFactor: 2 });
    page.on("pageerror", (e) => { console.error("page error:", e.message); process.exitCode = 1; });
    await page.goto(url("header.html", "v=cards-cream&lang=" + STORE_SOURCES[locale].lang), { waitUntil: "load" });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(300);
    await page.screenshot({ path: path.join(root, "header-store.png") });
    await page.close();
    console.log(locale, V.panels.length, "iPhone,", nPad, "iPad, header");
  }
  await browser.close();
})();
