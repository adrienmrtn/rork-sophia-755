"""English reading rules for the ElevenLabs narration.

Almost nothing in the French rules carries over. English reads years in pairs
("eighteen sixty-six"), writes centuries as digit ordinals ("19th century"),
puts "the" before a regnal ordinal ("Louis the Sixteenth"), groups thousands
with a comma that French uses for decimals, puts "$" before the number, and uses
"I" as a pronoun — so a Roman-numeral pattern is wrong more often than right.

Pass order is the one the corpus survey established: title and designator
lexicons, abbreviations, regnal names, signs, currency, percent, units, times,
decimals, comma thousands, dates, decades, ordinals, ranges, years, cardinals,
and only then pronunciation respelling.
"""

from __future__ import annotations

import json
import os
import re

LANG = 'en'
STAR_WORD = 'star'
SEE_PREFIXES = ('See',)
# The corpus avoids contractions (471 "does not" against 4 "n't"): the added
# lines keep that register.
TAKEAWAY_LEADIN = 'Here is what to remember from this course.'

CHAPTER_WORDS = {1: 'one', 2: 'two', 3: 'three', 4: 'four', 5: 'five'}


def chapter_label(n):
    return f'Chapter {CHAPTER_WORDS[n]}.'


def echoes_chapter_number(heading, n):
    first = re.split(r'[\s,:;.!?]', heading.strip(), 1)[0].lower()
    return first == CHAPTER_WORDS[n]


DETERMINERS = {'the', 'a', 'an'}

SOURCE_FIXES = {
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_229_l_ue_comment_ca_marche_vraiment': [
        ('[[The European Commission and the monopoly of legislative initiative]]', 'the monopoly of legislative initiative'),
    ],
    # L'apposition entre parenthèses s'entend comme un sixième item
    # de l'énumération, alors que la phrase en annonce cinq.
    'course_237_les_gafam_puissance_et_derives': [
        ('Meta (once Facebook)', 'Meta, formerly Facebook'),
    ],
    'course_109_don_quichotte_cervantes': [
        ("**[[Battle of Lepanto (1571) and Cervantes' captivity]]**", '**Battle of Lepanto** in 1571'),
    ],
    'course_128_l_expressionnisme_munch_et_le_cri': [
        ('the [[Eruption of Krakatoa (1883) and the red sky]]', 'the eruption of Krakatoa in 1883'),
    ],
    # French glossary slugs left untranslated in the English text.
    'course_153_la_creation_d_adam_michel_ange': [
        ('[[dissection_anatomique]]', 'anatomical dissection'),
        ('[[manière_moderne]]', 'the modern manner'),
    ],
}

