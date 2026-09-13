# App Store product page, in every language

`scripts/appstore_metadata.py` reads and writes this folder, and pushes it to
App Store Connect. Nothing here is compiled into the app — it is store metadata
only.

```
metadata/<locale>/description.txt        the product page body      (4000)
                  promotional_text.txt   the line above it           (170)
                  name.txt               the app's name               (30)
                  subtitle.txt           under the name               (30)
                  keywords.txt           comma separated             (100)
                  whats_new.txt          release notes              (4000)
                  marketing_url.txt      copied, never translated
                  support_url.txt
                  privacy_policy_url.txt
subscriptions/<product_id>.json          {"<locale>": {name (30), description (45)}}
subscription_groups/<reference>.json     {"<locale>": {name, custom_app_name}}
```

Those numbers are hard limits. Apple truncates nothing: one character over and
the whole request is rejected, so `check` refuses before anything is sent.

## The four steps

```bash
python3 scripts/appstore_metadata.py check              # no network, no account
python3 scripts/appstore_metadata.py pull               # what the store holds now
python3 scripts/appstore_metadata.py build --from en-US # fill what is missing
python3 scripts/appstore_metadata.py push --dry-run
python3 scripts/appstore_metadata.py push
```

`pull` first, always. `build` never overwrites a field that already has text
unless you pass `--redo`, so pulling first is what protects copy you wrote by
hand from being replaced by a machine translation of itself.

Credentials come from the environment and never from this repository:

```bash
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export ASC_PRIVATE_KEY=~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8
```

The `.p8` signs for the whole account. It belongs outside the repo, like the
other keys `AppConfig.swift` warns about. `check` needs none of this.

## Three languages the App Store does not have

The app speaks 26 languages. Apple offers 50 locales for store metadata and
**Bulgarian, Estonian and Serbian are not among them**. Those readers get a
product page in the primary language and an app in theirs, which works because
the app picks its language itself rather than following the device locale.

23 locales are pushable. There is nothing to do about the other three.

## Keywords are written by hand, not translated

`keywords.txt` is the one field a translation engine actively damages, so these
23 lists are composed per market rather than rendered from English. `build`
leaves a field that already has text alone, so they survive a rebuild.

Four rules shaped them, and `check` enforces the first three:

**No spaces.** The field is 100 characters and Apple counts every one. A space
after a comma is a keyword's worth of budget spent on nothing.

**Single words, never phrases.** Apple recombines keywords into phrases by
itself, so `culture,générale` already matches "culture générale" — spelling the
phrase out buys a match you had for free, and both words stay free to combine
with everything else in the list.

**No duplicates, no stray commas.** Both silently cost characters.

**Never repeat a word from the app's name or subtitle.** Apple indexes those
already. This is the one rule `check` cannot enforce, because the name lives on
the account and not in this folder — run `pull` and compare. It is why the
English list carries neither *general* nor *knowledge*.

Beyond the rules, each list ends on the local high-intent term for the exam
people are cramming for: *bac*, *Abitur*, *matura*, *maturita*, *érettségi*,
*bacalaureat*, *πανελλήνιες*. Those convert; a translated "examination" does
not. The lists average 82 of the 100 characters — the remaining room is there
deliberately, for terms you find in App Store Connect's own search data once
there is some.

## What is deliberately not here

**Screenshots.** A locale with no screenshots of its own shows the primary
locale's, so 23 languages times six device sizes is work Apple makes
unnecessary. Upload localized ones only where they would earn their keep.

**A hardcoded list of Apple's locale codes.** Apple publishes the table on a
page that renders in JavaScript, so `ASC_LOCALE` in the script is a proposal,
not a fact. `pull` prints the real code of every locale already configured on
the account, and `push` reports one line per locale and keeps going — a wrong
code costs that locale, not the run. Fix any Apple rejects and re-run; what
already succeeded is not redone.

## Two things the translation engine gets wrong

Both are guarded, and both are worth knowing if you add a field.

**It translates the app's name.** Left alone the engine returned *Sofia* in
Italian, *Σοφία* in Greek and *صوفي* in Arabic — three apps, none of them this
one — and inside the body text it was worse: the Russian description came back
carrying `Sophia` once, `София` five times and seven declined forms besides.
`name.txt` is copied, never translated, and every `Sophia` in prose is
sentinel-protected. `--translate-name` exists for a market where a
transliterated name is a deliberate branding decision.

**It rewrites URLs, and it eats sentinels that contain a digit.** `ZZKEEP0ZZ`
reads as the obvious protection and loses: Greek swallows the `ZZKEEP` and
leaves `1ZZ` glued to the previous word, Hungarian eats the trailing `ZZ`.
Measured on one paragraph across seven languages, the numbered sentinel came
back whole in three and a letter-only one in all seven. Hence `ZZAZZ`. A field
that loses a sentinel is reported and left empty rather than published with a
broken link.

Paragraphs are translated one at a time and rejoined on their own separators —
handed a whole description, the engine returns a single block of text.
