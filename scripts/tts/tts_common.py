"""Shared pipeline that turns course JSON into text ready for ElevenLabs.

A language module (lang_fr, lang_en) supplies everything that depends on the
language: number reading, units, pronunciation, and the few spoken strings the
narration adds. This module does the rest — which blocks are read, markup, the
pauses, chapter and quote framing, the per-chapter split — and the checks that
fail the build on anything a voice would read aloud by mistake.
"""

from __future__ import annotations

import csv
import glob
import json
import os
import re

KEEP = ('paragraph', 'takeaway', 'quote')

# ElevenLabs break tags. One tag on each side of a heading is enough: the model
# gets unstable when they are stacked, and caps each one at 3 s.
BREAK_BEFORE_CHAPTER = '<break time="1.5s" />'
BREAK_AFTER_CHAPTER = '<break time="0.8s" />'
BREAK_ECHO = '<break time="0.4s" />'
BREAK_TAKEAWAY = '<break time="1.2s" />'
BREAK_QUOTE = '<break time="0.6s" />'
BREAK_VERSE = '<break time="0.3s" />'

TAG = re.compile(r'<break time="[0-9.]+s" />')


class Log:
    """Every transformation, so a listener's complaint can be traced to a rule."""

    def __init__(self):
        self.rows = []

    def __call__(self, cid, category, before, after):
        self.rows.append((cid, category, before, after))


def ends_sentence(s):
    s = s.rstrip().rstrip('”"’»)').rstrip()
    return s.endswith(('.', '!', '?', '…'))


def sentence(s):
    s = s.strip().rstrip(',;')
    return s if not s or ends_sentence(s) else s + '.'


# ------------------------------------------------------------------- markup
#
# Order matters. Italics close on an asterisk glued to a word (*Psycho*),
# exactly like a star in a black hole's name (M87*). Bold goes first, then
# italic pairs with a bounded, non-greedy pattern — unbounded, two lone stars
# in one paragraph pair up and swallow the text between them — and only then is
# a surviving star read as the word it stands for.
# Le point est admis dans l'italique (« *St. Matthew Passion* ») mais la
# borne de 60 caractères empêche toujours deux astérisques isolés d'un même
# paragraphe de s'apparier et d'avaler le texte entre eux.
ITALIC = re.compile(r'(?<!\*)\*(?!\*)([^*\n!?]{1,60}?)\*(?!\*)')
LONE_STAR = re.compile(r'\b([A-Z][A-Za-z]*\d*(?:\s+[A-Z])?)\*(?!\*)')
GLOSSARY = re.compile(r'\[\[([^\]]*)\]\]')
PAREN_IN_GLOSSARY = re.compile(r'\s*\([^)]*\)')


def strip_markup(t, cid, log, lang):
    # An in-app cross-reference ("See [[...]].") points at a screen, not at
    # anything a listener can follow.
    for prefix in lang.SEE_PREFIXES:
        pattern = re.compile(r'(?:^|(?<=[.!?] ))' + re.escape(prefix) + r'\s+\[\[[^\]]*\]\]\s*[.!?]?\s*')
        for m in pattern.finditer(t):
            log(cid, 'renvoi supprimé', m.group(0).strip(), '')
        t = pattern.sub('', t)

    # The text inside [[...]] is a glossary headword, not prose. Its
    # parenthetical disambiguates the label ("tantalum (Ta, 73)",
    # "Montreal Protocol (1987)") and read aloud either means nothing or
    # repeats the year the sentence has just said.
    def headword(m):
        inner = m.group(1)
        cleaned = PAREN_IN_GLOSSARY.sub('', inner)
        if cleaned != inner:
            log(cid, 'glossaire', inner, cleaned)
        # A headword carries its own article ("le [[Le droit de veto]]") while
        # the sentence already has one, so the voice stutters it: "le Le".
        before = t[:m.start()].rstrip()
        # le gras n'est pas encore retiré : dans « la **[[La ...]]** » le dernier
        # jeton est « ** », qui devient vide une fois nettoyé.
        tokens = [w.strip('*') for w in re.split(r"[\s’']", before)]
        tokens = [w for w in tokens if w]
        previous = tokens[-1].lower() if tokens else ''
        words = cleaned.split(' ')
        if (len(words) > 1 and previous in lang.DETERMINERS
                and words[0].lower() in lang.DETERMINERS):
            log(cid, 'article doublé', f'{previous} {cleaned}', f'{previous} {" ".join(words[1:])}')
            cleaned = ' '.join(words[1:])
        return cleaned

    t = GLOSSARY.sub(headword, t)
    t = t.replace('**', '')
    t = ITALIC.sub(r'\1', t)

    def star(m):
        out = f'{m.group(1)} {lang.STAR_WORD}'
        log(cid, 'nom astronomique', m.group(0), out)
        return out

    t = LONE_STAR.sub(star, t)
    return t.replace('*', '')


