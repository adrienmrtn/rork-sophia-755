# Brief: recreate one Sophia iOS screen as a static HTML page

Sophia is a native SwiftUI iOS app (general-knowledge micro-courses). We are producing App Store
screenshots on a Linux box with no simulator, so each screen is rebuilt as a static HTML page that
must look like the real app screen, then photographed with Playwright. You build ONE screen.

## Where things are (repo root: /home/user/rork-sophia-755)
- SwiftUI source: `ios/Sophia/Views/**`, design tokens `ios/Sophia/Utilities/DesignSystem.swift`,
  `ElevateKit.swift`, `Theme.swift`.
- UI strings: Swift dictionaries in `ios/Sophia/Utilities/AppLocalizable.swift` and
  `ios/Sophia/Utilities/Localizable/*.swift` (French is the source language; find the French table
  for each key the screen uses).
- Course content, catalogue, authors, glossary: `content/` (French: look for `fr`), plus
  `ios/Sophia/Resources/StarterPack`. Cover and in-course images: `ios/Sophia/CourseImages/*.jpg`.
  Other artwork: `ios/Sophia/Assets.xcassets/*.imageset`, `ios/Sophia/Resources/*`.
- The kit you must use: `appstore/screenshots/src/kit.css` (tokens, font, status bar, tab bar) and
  `appstore/screenshots/src/kit.js` (`Kit.chrome({ status, tab, indicator })`). Read both first.
  `appstore/screenshots/src/screens/_kit-test.html` shows the wiring.

## What to produce
One file: `appstore/screenshots/src/screens/<name>.html`, exactly 440 x 956 CSS px (iPhone 6.9",
1 CSS px = 1 pt). Link `../kit.css` and `../kit.js`; put screen-specific CSS in a `<style>` block
in the page. Reference images by relative path (from `screens/`, the repo root is `../../../../`).
Do not edit the kit or any other file; if the kit lacks something, do it locally in your page and
say so in your report.

## Fidelity rules
- Read the SwiftUI for the screen and rebuild its real layout: paddings, spacing, font sizes and
  weights (`DS.baseSize` table), colours (use the kit CSS variables), corner radii, borders, the
  1.5 pt hairline card style. Light mode. Safe areas: 62 px top, 34 px bottom. Tab bar screens
  call `Kit.chrome({ tab: "<home|explore|duels|profile>" })`, which adds the 49 pt bar.
- Do not invent UI copy: every interface string comes from the app's French localisation.
  Do not invent features, counters with marketing claims, ratings or testimonials.
- Use real content: real course titles, real cover images that belong to those courses, real
  author names from the catalogue, real quiz questions. Check every image you pick actually
  matches the text beside it (open the image with Read to look at it).
- SF Symbols do not exist here: draw each as a clean inline SVG that looks like the symbol the
  code names. There is no colour emoji font: if the app shows an emoji, draw a small SVG instead.
- Show a flattering, realistic state: a Premium user with some history (no lock icons, no paywall
  banners, no debug rows, no empty states), content fills the screen, nothing cut mid-word at the
  bottom unless the real screen scrolls there (then let it run under the tab bar naturally).
- Text is in French, with correct typography (non-breaking space before ? ! : ;, « », curly ’).
- Keep all user-visible UI strings in one `const S = { "<loc key>": "…" }` object in a `<script>`
  at the end of the page and inject them into elements carrying `data-s="<loc key>"`, so the page
  can be translated later. Course content (titles, body text, names) goes in a second object `C`
  keyed by short names, injected via `data-c`. Inline markup inside a string (e.g. `<b>`) is fine.

## Verify before you report
Run `cd /home/user/rork-sophia-755/appstore/screenshots && node shoot.cjs <name> <SCRATCH>/<name>.png 2`
(SCRATCH = /tmp/claude-0/-home-user-rork-sophia-755/fd6ad3aa-dc2c-57be-a5c1-6d4e23751ed0/scratchpad),
then Read the PNG and look at it critically. Iterate until: fonts load, no broken image, no clipped
or overlapping text, alignment is clean, icons look right, it would pass for the real app. Zoom on
details by shooting at scale 3 and cropping with Python PIL if needed.

Do not run git commands, do not commit, do not create other files in the repo (scratch files go
in SCRATCH).

## Report (short)
The state you chose and why, the Swift files you followed, anything approximated or that you could
not determine from the code, and any string for which you found no French localisation key.

