// Render the App Store screenshots.
//   node render.cjs                 every locale in COPY, every shot
//   node render.cjs fr-FR           one locale
//   node render.cjs fr-FR 2         one shot (1-based) of each set
// Output: appstore/screenshots/<locale>/<device>[-editorial]/NN-<screen>.png, opaque RGB, exact store size.
const { chromium } = require("playwright");
const path = require("node:path");
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");
const { DEVICES, SETS } = require("./src/shots.js");

(async () => {
  const [onlyLocale, onlyShot] = process.argv.slice(2);
  const locales = onlyLocale ? [onlyLocale] : Object.keys(COPY);
  const browser = await chromium.launch();
  for (const [deviceName, device] of Object.entries(DEVICES)) {
    const context = await browser.newContext({
      viewport: { width: device.width, height: device.height },
      deviceScaleFactor: device.scale,
    });
    const page = await context.newPage();
    page.on("console", (m) => { if (m.type() === "error") console.error("console:", m.text()); });
    page.on("requestfailed", (r) => console.error("failed:", r.url()));
    for (const set of Object.values(SETS)) for (const locale of (onlyLocale ? [onlyLocale] : Object.keys(set.copy))) {
      const SHOTS = set.shots;
      const dir = path.join(__dirname, locale, deviceName + set.dir);
      fs.mkdirSync(dir, { recursive: true });
      for (let i = 0; i < SHOTS.length; i++) {
        if (onlyShot && Number(onlyShot) !== i + 1) continue;
        const url = pathToFileURL(path.join(__dirname, "src", set.frame)).href +
          `?locale=${locale}&device=${deviceName}&i=${i}`;
        await page.goto(url, { waitUntil: "load" });
        const frame = page.frames().find((f) => f !== page.mainFrame());
        await page.evaluate(() => document.fonts.ready);
        if (frame) {
          await frame.waitForLoadState("load");
          await frame.evaluate(() => document.fonts.ready);
        }
        await page.waitForTimeout(250);
        const file = path.join(dir, `${String(i + 1).padStart(2, "0")}-${SHOTS[i].screen}.png`);
        await page.screenshot({ path: file, omitBackground: false });
        console.log(path.relative(__dirname, file));
      }
    }
    await context.close();
  }
  await browser.close();
})();