def unparenthesize(t, cid, log):
    """Parentheses give the voice no pause, so an aside runs straight into the
    sentence ("Caravaggio (1571-1610) imposed"). Commas do."""
    def rep(m):
        out = f', {m.group(1).strip()},'
        log(cid, 'parenthèses', m.group(0).strip(), out)
        return out

    return re.sub(r'\s*\(([^()]*)\)', rep, t)


def capitalize_first(t, lang=None):
    if lang is not None and hasattr(lang, 'capitalize_first'):
        return lang.capitalize_first(t)
    return _ascii_capitalize(t)


# A sentence that opened on a figure comes back lowercase from the speller,
# which is common in Turkish, where the year opens the sentence with no
# preposition: "1919'da Mustafa Kemal" -> "bin dokuz yüz on dokuzda ...".
ABREV_POINT = {'av', 'vs', 'J', 'C', 'Dr', 'St', 'Mr', 'Mrs', 'Ms', 'no'}
SENTENCE_START = re.compile(r'(?P<fin>[.!?])(?P<esp>\s+)(?P<mot>\w)')


def capitalize_sentences(t, lang=None):
    def rep(m):
        if not m.group('mot').islower():
            return m.group(0)
        i = m.start('fin')
        if t[max(0, i - 2):i] == '..':          # « ... ou explosent » : suspension
            return m.group(0)
        mot_avant = re.search(r'([\w\u00c0-\u024f-]+)$', t[:i])
        if mot_avant and mot_avant.group(1).strip('-') in ABREV_POINT:
            return m.group(0)                   # « av. J.-C. », « vs. »
        return m.group('fin') + m.group('esp') + capitalize_first(m.group('mot'), lang)
    return SENTENCE_START.sub(rep, t)


def _ascii_capitalize(t):
    """A block that opened on a number comes back lowercase from the speller:
    "1940 made Germany master" -> "nineteen forty made Germany master"."""
    return t[0].upper() + t[1:] if t and t[0].islower() else t


def tidy(t):
    t = re.sub(r',\s*,', ',', t)
    t = re.sub(r',\s*([.;:!?…])', r'\1', t)
    # Ne pas toucher au point d'une abréviation : « av. J.-C., Aristote » et
    # « Josef K., employé de banque » perdaient leur virgule, donc leur pause.
    t = re.sub(r'([;:!?])\s*,', r'\1', t)
    t = re.sub(r'^\s*,\s*', '', t)
    t = re.sub(r'\s+,', ',', t)
    t = re.sub(r'[ \t]+', ' ', t)
    return t.strip()


# --------------------------------------------------------------------- render

def render(course, lang, log):
    cid = course['id']
    fixes = lang.SOURCE_FIXES.get(cid, [])
    used = set()

    def prep(text):
        text = text or ''
        for i, (old, new) in enumerate(fixes):
            if old in text:
                text = text.replace(old, new)
                used.add(i)
                log(cid, 'correctif source', old, new)
        return text

    def say(text):
        t = strip_markup(prep(text), cid, log, lang)
        t = unparenthesize(t, cid, log)
        t = lang.normalize(t, cid, log)
        t = lang.respell(t, cid, log)
        return capitalize_sentences(capitalize_first(tidy(t), lang), lang)

    def finish(text):
        """Hand-written narration: no markup to strip, same reading rules."""
        return capitalize_sentences(
            capitalize_first(tidy(lang.respell(lang.normalize(text, cid, log), cid, log)), lang), lang)

    title = say(course.get('title'))
    subtitle = say(course.get('subtitle'))
    hook = say((course.get('hero') or {}).get('hook'))

    head = [sentence(title)] if title else []
    if subtitle:
        # "How did Constantinople fall in 1453?" followed by "1453."
        if subtitle.rstrip('.').lower() in title.lower():
            log(cid, 'sous-titre redondant', subtitle, '')
        else:
            head.append(sentence(subtitle))
    if hook:
        head.append(sentence(hook))

    parts, chapters = [], []
    for i, section in enumerate(course.get('sections', [])):
        n = i + 1
        lines = list(head) if i == 0 else []
        # A pause before every heading except at the very start of the file,
        # where ElevenLabs renders a leading tag badly.
        if lines or i > 0:
            lines.append(BREAK_BEFORE_CHAPTER)

        heading = say(section.get('title'))
        label = lang.chapter_label(n)
        if heading and lang.echoes_chapter_number(heading, n):
            # "Chapter two. Two brothers" would blur into one number.
            lines.append(f'{label} {BREAK_ECHO} {sentence(heading)}')
            log(cid, 'écho du numéro de chapitre', f'{label} {heading}', 'pause 0,4 s')
        else:
            lines.append(f'{label} {sentence(heading)}' if heading else label)
        lines.append(BREAK_AFTER_CHAPTER)

        narrated = [b for b in section.get('blocks', []) if b.get('type') in KEEP]
        body = []
        for bi, block in enumerate(narrated):
            last = bi == len(narrated) - 1
            kind = block['type']

            if kind == 'quote':
                spec = lang.QUOTES[cid]  # a quote with no entry fails the build
                if 'paraphrase' in spec:
                    body.append(finish(spec['paraphrase']))
                    log(cid, 'citation paraphrasée', block.get('text', ''), spec['paraphrase'])
                    continue
                quote = say(block.get('text'))
                quote = quote.replace(' / ', f' {BREAK_VERSE} ')
                body += [BREAK_QUOTE, sentence(quote), sentence(finish(spec['attribution']))]
                # A quote that closes its section would stack its pause onto the
                # 1.5 s before the next heading.
                if not last:
                    body.append(BREAK_QUOTE)
                continue

            text = say(block.get('text'))
            if not text:
                continue
            if kind == 'takeaway':
                body += [BREAK_TAKEAWAY, lang.TAKEAWAY_LEADIN]
            body.append(text)

        if not body:
            continue
        chapters.append(section.get('title') or '')
        parts.append('\n\n'.join(lines + body))

    stale = [fixes[i][0] for i in range(len(fixes)) if i not in used]
    if stale:
        raise SystemExit(f'{cid}: source fix no longer matches the text: {stale!r}')
    return '\n\n\n'.join(parts), chapters, parts


