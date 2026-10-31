export const meta = {
  name: 'post-edition-native',
  description: 'Post-édition native lot par lot (interface, catalogue, fiche, glossaire, quiz, cours) avec guide et terminologie',
  phases: [{ title: 'Post-édition', detail: 'un agent par lot, sortie JSON contrôlée par le script' }],
}
const R = args.repo || '/home/user/rork-sophia-755' // checkout of this repository
const P = args.work // working folder: packs/<lang>/, term/<lang>.md, out/<lang>/ … (see docs/processus-traduction.md)
const NAMES = { en: 'English (US)', es: 'Spanish (Spain)', de: 'German', pt: 'Brazilian Portuguese', 'pt-PT': 'European Portuguese', it: 'Italian', tr: 'Turkish', pl: 'Polish', ro: 'Romanian', nl: 'Dutch', el: 'Greek', sv: 'Swedish', hu: 'Hungarian', bg: 'Bulgarian', cs: 'Czech', da: 'Danish', nb: 'Norwegian Bokmål', ru: 'Russian', hr: 'Croatian', sl: 'Slovenian', sk: 'Slovak', sr: 'Serbian (Latin script, ekavian)', ar: 'Arabic (Modern Standard Arabic)', he: 'Hebrew', fi: 'Finnish', et: 'Estonian', lt: 'Lithuanian', lv: 'Latvian', ja: 'Japanese' }

const SURFACE = {
  ui: `App interface strings. Keep every placeholder exactly ({name}, %@, %d, %1$@, %s, %lld…), keep the same number of ⏎ (line breaks) as the current text, keep buttons and labels about as short as now. Product voice: informal singular "you", warm, short.`,
  catalogue: `Collection titles/descriptions shown in the library, and "rubrique:" items = library section labels (short noun phrases, one to four words; the id contains the current label, return the new label as "texte").`,
  store: `App Store product page. Hard limits in characters: name 30, subtitle 30, promotional_text 170, keywords 100 (comma-separated, no space after commas, no words already in name), description 4000. Keep the line structure of the description. Must read like native marketing copy.`,
  glossaire: `Glossary entries "[term] definition". Return "texte" = the definition ONLY, without the [term] prefix. The French definitions of the course are given in the "(Définitions françaises du cours…)" line: match the entry by meaning. If the TERM itself is wrong (mistranslation, trap word such as an organ for "spleen", literal calque, not the established ${'$'}{LANG} name of a work, person, event or concept), also return "terme": the corrected term, in base/nominative form, same capitalisation style. Rename only when the term is clearly wrong: lessons link to it and follow automatically.`,
  legal: `Terms of use and privacy policy. ids starting with ios: are the iPhone text (Apple, App Store), ids starting with android: the Android text (Google, Google Play): keep each platform's names. The French addresses the user formally (vous): use the register a ${'$'}{LANG} legal text of a consumer app normally uses (formal or informal, per the guide; consistent across the whole document). Precise, natural legal prose, no calques (e.g. a rendering of 'available on iOS' as 'available at the address iOS' is wrong). Keep ⏎ line breaks and section numbering.`,
  quiz: `Quiz items: question, options (the French marked "(bonne réponse)" is the correct one; never add that mark), explanation, statement, items. Options must stay mutually distinct and parallel in form; the correct option must stay correct and must not become longer or more obvious than the distractors; question, options and explanation must agree with each other (same names, same terms).`,
  cours: `Lesson segments of micro-courses. A header item "COURS <id> — termes de glossaire autorisés : [[…]]" lists the only glossary spans allowed in that course: text inside [[ ]] must be one of them character for character (it is a key). Never inflect a term or glue a suffix after ]]: restructure the sentence around the base form instead. Keep at least as many [[ ]] spans as the current text and as the French; put each one inside the sentence where the French has it, never parked at the end. Keep **bold** markers balanced and around the equivalent words. Titles stay short. The header item itself is not editable.`,
}

