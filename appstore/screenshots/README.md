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

`fr-FR/iphone-6.9-penche/`, `-couleurs/`, `-duo/` and `-vitrine/` are cut out of one wide canvas, so a
phone or a character can sit across two neighbouring screenshots. They must be uploaded in
order, with none removed, or the seams no longer match.

```
src/pano.html, src/pano.js   the wide canvas and the three layouts (panels, phones, people)
render-pano.cjs              node render-pano.cjs [penche|couleurs|duo|vitrine]
src/people/*.png             full-body characters in the style of the app's avatars
people.py                    how they were made (fal.ai, Recraft v3, then background removal)
```

`duo` has ten panels (the App Store maximum) and adds two lines of copy the other sets do not
have: « 30 ligues à gravir » and « Reprenez votre temps ».

`vitrine` opens with a brand-blue panel (characters, logo, speech bubble), continues with upright
phones in a thick blue frame under a centred title, and closes on a wall of real course covers.
Its last panel quotes three real five-star reviews from the French App Store (app id 6760919622,
public customer-reviews feed, read on 13 November 2026), word for word. Replace them only with
other real reviews; a translated set needs reviews from that country's store.

## English set (`en-US/iphone-6.9-showcase/`)

`node render-pano.cjs showcase`. Same look as `vitrine`, with the app screens in English
(`screens/<name>.html?lang=en`: every screen except `explore` carries a French and an English
`S` / `C`). Nine panels: opening on cream with the colour logo and a before / after pair, « Get
smarter every day » (For you feed, « Why does nobody smile in old photographs? »), « Learn in
10 minutes » (that course open), catalogue wall, reviews, quiz, duels, anti-scroll, « Written by
professors ».

The reviews are the only English-language ones the public feeds returned on 13 November 2026:
two five-star and one four-star, shown with its four stars. The professors panel lists real
authors and credentials from `content/authors.json`; the portraits are the site's illustrated
avatars, on purpose, not their faces.

Two colour variants of the English set render with `node render-pano.cjs showcase-bold` (a strong
colour on almost every panel) and `node render-pano.cjs showcase-trio` (cream, blue and pink in
rotation); the content is the same. Their panel colours are the two lists at the end of
`src/pano.js`.

## Product page header (`header/`)

`node render-header.cjs` renders four proposals at 3840 x 1646 (21:9) from `src/header.html`:
`header-cards.png` and `header-cards-cream.png` (the logo among tilted course cards with real
English course titles and covers, on blue or on cream),
`header-cream.png` (colour logo, the before / after pair) and `header-blue.png` (white logo,
illustrated objects). The logo and the main figures stay in the middle 3:2, which is roughly
what a phone shows; check the exact size and crop against Apple's current specifications and
the App Store Connect preview before uploading.

## iPad set (`en-US/ipad-13-showcase-bold/`)

`node render-ipad.cjs [variant]` renders the same nine panels at 2064 x 2752 (iPad 13") from
`src/pano-ipad.html`, with the app screens in their iPad variant (`?device=ipad`, 768 x 1024 pt,
see BRIEF.md). The app has no iPad-specific code, so these are the phone layouts as SwiftUI
would stretch them; the top tab capsule and the size of the anti-scroll sheet are assumptions.
Check them on a real iPad or simulator before submitting.

## French edition of the retained set

`node render-pano.cjs showcase-bold-fr` -> `fr-FR/iphone-6.9-showcase-bold/`,
`node render-ipad.cjs showcase-bold-fr` -> `fr-FR/ipad-13-showcase-bold/`, and
`header/header-cards-cream-fr.png`. The iPad sets have eight panels: the anti-scroll panel is
left out there.

## Every store locale (`render-store.cjs`)

`node render-store.cjs [locale ...]` renders, for each of the 29 locales of the store page, the
retained set for iPhone 6.9" and iPad 13" and the product page header:
`<locale>/iphone-6.9-store/`, `<locale>/ipad-13-store/`, `<locale>/header-store.png`. These are
git-ignored; the "App Store screenshots" workflow renders and uploads them (and attaches them
to the run).

- Headlines: French and English in `src/pano.js`, the others in `src/copy.js`.
- App screens: French and English inline in `src/screens/<name>.html`, the 23 other languages in
  `src/screens/l10n/<name>.js`, generated from the app's own strings and course content by
  `tools/l10n_<name>.py`.
- Header titles: `src/header-titles.js`, generated by `tools/header_titles.py`.
- Reviews panel: only where real reviews exist in the language (French, English); the other
  locales have eight iPhone and seven iPad panels.
- Needs the Noto Sans fonts (`fonts-noto-core`, `fonts-noto-cjk`) for Greek, Cyrillic, Arabic,
  Hebrew and Japanese, and Inter for the status bar.

## Google Play

`node render-store.cjs --android [locale ...]` renders the Play variant of the same set:
`<locale>/play-phone/` (1320 x 2346, 9:16) and `<locale>/play-tablet/` (2064 x 2752), eight
panels each. It differs from the App Store set in four ways: shorter phone panels, no anti-scroll
panel (the Android app does not block apps), characters only on the opening panel, and reviews
signed with the reviewer's name alone (they were written on the App Store, so they are not
labelled "Google Play"). The app screens inside are the iOS ones with an Android-style status
bar. `scripts/play_screenshots.py` and the "Google Play screenshots" workflow upload them.