# Speaker first whenever the line is not the author's own voice.
QUOTES = {
    'course_100_les_fleurs_du_mal_baudelaire': {'attribution':
        'These are the opening lines of the sonnet Correspondences, by Charles Baudelaire.'},
    'course_101_1984_george_orwell': {'attribution':
        'These are the three slogans of the Party, in George Orwell\'s Nineteen Eighty-Four.'},
    'course_102_la_ferme_des_animaux_george_orwell': {'attribution':
        'This is the commandment the pigs rewrite, in George Orwell\'s Animal Farm.'},
    'course_103_hamlet_shakespeare': {'attribution':
        'So speaks Hamlet, in Act Three, Scene One of William Shakespeare\'s play.'},
    'course_104_romeo_et_juliette_shakespeare': {'attribution':
        'It is Juliet who speaks, in Act Two, Scene Two of Romeo and Juliet.'},
    'course_105_le_meilleur_des_mondes_aldous_huxley': {'attribution':
        'So says John the Savage, in Aldous Huxley\'s Brave New World.'},
    'course_106_frankenstein_mary_shelley': {'attribution':
        'It is the creature who speaks, in Mary Shelley\'s Frankenstein.'},
    'course_108_le_proces_kafka': {'attribution':
        'These are the opening words of Franz Kafka\'s The Trial.'},
    'course_109_don_quichotte_cervantes': {'attribution':
        'So says Don Quixote himself, in Miguel de Cervantes\'s novel.'},
    'course_112_le_grand_gatsby_fitzgerald': {'attribution':
        'These are the words of the narrator, Nick Carraway, in the last pages of Francis Scott '
        'Fitzgerald\'s The Great Gatsby.'},
    # The line cannot be found in Bradbury: it reads like a back-translation of
    # the French course, so it is narrated as a paraphrase, not as a quote.
    'course_114_fahrenheit_451_bradbury': {'paraphrase':
        'In the last pages of the novel, the exiles Montag joins have each learned a book by heart. '
        'The fire has touched them, but through them, the books survive.'},
    'course_117_le_maitre_et_marguerite_boulgakov': {'attribution':
        'It is Woland who says it, in Mikhail Bulgakov\'s The Master and Margarita.'},
    'course_119_le_petit_prince_saint_exupery': {'attribution':
        'It is the fox who shares his secret, in Antoine de Saint-Exupéry\'s The Little Prince.'},
    'course_91_les_miserables_victor_hugo': {'attribution':
        'So speaks Bishop Myriel, in Victor Hugo\'s Les Misérables.'},
    'course_94_candide_voltaire': {'attribution':
        'These are the words of the enslaved man of Surinam, in Voltaire\'s Candide.'},
    'course_96_l_etranger_camus': {'attribution':
        'These are the opening words of Albert Camus\'s The Stranger.'},
    'course_97_le_mythe_de_sisyphe_camus': {'attribution':
        'It is with this sentence that Albert Camus closes The Myth of Sisyphus.'},
    'course_98_a_la_recherche_du_temps_perdu_proust': {'attribution':
        'So says the narrator of Swann\'s Way, by Marcel Proust.'},
    'course_99_le_pere_goriot_balzac': {'attribution':
        'It is the challenge Rastignac throws at Paris, on the last page of Honoré de Balzac\'s '
        'Père Goriot.'},
}


# ------------------------------------------------------------------- numbers
ONES = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
        'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen',
        'nineteen']
TENS = {2: 'twenty', 3: 'thirty', 4: 'forty', 5: 'fifty', 6: 'sixty', 7: 'seventy', 8: 'eighty',
        9: 'ninety'}
SCALES = [(10 ** 12, 'trillion'), (10 ** 9, 'billion'), (10 ** 6, 'million'), (10 ** 3, 'thousand')]