function prompt(lang, lot) {
  const surface = lot.startsWith('ui') ? 'ui' : lot.split('_')[0]
  const guide = `${R}/content/TRANSLATION_GUIDE_${lang.toUpperCase().replace('-', '_')}.md`
  const out = `${P}/out/${lang}/${lot}.json`
  return `You are a senior native ${NAMES[lang]} editor, fluent in French, post-editing the ${NAMES[lang]} edition of Sophia (general-knowledge micro-courses for curious teenagers and adults). The current ${NAMES[lang]} text is raw machine translation and native speakers complain it is unnatural. French is the source of truth for meaning. For a language being added (Lithuanian, Latvian, Japanese), ACTUEL is still the French text: translate every item in full from the French, so every item gets an edit; glossary items then always return "terme" too (the term in the language).

Read fully first:
1. ${guide} — the ${NAMES[lang]} translation guide. Follow it.
2. ${P}/term/${lang}.md — imposed terminology (product terms, trap words, titles of works).
3. ${P}/packs/${lang}/${lot}.md — your lot. It may be long: read it all, in chunks (offset/limit) if needed. Each item: "### <id>", optional context line in parentheses, "FR:" source, "ACTUEL:" current text, and "! " hints (audit findings with a proposed fix, terminology occurrences). Hints are leads, not orders: check each against the French.

Surface rules: ${SURFACE[surface].split('${LANG}').join(NAMES[lang])}

For every item, decide whether a careful native editor would publish ACTUEL as is. Rewrite it when it has any of: a meaning error against the French (wrong sense, trap word, false friend, misread negation or subject, lost or added fact), unnatural or calqued phrasing, wrong grammar (case, agreement, gender, aspect, word order), wrong register (the user is addressed informally in the singular; French impersonal "on" is not "we"), terminology that contradicts the sheet, typography or number/date formats that contradict the guide, untranslated words that have an established ${NAMES[lang]} form. Leave good items alone: do not rewrite for taste.
Always: same meaning and facts as the French, no new numbers or dates, placeholders identical, **bold** balanced.

Write the result with the Write tool to ${out} as JSON: {"edits":[{"id":"<exact id from the pack>","texte":"<full new text>"}]} (glossary items may add "terme"). Only changed items. Full replacement text, not a diff. Valid JSON (escape " and \\). Use ⏎ for line breaks in UI items, as the pack does. If nothing needs changing, write {"edits":[]}.
Then run: cd ${R} && python3 scripts/postedit_i18n.py check --lang ${lang} --file ${out}
It prints one "REJET <id> : <reason>" line per edit the checker would refuse (placeholders, line breaks, unbalanced bold, unknown or lost glossary term, new number, length out of range, unknown id). Fix those edits (or drop them) and rewrite the file until no REJET remains.
Return one line: "<lot> <number of edits>".`
}

// args.work: working folder (packs/<lang>/<lot>.md in, out/<lang>/<lot>.json out, term/<lang>.md).
// args.lots: ["<lang>/<lot>"] or [{lang, lot}] — or args.langs + args.counts {lang: {ui, catalogue, store, legal, glossaire, quiz, cours}}, args.shard, args.of, args.skip ["lang/lot"]
function plan() {
  const order = ['ui', 'catalogue', 'store', 'legal', 'glossaire', 'quiz', 'cours']
  const skip = new Set(args.skip || [])
  const all = []
  for (const surf of order) for (const lang of args.langs) {
    const n = (args.counts[lang] || {})[surf] || 0
    for (let i = 0; i < n; i++) {
      const lot = surf === 'ui' ? `ui${i + 1}` : ['catalogue', 'store', 'legal'].includes(surf) ? surf : `${surf}_${String(i).padStart(3, '0')}`
      if (!skip.has(`${lang}/${lot}`)) all.push({ lang, lot })
    }
  }
  return all.filter((_, i) => i % (args.of || 1) === (args.shard || 0))
}
let listed = null
if (args.argsFile) {
  const r = await agent(`Run: cat ${args.argsFile}\nIt is JSON {"lots": [...strings...]}. Return that "lots" array exactly, every string, same order, nothing added.`,
    { label: 'liste des lots', phase: 'Post-édition', effort: 'low', schema: { type: 'object', properties: { lots: { type: 'array', items: { type: 'string' } } }, required: ['lots'] } })
  listed = ((r && r.lots) || []).filter(x => /^[a-z]{2}(-PT)?\/(ui[1-4]|catalogue|store|legal|(glossaire|quiz|cours)_\d{3})$/.test(x))
}
const lots = (listed || args.lots || plan()).map(x => typeof x === 'string' ? { lang: x.split('/')[0], lot: x.split('/')[1] } : x)
log(`${lots.length} lots`)
const res = await parallel(lots.map(({ lang, lot }) => () =>
  agent(prompt(lang, lot), { label: `${lang}:${lot}`, phase: 'Post-édition' }).then(r => `${lang} ${(r || '').trim().slice(0, 80)}`)))
return res.filter(Boolean)
