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

The subscription description is the exception. Every reference repeats 45
characters, inherited from the old in-app purchase field, and the account
disproves it: five of the six descriptions live on `Sophia_monthly` are longer,
up to "Desbloqueia todas as funcionalidades premium da Sophia" at 54, published
and serving. Enforcing 45 threw away five translations Apple accepts, so that
field is now advisory — `check` notes a long one, nothing is dropped, and the
server rules.

## Regional variants

`en-GB`, `en-AU`, `en-CA`, `es-MX` and `pt-BR` take a **copy** of their base
locale rather than a translation of it. The account already works this way: all
four English rows on `Sophia_monthly` carry the identical sentence. Translating
en-US into en-GB is a round trip that can only introduce a difference, and
handling only en-US would strand those rows on the previous release's copy.

`fr-CA` is deliberately absent. The account does not use it, and inventing a
Canadian French page nobody asked for is not this tool's business — add it to
`VARIANTS` if that changes.

## The four steps

```bash
python3 scripts/appstore_metadata.py check              # no network, no account
python3 scripts/appstore_metadata.py pull               # what the store holds now
python3 scripts/appstore_metadata.py build --from en-US # fill what is missing
python3 scripts/appstore_metadata.py push --dry-run
python3 scripts/appstore_metadata.py push
```

`build` never overwrites a field that already has text unless you pass `--redo`.
So `pull` first when you are adding languages to copy you want to keep, and skip
it when you are deliberately replacing the copy — it writes the store's text over
what is here.

**Subscriptions only exist after a `pull`.** Their product ids and group
reference names live on the account, not in this repo, so `subscriptions/` and
`subscription_groups/` stay empty until `pull` creates them. Then `build`
translates them and `push` writes them back, same as everything else.

## Deleting subscription text that was never submitted

The four steps only ever add and overwrite. `prune` is the one that removes,
and it removes from App Store Connect, never from this folder:

```bash
python3 scripts/appstore_metadata.py prune --dry-run
python3 scripts/appstore_metadata.py prune
```

Every subscription and group localization carries one of four states —
**Prepare for Submission**, Waiting for Review, Approved, Rejected. The first
means the text was typed and never sent to review; the other three mean it has
left your hands. `prune` deletes the first and touches none of the others, so on
a product that is already selling it removes the unsubmitted edits and leaves
what customers see exactly as it is.

Two guards, because this cannot be undone:

**A product keeps one localization.** On something created and never submitted,
every row is Prepare for Submission, and deleting them all leaves it reading as
Missing Metadata and no longer submittable — Apple refuses the last delete in any
case. So where no row has been reviewed, one survives: the app's primary language
if it is there, else `en-US`, else the first by locale. The run says which.

**A row whose state the account did not report is left alone.** Guessing would be
guessing about something irreversible.

`--locale de-DE` narrows what is deleted, and cannot narrow the protection: the
row to keep is chosen before the filter is applied.

**This folder is not touched, so `push` undoes it.** `subscriptions/` and
`subscription_groups/` still hold all 28 locales after a prune, and the next
`push` writes every deleted row straight back. Empty those files too if the text
is meant to stay gone.

## Or from the Actions tab, with no terminal

`.github/workflows/appstore-metadata.yml` runs all of this from a button.
Actions → **App Store metadata** → **Run workflow**, pick what to do. It defaults
to `dry-run`, so a careless click reports and changes nothing. `pull` and `build`
commit what they changed back to the branch you ran them on. `prune` is there as
`prune-dry-run` and `prune`, and has to be chosen deliberately.

This needs three repository secrets — Settings → Secrets and variables → Actions:
`ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY` holding the whole contents of
the `.p8`, `-----BEGIN PRIVATE KEY-----` line included. `check` needs none of
them.

`build` is the one step that may fail here rather than on a laptop: the
translation engine answers 429 to some data-centre ranges. Build locally and push
from Actions if it does.

## Or from a terminal

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
