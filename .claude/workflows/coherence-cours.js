export const meta = {
  name: 'coherence-par-cours',
  description: 'Cohérence des noms et termes entre corps de cours, quiz et glossaire, huit cours par agent',
  phases: [{ title: 'Cohérence', detail: 'un agent par groupe de huit cours' }],
}
const R = args.repo || '/home/user/rork-sophia-755' // checkout of this repository
const P = args.work // working folder: packs/<lang>/, term/<lang>.md, out/<lang>/ … (see docs/processus-traduction.md)
const NAMES = { en: 'English (US)', es: 'Spanish (Spain)', de: 'German', pt: 'Brazilian Portuguese', 'pt-PT': 'European Portuguese', it: 'Italian', tr: 'Turkish', pl: 'Polish', ro: 'Romanian', nl: 'Dutch', el: 'Greek', sv: 'Swedish', hu: 'Hungarian', bg: 'Bulgarian', cs: 'Czech', da: 'Danish', nb: 'Norwegian Bokmål', ru: 'Russian', hr: 'Croatian', sl: 'Slovenian', sk: 'Slovak', sr: 'Serbian (Latin script, ekavian)', ar: 'Arabic (Modern Standard Arabic)', he: 'Hebrew', fi: 'Finnish', et: 'Estonian' }
const PER = 8

function prompt(lang, g, courses) {
  const tag = String(g).padStart(3, '0')
  const dir = `${P}/cohe/${lang}`
  return `You are a senior native ${NAMES[lang]} editor doing a CONSISTENCY pass on the ${NAMES[lang]} edition of Sophia (micro-courses with a quiz and a glossary each). Each course body, its quiz and its glossary were post-edited by different editors, so the same name can be spelled differently from one to the other.

Read first: ${R}/content/TRANSLATION_GUIDE_${lang.toUpperCase().replace('-', '_')}.md (section 5 on proper names, section 4 on glossary terms) and ${P}/term/${lang}.md.
Your courses: ${courses ? courses.join(' ') : `cd ${R} && ls content/courses/${lang} | sort | sed -n '${g * PER + 1},${g * PER + PER}p' (strip ".json" to get the course ids)`}.
Dump them: python3 scripts/postedit_i18n.py dump --lang ${lang} <course ids...> (one or two at a time if long). Each item is "### <id>" then its current text; sections say which output file the item belongs to.

For each course, list every proper name (people, places, gods, characters, peoples, dynasties), title of a work, and technical term that occurs in more than one place: body, quiz questions/options/explanations, glossary definitions, and the glossary terms themselves (the keys after "|", which appear as [[term]] in the body). Wherever the same thing is written differently (spelling, transliteration, with or without article or prefix, a different word for the same concept, a quiz option that does not match the name used in the lesson), choose ONE form: the established ${NAMES[lang]} form (guide §5, terminology sheet), and if a glossary term exists for it, normally that term's form. Then make every occurrence use it. Also fix any plain error you meet while doing this (wrong gender agreement on a name, a name that is clearly mistranslated). Do not restyle anything else.

Constraints: [[ ]] spans must stay exactly a glossary key of that course, never inflected; to change how a glossary TERM is written, rename it in the glossary file with "terme" (its [[links]] in the lesson follow automatically, so do not edit the [[...]] text in the body yourself). Keep **bold** balanced, placeholders identical, no new numbers. A quiz's correct option must stay correct and distinct from the distractors.

Write only the items you change, full new text, to these files (create only the ones you need), JSON {"edits":[{"id":"<exact id>","texte":"<full text>"}]} (glossary items: "texte" = definition only, optional "terme"):
  ${dir}/cours_coh${tag}.json, ${dir}/quiz_coh${tag}.json, ${dir}/glossaire_coh${tag}.json
Then run for each file you wrote: python3 scripts/postedit_i18n.py check --lang ${lang} --file <file>  and fix every "REJET" line until none remain.
Return one line: number of edits per file, and the names you harmonised (short).`
}

// args.groups: [{lang, g}] = the g-th block of eight courses in alphabetical order (a whole language),
// or [{lang, g, courses: [ids]}] = these courses only (new content); g then only numbers the output files.
const groups = args.groups
const res = await parallel(groups.map(({ lang, g, courses }) => () =>
  agent(prompt(lang, g, courses), { label: `${lang}:coh${g}`, phase: 'Cohérence' }).then(r => `${lang} ${g}: ${(r || '').trim().slice(0, 160)}`)))
return res.filter(Boolean)