def under_100(n):
    if n < 20:
        return ONES[n]
    return TENS[n // 10] + ('-' + ONES[n % 10] if n % 10 else '')


def under_1000(n):
    h, r = divmod(n, 100)
    parts = []
    if h:
        parts.append(ONES[h] + ' hundred')
    if r:
        parts.append(under_100(r))
    return ' '.join(parts)


def cardinal(n):
    """US style, no "and": 150 is "one hundred fifty"."""
    if n == 0:
        return 'zero'
    parts = []
    for value, name in SCALES:
        q, n = divmod(n, value)
        if q:
            parts.append(f'{under_1000(q)} {name}')
    if n:
        parts.append(under_1000(n))
    return ' '.join(parts)


IRREGULAR_ORDINALS = {'one': 'first', 'two': 'second', 'three': 'third', 'five': 'fifth',
                      'eight': 'eighth', 'nine': 'ninth', 'twelve': 'twelfth'}


def _last_word(words, fn):
    m = re.match(r'^(.*?)([a-z]+)$', words)
    return m.group(1) + fn(m.group(2))


def ordinal(n):
    """Built from the whole word, never cardinal + suffix: that gives 'twentyth'."""
    def inflect(w):
        if w in IRREGULAR_ORDINALS:
            return IRREGULAR_ORDINALS[w]
        return w[:-1] + 'ieth' if w.endswith('y') else w + 'th'
    return _last_word(cardinal(n), inflect)


def year(n):
    """1866 eighteen sixty-six, 1805 eighteen oh-five, 1600 sixteen hundred,
    2001 two thousand one, 2024 twenty twenty-four, 2100 twenty-one hundred."""
    if n == 1000 or 2000 <= n <= 2009:
        return cardinal(n)
    hi, lo = divmod(n, 100)
    if lo == 0:
        return f'{cardinal(hi)} hundred'
    if lo < 10:
        return f'{cardinal(hi)} oh-{ONES[lo]}'
    return f'{cardinal(hi)} {under_100(lo)}'


def plural(words):
    """nineteen thirty -> nineteen thirties, two thousand -> two thousands."""
    def inflect(w):
        if w.endswith('y'):
            return w[:-1] + 'ies'
        return w + ('es' if w.endswith('x') else 's')
    return _last_word(words, inflect)


def decimal(whole, frac):
    """1.7 one point seven; 0.005 zero point zero zero five."""
    return f'{cardinal(int(whole))} point ' + ' '.join(ONES[int(c)] for c in frac)


def quantity(s):
    """A quantity, never a year: 1,300 km is one thousand three hundred."""
    s = s.replace(',', '')
    if '.' in s:
        whole, frac = s.split('.', 1)
        return decimal(whole, frac)
    return cardinal(int(s))


# ---------------------------------------------------------- whole-token lexicons
# Names whose spoken form no reader can derive from the digits.
TITLES = [
    ('1,001 nights', 'a thousand and one nights'),
    ('1,001 Nights', 'a Thousand and One Nights'),
    ('Room 101', 'Room one-oh-one'),
    ('Fahrenheit 451', 'Fahrenheit four fifty-one'),
    ('HAL 9000', 'HAL nine thousand'),
]

DESIGNATORS = [
    ('TR-808', 'T-R eight-oh-eight'),
    ('B-612', 'B six-twelve'),
    ('COVID-19', 'Covid nineteen'),
    ('G20', 'G twenty'),
    ('G7', 'G seven'),
    ('U-2', 'U-two'),
    ('SS-4', 'S-S four'),
    ('B-59', 'B fifty-nine'),
    ('R2P', 'R two P'),
    ('COP15', 'Cop fifteen'),
    ('3D', 'three-D'),
    ('CO₂', 'C-O two'),
    ('E=mc²', 'E equals m c squared'),
    ('M87', 'M eighty-seven'),
    ('F. Scott Fitzgerald', 'Francis Scott Fitzgerald'),
    ('N.W.A', 'N-W-A'),
    ('TCP/IP', 'T-C-P I-P'),
    ('OPEC+', 'Opec plus'),
    ('4/4', 'four-four'),
]


def _whole_token(t, pairs, cid, log, category):
    for raw, spoken in sorted(pairs, key=lambda p: -len(p[0])):
        pattern = re.compile(r'(?<![\w-])' + re.escape(raw) + r'(?![\w])')
        if pattern.search(t):
            t = pattern.sub(spoken, t)
            log(cid, category, raw, spoken)
    return t


ABBREVIATIONS = [
    (re.compile(r'\bvs?\.(?=\s)'), 'versus'),
    (re.compile(r'\bNo\.\s(?=\d)'), 'number '),
    (re.compile(r'(?<![A-Za-z])c\.\s?(?=\d)'), 'around '),
    (re.compile(r'\bSt\.(?=\s)'), 'Saint'),
    (re.compile(r'\bJr\b\.?'), 'Junior'),
    # a.m. at the end of a sentence keeps its full stop
    (re.compile(r'\ba\.m\.(?=\s+[A-Z])'), 'A-M.'),
    (re.compile(r'\bp\.m\.(?=\s+[A-Z])'), 'P-M.'),
    (re.compile(r'\ba\.m\.'), 'A-M'),
    (re.compile(r'\bp\.m\.'), 'P-M'),
]


def fix_abbreviations(t, cid, log):
    for pattern, spoken in ABBREVIATIONS:
        for m in pattern.finditer(t):
            log(cid, 'abréviation', m.group(0), spoken)
        t = pattern.sub(spoken, t)
    return t


# The 26 regnal names of the corpus plus the numbered parts, from a whitelist:
# a pattern on the bare letters converts the pronoun "I", X-rays and initials.
REGNAL = {
    'Urban II': 'Urban the Second', 'Nicholas II': 'Nicholas the Second',
    'Louis XVI': 'Louis the Sixteenth', 'Napoleon III': 'Napoleon the Third',
    'Charles VII': 'Charles the Seventh', 'Julius II': 'Julius the Second',
    'Charles X': 'Charles the Tenth', 'Moctezuma II': 'Moctezuma the Second',
    'Leo III': 'Leo the Third', 'Mehmed II': 'Mehmed the Second',
    'Constantine XI': 'Constantine the Eleventh', 'Elizabeth I': 'Elizabeth the First',
    'Francis I': 'Francis the First', 'Francis II': 'Francis the Second',
    'Alexander I': 'Alexander the First', 'Joseph II': 'Joseph the Second',
    'Louis-Philippe I': 'Louis-Philippe the First', 'Louis XIV': 'Louis the Fourteenth',
    'Abdul Hamid II': 'Abdul Hamid the Second', 'Alexios I': 'Alexios the First',
    'Alaric I': 'Alaric the First', 'Philip II': 'Philip the Second',
    'Innocent III': 'Innocent the Third', 'Henry III': 'Henry the Third',
    'Clement VI': 'Clement the Sixth', 'Henry VI': 'Henry the Sixth',
    # numbered parts read as bare cardinals: "World War One", "Book Nine"
    'World War I': 'World War One', 'World War II': 'World War Two',
    'Book IX': 'Book Nine',
}
_REGNAL = re.compile(r'(?<![\w-])(' + '|'.join(re.escape(k) for k in sorted(REGNAL, key=len, reverse=True))
                     + r')(?=[\s.,;:!?\'’”)]|$)')


def fix_regnal(t, cid, log):
    def rep(m):
        log(cid, 'romain', m.group(1), REGNAL[m.group(1)])
        return REGNAL[m.group(1)]
    return _REGNAL.sub(rep, t)


def fix_initials(t, cid, log):
    """A period after a single initial is not a sentence end: "Franklin D.
    Roosevelt", "B.B. King", "The harder K. defends himself"."""
    # Chain of initials: "B.B. King", "J.R.R. Tolkien", "N.W.A".
    t2 = re.sub(r'\b([A-Z])\.(?=[A-Z])', r'\1 ', t)
    # A single initial only counts as one when a capitalised name precedes it —
    # otherwise "it forms a V. Because of that shape" loses its full stop, and
    # so does "ten twenty-eight A-M. American airspace".
    t2 = re.sub(r'\b([A-Z][a-z]+) ([A-Z])\.(?=\s+[A-Z][a-z])', r'\1 \2', t2)
    t2 = re.sub(r'\b([A-Z]) ([A-Z])\.(?=\s+[A-Z][a-z])', r'\1 \2', t2)
    # "Josef K., a bank clerk": the period must go, the comma must stay.
    t2 = re.sub(r'\b([A-Z])\.(?=,)', r'\1', t2)
    t2 = re.sub(r'\b([A-Z])\.(?=\s+[a-z])', r'\1', t2)
    if t2 != t:
        log(cid, 'initiale', 'point après une initiale', 'retiré')
    return t2


NUM = r'\d[\d,]*(?:\.\d+)?'


def fix_signs(t, cid, log):
    """A sign is a hyphen or plus with no digit or letter before it; between two
    digits the hyphen is a range, which reads "to"."""
    t2 = re.sub(r'(?<![\w\d])-(?=\d)', 'minus ', t)
    t2 = re.sub(r'(?<![\w\d])\+(?=\d)', 'plus ', t2)
    if t2 != t:
        log(cid, 'signe', 'signe devant un nombre', 'minus / plus')
    return t2


CURRENCY = re.compile(r'\$\s?(?P<n>' + NUM + r')(?P<scale>\s(?:thousand|million|billion|trillion))?')


def fix_currency(t, cid, log):
    def rep(m):
        n, scale = m.group('n'), m.group('scale') or ''
        unit = 'dollar' if n == '1' and not scale else 'dollars'
        out = f'{quantity(n)}{scale} {unit}'
        log(cid, 'devise', m.group(0), out)
        return out
    return CURRENCY.sub(rep, t)


PERCENT = re.compile(r'(?P<n>' + NUM + r')\s?%')


def fix_percent(t, cid, log):
    def rep(m):
        out = f"{quantity(m.group('n'))} percent"
        log(cid, 'pourcent', m.group(0), out)
        return out
    return PERCENT.sub(rep, t)


UNITS = [
    ('km/h', 'kilometer per hour', 'kilometers per hour'),
    ('km/s', 'kilometer per second', 'kilometers per second'),
    ('m/s', 'meter per second', 'meters per second'),
    ('g/l', 'gram per liter', 'grams per liter'),
    ('km²', 'square kilometer', 'square kilometers'),
    ('°C', 'degree Celsius', 'degrees Celsius'),
    ('°F', 'degree Fahrenheit', 'degrees Fahrenheit'),
    ('km', 'kilometer', 'kilometers'),
    ('cm', 'centimeter', 'centimeters'),
    ('mm', 'millimeter', 'millimeters'),
    ('kg', 'kilogram', 'kilograms'),
    ('°', 'degree', 'degrees'),
]
_UNIT_ALT = '|'.join(re.escape(u) for u, _, _ in UNITS)
UNIT = re.compile(r'(?P<n>' + NUM + r')\s?(?P<u>' + _UNIT_ALT + r')(?![\w²])')
UNIT_AFTER_SCALE = re.compile(r'(?P<scale>\b(?:million|billion|thousand) )(?P<u>' + _UNIT_ALT + r')(?![\w²])')


def fix_units(t, cid, log):
    def rep(m):
        n, sym = m.group('n'), m.group('u')
        sing, plur = next((s, p) for u, s, p in UNITS if u == sym)
        # English: singular for exactly one, plural for 0 and every decimal
        out = f"{quantity(n)} {sing if n == '1' else plur}"
        log(cid, 'unité', m.group(0), out)
        return out
    t = UNIT.sub(rep, t)

    def after_scale(m):
        plur = next(p for u, _, p in UNITS if u == m.group('u'))
        log(cid, 'unité', m.group('u'), plur)
        return m.group('scale') + plur
    return UNIT_AFTER_SCALE.sub(after_scale, t)


CLOCK = re.compile(r'\b(?P<h>\d{1,2}):(?P<m>\d{2})\b')


def fix_times(t, cid, log):
    def rep(m):
        h, mn = int(m.group('h')), int(m.group('m'))
        if mn == 0:
            out = f"{cardinal(h)} o'clock"
        elif mn < 10:
            out = f'{cardinal(h)} oh-{ONES[mn]}'
        else:
            out = f'{cardinal(h)} {under_100(mn)}'
        log(cid, 'heure', m.group(0), out)
        return out
    return CLOCK.sub(rep, t)


DECIMAL = re.compile(r'(?<![\d,.])(?P<a>\d+)\.(?P<b>\d+)(?![\d])')
THOUSANDS = re.compile(r'(?<![\d.])\d{1,3}(?:,\d{3})+(?![\d])')


def fix_decimals_and_thousands(t, cid, log):
    def dec(m):
        out = decimal(m.group('a'), m.group('b'))
        log(cid, 'décimale', m.group(0), out)
        return out
    t = DECIMAL.sub(dec, t)

    def grp(m):
        # comma-grouped numbers are quantities in this corpus, never years
        out = cardinal(int(m.group(0).replace(',', '')))
        log(cid, 'nombre', m.group(0), out)
        return out
    return THOUSANDS.sub(grp, t)


MONTHS = ('January|February|March|April|May|June|July|August|September|October|November|December')
DAY_AFTER_MONTH = re.compile(r'\b(?P<month>' + MONTHS + r')\s+(?P<d1>\d{1,2})'
                             r'(?:(?P<sep>\s*-\s*|\s+(?:and|to|or)\s+)(?P<d2>\d{1,2}))?(?![\d])')
DAY_BEFORE_MONTH = re.compile(r'\b(?P<d>\d{1,2})\s+(?P<month>' + MONTHS + r')\b(?P<year>\s+\d{4})?')


def fix_dates(t, cid, log):
    """US dates read the day as an ordinal: "July 14" is "July fourteenth"."""
    def us(m):
        out = f"{m.group('month')} {ordinal(int(m.group('d1')))}"
        if m.group('d2'):
            joiner = ' to ' if '-' in m.group('sep') else m.group('sep')
            out += f"{joiner}{ordinal(int(m.group('d2')))}"
        log(cid, 'date', m.group(0), out)
        return out
    t = DAY_AFTER_MONTH.sub(us, t)

    def uk(m):
        out = f"the {ordinal(int(m.group('d')))} of {m.group('month')}"
        if m.group('year'):
            out += ',' + m.group('year')
        log(cid, 'date', m.group(0), out)
        return out
    return DAY_BEFORE_MONTH.sub(uk, t)


DECADE_RANGE = re.compile(r'\b(?P<a>\d{4})s\s*-\s*(?P<b>\d{2})s\b')
DECADE = re.compile(r'\b(?P<y>\d{4})s\b')


def fix_decades(t, cid, log):
    def rng(m):
        out = f"{plural(year(int(m.group('a'))))} to {plural(cardinal(int(m.group('b'))))}"
        log(cid, 'décennie', m.group(0), out)
        return out
    t = DECADE_RANGE.sub(rng, t)

    def one(m):
        out = plural(year(int(m.group('y'))))
        log(cid, 'décennie', m.group(0), out)
        return out
    return DECADE.sub(one, t)


ORDINAL_RANGE = re.compile(r'\b(?P<a>\d+)(?:st|nd|rd|th)\s*-\s*(?P<b>\d+)(?:st|nd|rd|th)\b')
ORDINAL_DIGITS = re.compile(r'\b(?P<n>\d+)(?:st|nd|rd|th)\b')


def fix_ordinals(t, cid, log):
    def rng(m):
        out = f"{ordinal(int(m.group('a')))} to {ordinal(int(m.group('b')))}"
        log(cid, 'ordinal', m.group(0), out)
        return out
    t = ORDINAL_RANGE.sub(rng, t)

    def one(m):
        out = ordinal(int(m.group('n')))
        log(cid, 'ordinal', m.group(0), out)
        return out
    return ORDINAL_DIGITS.sub(one, t)


RANGE = re.compile(r'(?<![\w.,])(?P<a>\d+)\s*-\s*(?P<b>\d+)(?![\d])')


def fix_ranges(t, cid, log):
    def rep(m):
        a, b = m.group('a'), m.group('b')
        if len(a) == 4 and len(b) == 2:
            b = a[:2] + b
        out = f'{a} to {b}'
        log(cid, 'plage', m.group(0), out)
        return out
    return RANGE.sub(rep, t)


YEAR = re.compile(r'(?<![\d,.])(?P<y>[12]\d{3})(?![\d]|[.,]\d)')
INTEGER = re.compile(r'\d+')


def fix_years_and_cardinals(t, cid, log):
    """By shape, not by context: every bare 4-digit number from 1000 to 2100 in
    this corpus is a year, and a cue-word detector misses 222 of them."""
    def yr(m):
        n = int(m.group('y'))
        if not 1000 <= n <= 2100:
            return m.group(0)
        out = year(n)
        log(cid, 'année', m.group(0), out)
        return out
    t = YEAR.sub(yr, t)

    def num(m):
        out = cardinal(int(m.group(0)))
        log(cid, 'nombre', m.group(0), out)
        return out
    return INTEGER.sub(num, t)


SYMBOLS = [
    (re.compile(r'\s*&\s*'), ' and '),
    (re.compile(r'\s*→\s*'), ' gives '),
    (re.compile(r'(?<=[\w)])\s*\+\s*(?=[\w(])'), ' plus '),
    (re.compile(r'(?<=[\w)])\s*=\s*(?=[\w(])'), ' equals '),
    # "East/West": the slash separates two words, it is not spoken
    (re.compile(r'(?<=[A-Za-z])/(?=[A-Za-z])'), '-'),
]


def fix_symbols(t, cid, log):
    for pattern, out in SYMBOLS:
        for m in pattern.finditer(t):
            log(cid, 'symbole', m.group(0), out)
        t = pattern.sub(out, t)
    return t


TAG = re.compile(r'<[^>]*>')


def _outside_tags(t, fn):
    out, pos = [], 0
    for m in TAG.finditer(t):
        out.append(fn(t[pos:m.start()]))
        out.append(m.group(0))
        pos = m.end()
    out.append(fn(t[pos:]))
    return ''.join(out)


def normalize(t, cid, log):
    def run(s):
        s = _whole_token(s, TITLES, cid, log, 'titre')
        s = _whole_token(s, DESIGNATORS, cid, log, 'désignateur')
        s = fix_abbreviations(s, cid, log)
        s = fix_regnal(s, cid, log)
        s = fix_signs(s, cid, log)
        s = fix_currency(s, cid, log)
        s = fix_percent(s, cid, log)
        s = fix_units(s, cid, log)
        s = fix_initials(s, cid, log)
        s = fix_times(s, cid, log)
        s = fix_decimals_and_thousands(s, cid, log)
        s = fix_dates(s, cid, log)
        s = fix_decades(s, cid, log)
        s = fix_ordinals(s, cid, log)
        s = fix_ranges(s, cid, log)
        s = fix_years_and_cardinals(s, cid, log)
        return fix_symbols(s, cid, log)
    return _outside_tags(t, run)


# ------------------------------------------------------------ pronunciation
# Hard names and every acronym, respelled in the text itself: an English voice
# reads "Meursault" as "mer-salt" and "WHO" as "who". Case-sensitive and
# whole-word, so "who" and "us" are never touched.
_LEXICON_PATH = os.path.join(os.path.dirname(__file__), 'lexicon_en.json')
_LEXICON = {}
_LEXICON_RE = None


def _load_lexicon():
    global _LEXICON, _LEXICON_RE
    if _LEXICON_RE is not None or not os.path.exists(_LEXICON_PATH):
        return
    entries = json.load(open(_LEXICON_PATH, encoding='utf-8'))
    _LEXICON = {e['term']: e['respelling'] for e in entries}
    alternation = '|'.join(re.escape(k) for k in sorted(_LEXICON, key=len, reverse=True))
    _LEXICON_RE = re.compile(r'(?<![\w])(' + alternation + r')(?![\w])')


def respell(t, cid, log):
    _load_lexicon()
    if _LEXICON_RE is None:
        return t

    def rep(m):
        log(cid, 'prononciation', m.group(1), _LEXICON[m.group(1)])
        return _LEXICON[m.group(1)]
    return _outside_tags(t, lambda s: _LEXICON_RE.sub(rep, s))


def extra_checks(bare):
    found = []
    for sym in ('%', '$', '°', '/', '=', '+', '€', '£', '₂', '²', '³', '&'):
        if sym in bare:
            found.append(('symbole', sym))
    for raw in REGNAL:
        if re.search(r'(?<![\w-])' + re.escape(raw) + r'(?=[\s.,;:!?\'’”)]|$)', bare):
            found.append(('romain', raw))
    for m in re.finditer(r'\b[IVX]{2,}\b', bare):
        found.append(('romain', m.group(0)))
    return found


def warnings(bare):
    """Non-ASCII words left un-respelled: foreign names the lexicon missed."""
    return sorted({m.group(0) for m in re.finditer(r'\w*[^\x00-\x7F’“”—–…]\w*', bare)})