# ----------------------------------------------------------------- validation

def problems(text, lang):
    """Everything left in the text that a voice would read aloud by mistake."""
    bare = TAG.sub('', text)
    found = []
    if re.search(r'\d', bare):
        found += [('chiffre', m.group(0)) for m in re.finditer(r'\S*\d\S*', bare)]
    for sym in ('[[', ']]', '*', '_', '<', '>', '#', '`', '?.', '!.'):
        if sym in bare:
            found.append(('symbole', sym))
    found += lang.extra_checks(bare)
    return found


# ---------------------------------------------------------------------- build

def build(lang, root, dest):
    os.makedirs(dest, exist_ok=True)
    chap_dir = os.path.join(dest, 'chapitres')
    os.makedirs(chap_dir, exist_ok=True)

    log = Log()
    rows, chap_rows, issues, total = [], [], [], 0
    files = sorted(glob.glob(os.path.join(root, 'content', 'courses', lang.LANG, '*.json')))
    quote_courses = set()

    for path in files:
        course = json.load(open(path, encoding='utf-8'))
        cid = course['id']
        if any(b.get('type') == 'quote' for s in course.get('sections', []) for b in s.get('blocks', [])):
            quote_courses.add(cid)
        text, chapters, parts = render(course, lang, log)

        name = cid + '.txt'
        with open(os.path.join(dest, name), 'w', encoding='utf-8') as fh:
            fh.write(text + '\n')
        total += len(text)
        rows.append({'fichier': name, 'course_id': cid, 'titre': course.get('title', ''),
                     'chapitres': len(chapters), 'caracteres': len(text)})
        for kind, what in problems(text, lang):
            issues.append((cid, kind, what))

        # Per-chapter files, for mixing a jingle between chapters. The leading
        # pause goes: the jingle is the break.
        for k, part in enumerate(parts, 1):
            part = re.sub(r'^\s*<break[^>]*/>\s*', '', part)
            ch_name = f'{cid}__ch{k}.txt'
            with open(os.path.join(chap_dir, ch_name), 'w', encoding='utf-8') as fh:
                fh.write(part + '\n')
            chap_rows.append({'fichier': ch_name, 'course_id': cid, 'chapitre': k,
                              'titre': chapters[k - 1], 'caracteres': len(part)})

    missing = sorted(set(lang.QUOTES) - quote_courses)
    if missing:
        raise SystemExit(f'quote table entries with no quote block: {missing}')

    def write_csv(path, header, data):
        with open(path, 'w', newline='', encoding='utf-8') as fh:
            w = csv.writer(fh)
            w.writerow(header)
            w.writerows(data)

    with open(os.path.join(dest, 'manifest.csv'), 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    with open(os.path.join(chap_dir, 'chapitres.csv'), 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=list(chap_rows[0].keys()))
        w.writeheader()
        w.writerows(chap_rows)
    write_csv(os.path.join(dest, 'transformations.csv'), ['course_id', 'categorie', 'avant', 'apres'], log.rows)
    write_csv(os.path.join(dest, 'problemes.csv'), ['course_id', 'type', 'texte'], issues)

    return {'courses': len(files), 'chapters': len(chap_rows), 'characters': total,
            'transformations': len(log.rows), 'problems': issues, 'log': log.rows}
