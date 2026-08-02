# Step 7 — Apply legal / RevenueCat / App Store (hors app)

In-repo deliverables for `tr pl ro nl el sv hu bg cs`.  
**Do not rewrite French.** Dashboard steps require human / API credentials.

## Already wired in the app (this PR)

- [x] Terms + Privacy in `LegalDocumentContent.swift` for the 9 langs (no EN fallback)
- [x] JSON sources: `content/locales/<lang>/legal.json`
- [x] `AppLanguage.localeIdentifier` → `tr_TR`, `pl_PL`, `ro_RO`, `nl_NL`, `el_GR`, `sv_SE`, `hu_HU`, `bg_BG`, `cs_CZ`
- [x] ATT `InfoPlist.strings` translated in each `{lang}.lproj` (étape 2)
- [x] RC course-unlock titles extended in `scripts/configure_revenuecat_offering.py`

## App Store Connect (manual)

For each locale, paste drafts from `content/store/listing.<lang>.json`:

| Field | Source key |
|-------|------------|
| Name | `name` (kept **Sophia**) |
| Subtitle | `subtitle` |
| Promotional Text | `promotional_text` |
| Description | `description` |
| Keywords | `keywords` |
| What's New | `whats_new` |

Locales: `tr-TR`, `pl-PL`, `ro-RO`, `nl-NL`, `el-GR`, `sv-SE`, `hu-HU`, `bg-BG`, `cs-CZ`.

Optional: screenshots per locale (only if you localize the store listing visuals).

Update `privacy_policy_url` / `support_url` to production pages before submit.

## RevenueCat (manual or API)

1. Product display names / descriptions: `content/store/revenuecat_products.<lang>.json`
   - `Sophia_monthly`, `Sophia_yearly`
2. Paywall override titles for `debloquer_cours`: see `revenuecat_products.en.json` → `paywall_overrides.debloquer_cours.title` (includes the 9 new locales).
3. Optional apply via existing script (needs `REVENUECAT_SECRET_API_KEY`):

```bash
REVENUECAT_SECRET_API_KEY=sk_... python3 scripts/configure_revenuecat_offering.py \
  --offering debloquer_cours --reference quizz
```

(Native paywall body copy is already in `AppLocalizable` — this step is dashboard product / paywall title localization.)

## QA checklist

- [ ] App language picker → Terms / Privacy show that language (not English)
- [ ] French Terms / Privacy unchanged
- [ ] `PYTHONPATH=scripts python3 scripts/translate_legal_docs.py qa --lang all` → PASS
- [ ] ASC listing fields reviewed by a native speaker before release
- [ ] RC product titles visible for the 9 store locales
- [ ] Sandbox purchase still works (étape 8)


---

# Android / Google Play Console

Play drafts generated from ASC listings (Apple → Google wording):

| Field | Source key in `play_listing.<lang>.json` |
|-------|------------------------------------------|
| App name | `name` |
| Short description | `short_description` |
| Full description | `full_description` |
| What's new | `whats_new` |

Locales with drafts: `en tr pl ro nl el sv hu bg cs`.

Also paste RC product titles from `revenuecat_products.<lang>.json` (`Sophia_monthly`, `Sophia_yearly`).

In-app legal documents for Android live under `android/app/src/main/assets/legal/<lang>.json` (Play Billing wording).

## Play QA checklist

- [ ] Profile → Terms / Privacy show the selected language
- [ ] Paywall legal row: Restore · Terms · Privacy
- [ ] Login legal note tappable
- [ ] Restore purchases refreshes premium
- [ ] Play listing drafts reviewed by a native speaker before release
