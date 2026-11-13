# App Store screenshots

Two iPhone sets, 1320 x 2868 (6.9"), opaque RGB: `fr-FR/iphone-6.9/` (seven shots, centred
headline, framed phone, coloured backgrounds) and `fr-FR/iphone-6.9-editorial/` (eight shots: a
full-colour opening panel, then cream panels with title and subtitle on the left and a flat
outlined phone). Upload one set, not both.
App Store Connect scales this size down for the smaller iPhones.

They are **not simulator captures**. Each app screen is rebuilt as a static HTML page from the
SwiftUI source (same font, colours, French strings, real course covers), then photographed with
Playwright inside a marketing frame. Check them against the running app before submitting, and
recapture a screen in the simulator if the two have drifted.

```
src/kit.css, src/kit.js     tokens from DesignSystem.swift, status bar, tab bar
src/screens/<name>.html     one app screen, 440 x 956 pt; UI strings in `S`, content in `C`
src/frame.html              frame of the first set; src/frame-b.html of the editorial set
src/shots.js                order and copy of each shot, per set (`SETS`) and locale
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

## Panorama sets (tilted phones, characters across the seams)

`fr-FR/iphone-6.9-penche/`, `-couleurs/` and `-duo/` are cut out of one wide canvas, so a
phone or a character can sit across two neighbouring screenshots. They must be uploaded in
order, with none removed, or the seams no longer match.

```
src/pano.html, src/pano.js   the wide canvas and the three layouts (panels, phones, people)
render-pano.cjs              node render-pano.cjs [penche|couleurs|duo]
src/people/*.png             full-body characters in the style of the app's avatars
people.py                    how they were made (fal.ai, Recraft v3, then background removal)
```

`duo` has ten panels (the App Store maximum) and adds two lines of copy the other sets do not
have: « 30 ligues à gravir » and « Reprenez votre temps ».