## iPad variant (`?device=ipad`)

Each screen also renders as the app would on an iPad: 768 x 1024 pt, portrait. The kit handles
the switch: with `?device=ipad` it adds `class="ipad"` on `<html>`, sizes the body, draws the
iPad status bar (24 pt, time and date left), a wider home indicator, and turns the tab bar into
the floating capsule of titles that a SwiftUI `TabView` gets at the top on iPadOS 18 (the app's
deployment target is iOS 18; it occupies y = 32 to 72). `Kit.ipad` is true in that mode. Safe
areas: `--safe-top: 24px`, `--safe-bottom: 20px`, no bottom tab bar.

The app has no iPad-specific code (no size-class or idiom checks), so the iPad screen is what the
same SwiftUI gives at 768 pt wide: read the layout code again and apply it honestly — views with
`maxWidth: .infinity` stretch, fixed frames and `maxWidth` caps stay, squares capped at a size
stay that size and centre or lead as the code says, `GeometryReader` maths is redone for the new
size, grids keep their column count unless adaptive, `fullScreenCover` stays full screen, and a
`.sheet` is the centred iPadOS form sheet (about 704 pt wide at this size for a large detent, a
card with 12 to 16 pt corners over the dimmed screen; medium detents are ignored on iPad, where
the sheet is the full-height page sheet). Tab-bar screens start their content below the capsule.
More content is visible than on the phone: fill it with more real content, not blank space.

Write the iPad rules as CSS under `html.ipad` plus any `if (Kit.ipad)` content, in the same file.
The phone renders (French and English) must stay pixel-identical. Check with
`node shoot.cjs <name> <SCRATCH>/<name>-ipad.png 2 "lang=en&device=ipad"`, look at the PNG, and
iterate until it would pass for the app on an iPad. Report briefly what the iPad layout shows
and what you had to assume.

## All the app's languages (`?lang=<code>`)

A screen renders in French (default), English (`lang=en`) and in the 23 other languages the store
page has: ar cs da de el es fi he hr hu it ja nb nl pl pt pt-PT ro ru sk sl sv tr (the app's own
codes, the names of the folders under `content/courses/`). French and English stay inline in
the page; the others live in one data file per screen, `src/screens/l10n/<screen>.js`, which
sets `window.L10N = { de: { S: {...}, C: {...} }, ... }` with exactly the keys of the page's
English `S` and `C`. The page loads it with a plain `<script src="l10n/<screen>.js">` before its
own script and picks `{ fr, en }[LANG] || window.L10N[LANG]`.

Where the data comes from, never from your own translation when the app has it:
- `S` (interface strings): the app's localisation tables for that language, by key
  (`ios/Sophia/Utilities/AppLocalizable.swift`, `Utilities/Localizable/*.swift`, the
  `<lang>.lproj` folders, `content/locales/<lang>/`). A key missing in a language falls back as
  the app does (English).
- `C` (content): the same course, quiz question, duel question, league, badge names… in that
  language, from `content/courses/<lang>/`, `content/locales/<lang>/`, `content/glossary/`,
  `content/duels/i18n/<lang>.json`. Same course and same passage as the English page unless a
  language lacks it; then say so. Invented handles stay neutral.
Build the data file with a small script that reads those sources (keep it in
`appstore/screenshots/tools/l10n_<screen>.py` so the file can be rebuilt), then fix by hand what
the script cannot know. Apply each language's typography as the source data has it.

Layout must hold in every language: long words (de, fi, hu, ru, el), no clipped or overlapping
text, no orphaned half line under a fixed bar (tune per-language scroll offsets as the English
page does). Arabic and Hebrew are right-to-left: set `dir="rtl"` and mirror the layout as
SwiftUI does (leading/trailing swap, directional icons flip, numbers and progress direction as
iOS renders them). The kit's font stack falls back to Noto Sans for Greek, Cyrillic, Arabic,
Hebrew and Japanese, which Plus Jakarta Sans lacks (the app falls back to the system font).

Check every language in both sizes: shoot `lang=<code>` and `lang=<code>&device=ipad` for all 23,
assemble contact sheets with PIL, look at them, and fix what is wrong. French and English
renders, phone and iPad, must stay pixel-identical. Report: languages where content was missing
or replaced, anything you translated yourself, and any language whose layout you are not happy
with.
