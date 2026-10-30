export const meta = {
  name: 'verification-native',
  description: 'Relecture native adverse d\'un échantillon post-édité par langue : fidélité, puis langue, plus contrôle des segments laissés tels quels',
  phases: [{ title: 'Fidélité' }, { title: 'Langue' }, { title: 'Oublis' }],
}
const R = args.repo || '/home/user/rork-sophia-755' // checkout of this repository
const P = args.work // working folder: packs/<lang>/, term/<lang>.md, out/<lang>/ … (see docs/processus-traduction.md)
const NAMES = { en: 'English (US)', es: 'Spanish (Spain)', de: 'German', pt: 'Brazilian Portuguese', 'pt-PT': 'European Portuguese', it: 'Italian', tr: 'Turkish', pl: 'Polish', ro: 'Romanian', nl: 'Dutch', el: 'Greek', sv: 'Swedish', hu: 'Hungarian', bg: 'Bulgarian', cs: 'Czech', da: 'Danish', nb: 'Norwegian Bokmål', ru: 'Russian', hr: 'Croatian', sl: 'Slovenian', sk: 'Slovak', sr: 'Serbian (Latin script, ekavian)', ar: 'Arabic (Modern Standard Arabic)', he: 'Hebrew', fi: 'Finnish', et: 'Estonian' }

const VERDICTS = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          surface: { type: 'string' },
          verdict: { type: 'string', enum: ['ok', 'fix'] },
          gravite: { type: 'string', enum: ['bloquant', 'majeur', 'mineur', 'aucune'] },
          raison: { type: 'string' },
          texte: { type: 'string' },
          terme: { type: 'string' },
        },
        required: ['id', 'surface', 'verdict', 'gravite'],
      },
    },
  },
  required: ['verdicts'],
}

const COMMON = lang => `Read first: ${R}/content/TRANSLATION_GUIDE_${lang.toUpperCase().replace('-', '_')}.md (the ${NAMES[lang]} guide) and ${P}/term/${lang}.md (imposed terminology).
Constraints any text you propose must keep: same meaning and facts as the French; no new numbers; placeholders ({name}, %@, %d…) identical; ⏎ line breaks as in the text; **bold** balanced; in course items, text inside [[ ]] must stay exactly one of the allowed terms listed in the item's "(COURS … termes de glossaire autorisés …)" line, never inflected, and no [[ ]] span may be dropped; glossary items: "texte" is the definition only, and if the glossary TERM itself (or a renamed term, "TERME RENOMMÉ EN") is wrong, give the corrected term in "terme"; store limits: name 30, subtitle 30, promotional_text 170, keywords 100 characters.
Return one verdict per item of the file, with its exact id and surface (the "### surface | id" header). verdict "ok" when the text is right as it stands; "fix" with "texte" = the full corrected text, "gravite" and a short "raison" in French. Be adversarial but honest: do not propose changes of taste.`

function fidelity(lang, half) {
  return `You are a senior ${NAMES[lang]}–French reviser. Native editors post-edited machine-translated ${NAMES[lang]} text of the Sophia app. Your job: catch what they got WRONG. File: ${P}/review/${lang}/changed_${half}.md — each item has FR (source), AVANT (before) and APRÈS (after post-editing), sometimes TERME RENOMMÉ EN (a renamed glossary term).
Lens: FIDELITY. For each item, compare APRÈS with FR: meaning changed, nuance lost, fact added or dropped, wrong referent, negation flipped, correct quiz answer altered, an AVANT error the editor kept, a renamed term that is not the established ${NAMES[lang]} name. If APRÈS is faithful, verdict ok.
${COMMON(lang)}`
}

function fluency(lang, half, prior) {
  return `You are a native ${NAMES[lang]} copy editor (not a translator) for a general-knowledge app aimed at curious teenagers and adults. File: ${P}/review/${lang}/changed_${half}.md — items have FR, AVANT, APRÈS. A fidelity reviser already corrected some items; for those, the CURRENT text is the one below, not APRÈS:
${prior || '(none)'}
Lens: LANGUAGE. Read the current ${NAMES[lang]} text as a native reader would: grammar (case, agreement, gender, aspect), word order, idiom, register (informal singular "you" in the app, per the guide for legal text), punctuation and typography per the guide, calques from French or English that no native would write. Check meaning only to make sure your fix keeps it.
${COMMON(lang)}`
}

function recall(lang) {
  return `You are a senior ${NAMES[lang]}–French reviser. File: ${P}/review/${lang}/unchanged.md — items the post-editors LEFT AS IS (FR source, AVANT = current text). Your job: find what they missed. For each item, would a careful native editor publish AVANT as is, given FR? Flag meaning errors, trap words, unnatural calques, grammar errors, register errors, terminology contradicting the sheet.
${COMMON(lang)}`
}

const langs = args.langs
const out = await parallel(langs.map(lang => async () => {
  const halves = await pipeline(['a', 'b'],
    half => agent(fidelity(lang, half), { label: `${lang}:fidélité:${half}`, phase: 'Fidélité', schema: VERDICTS }),
    (fid, half) => {
      const fixes = ((fid && fid.verdicts) || []).filter(v => v.verdict === 'fix' && v.texte)
      const prior = fixes.map(v => `- ${v.id}: ${v.texte}`).join('\n')
      return agent(fluency(lang, half, prior), { label: `${lang}:langue:${half}`, phase: 'Langue', schema: VERDICTS })
        .then(flu => ({ half, fidelite: (fid && fid.verdicts) || [], langue: (flu && flu.verdicts) || [] }))
    })
  const miss = await agent(recall(lang), { label: `${lang}:oublis`, phase: 'Oublis', schema: VERDICTS })
  return { lang, halves: halves.filter(Boolean), oublis: (miss && miss.verdicts) || [] }
}))
return out.filter(Boolean)
