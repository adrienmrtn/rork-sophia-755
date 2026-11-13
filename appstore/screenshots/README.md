# App Store screenshots

`fr-FR/iphone-6.9/*.png` are the seven iPhone screenshots, 1320 x 2868 (6.9"), opaque RGB.
App Store Connect scales this size down for the smaller iPhones.

They are **not simulator captures**. Each app screen is rebuilt as a static HTML page from the
SwiftUI source (same font, colours, French strings, real course covers), then photographed with
Playwright inside a marketing frame. Check them against the running app before submitting, and
recapture a screen in the simulator if the two have drifted.

```
src/kit.css, src/kit.js     tokens from DesignSystem.swift, status bar, tab bar
src/screens/<name>.html     one app screen, 440 x 956 pt; UI strings in `S`, content in `C`
src/frame.html              the marketing frame: headline + phone
src/shots.js                order, background theme and headline of each shot, per locale
render.cjs                  node render.cjs [locale] [shot number]  ->  <locale>/iphone-6.9/
shoot.cjs                   node shoot.cjs <screen> [out.png] [scale]  ->  one bare screen
BRIEF.md                    the rules followed to rebuild a screen (use it to add one)
```

To change a headline or the order, edit `src/shots.js` and run `node render.cjs`.
To add a language, add its entry to `COPY` and translate `S` / `C` in each screen.

Known liberties: read and like counters, friends' handles and XP are sample data; on the
anti-scroll shot the profile behind the sheet is scrolled a little past its real end and the QR
buttons are hidden, so that the status bar does not sit across a button. iPad screenshots
(13", 2064 x 2752) are not produced here.
