"""German reading rules.

The hard part of German narration is that ordinals decline. "19." is
*neunzehnte*, *neunzehnten*, *neunzehntes* or *neunzehnter* depending on the
case the preceding article forces and on the gender of the noun that follows —
"das 19. Jahrhundert" but "im 19. Jahrhundert" and "des 19. Jahrhunderts". A
wrong ending is immediately audible, so the rules below read the article on the
left and the noun on the right before choosing.

The corpus holds 317 such ordinals in narrated text, against 120 numbers whose
thousands separator is the same period; telling those two apart is the other
half of the job.
"""

import re

LANG = 'de'
STAR_WORD = 'Stern'
SEE_PREFIXES = ('Siehe', 'Vergleiche')
TAKEAWAY_LEADIN = 'Das sollten Sie aus diesem Kurs behalten.'
DETERMINERS = {'der', 'die', 'das', 'den', 'dem', 'des',
               'ein', 'eine', 'einen', 'einem', 'eines', 'einer'}

CHAPTER_WORDS = ['', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben',
                 'acht', 'neun', 'zehn', 'elf', 'zwölf']
_ORDINAL_HEAD = ['', 'erste', 'zweite', 'dritte', 'vierte', 'fünfte', 'sechste',
                 'siebte', 'achte', 'neunte', 'zehnte', 'elfte', 'zwölfte']


def chapter_label(n):
    return f'Kapitel {CHAPTER_WORDS[n]}.'


def echoes_chapter_number(heading, n):
    """"Kapitel zwei. Zwei tote Brüder" — a pause beats saying two twice."""
    first = re.split(r'[\s,:;.!?]', heading.strip(), 1)[0].lower()
    return n < len(CHAPTER_WORDS) and first in (CHAPTER_WORDS[n], _ORDINAL_HEAD[n])


# --------------------------------------------------------------------------
# Zahlwörter
# --------------------------------------------------------------------------

_E = ['null', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht',
      'neun', 'zehn', 'elf', 'zwölf', 'dreizehn', 'vierzehn', 'fünfzehn',
      'sechzehn', 'siebzehn', 'achtzehn', 'neunzehn']
_Z = {2: 'zwanzig', 3: 'dreißig', 4: 'vierzig', 5: 'fünfzig',
      6: 'sechzig', 7: 'siebzig', 8: 'achtzig', 9: 'neunzig'}


def cardinal(n, attributiv=False):
    """*attributiv* picks "ein" over "eins" — the form used as a multiplier
    ("einhundert") and inside compounds ("einundzwanzig")."""
    if n < 0:
        return 'minus ' + cardinal(-n)
    if n < 20:
        return ('ein' if attributiv else 'eins') if n == 1 else _E[n]
    if n < 100:
        z, u = divmod(n, 10)
        return _Z[z] if u == 0 else f"{'ein' if u == 1 else _E[u]}und{_Z[z]}"
    if n < 1000:
        h, r = divmod(n, 100)
        wort = ('ein' if h == 1 else cardinal(h, True)) + 'hundert'
        return wort if r == 0 else wort + cardinal(r)
    if n < 10 ** 6:
        t, r = divmod(n, 1000)
        wort = ('ein' if t == 1 else cardinal(t, True)) + 'tausend'
        return wort if r == 0 else wort + cardinal(r)
    mio, r = divmod(n, 10 ** 6)
    wort = ('eine Million' if mio == 1 else cardinal(mio, True) + ' Millionen')
    return wort if r == 0 else wort + ' ' + cardinal(r)


def jahr(n):
    """1492 is said in hundreds — "vierzehnhundertzweiundneunzig" — but 2022 is
    not: after two thousand German goes back to the plain cardinal."""
    if 1100 <= n <= 1999:
        h, r = divmod(n, 100)
        wort = cardinal(h, True) + 'hundert'
        return wort if r == 0 else wort + cardinal(r)
    if 1000 <= n <= 1099:
        return 'tausend' + (cardinal(n - 1000) if n > 1000 else '')
    return cardinal(n)


_ORD_UNREGELMASSIG = {1: 'erst', 3: 'dritt', 7: 'siebt', 8: 'acht'}


def ordinal_stamm(n):
    if n in _ORD_UNREGELMASSIG:
        return _ORD_UNREGELMASSIG[n]
    if n < 20:
        return _E[n] + 't'
    return cardinal(n, True) + 'st'


# --------------------------------------------------------------------------
# Genus und Kasus: was die Endung der Ordinalzahl bestimmt
# --------------------------------------------------------------------------

MONATE = ('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August',
          'September', 'Oktober', 'November', 'Dezember')
MONATE_KURZ = ('Jan', 'Feb', 'Mär', 'Apr', 'Jun', 'Jul', 'Aug', 'Sep', 'Sept',
               'Okt', 'Nov', 'Dez')

GENUS = {m: 'm' for m in MONATE + MONATE_KURZ}
GENUS.update({
    'Jahrhundert': 'n', 'Jahrhunderts': 'n', 'Jahrhunderte': 'n',
    'Jahrhunderten': 'n', 'Jh': 'n', 'Jahr': 'n', 'Jahres': 'n', 'Jahre': 'n',
    'Lebensjahr': 'n', 'Massenaussterben': 'n', 'Kapitel': 'n', 'Buch': 'n',
    'Reich': 'n', 'Konzil': 'n', 'Jahrtausend': 'n', 'Jahrzehnt': 'n',
    'Breitengrad': 'm', 'Zusatzartikel': 'm', 'Weltkrieg': 'm', 'Kreuzzug': 'm',
    'Akt': 'm', 'Band': 'm', 'Teil': 'm', 'Stock': 'm', 'Artikel': 'm',
    'Kongress': 'm', 'Parteitag': 'm', 'Satz': 'm',
    'Armee': 'f', 'Sinfonie': 'f', 'Woche': 'f', 'Republik': 'f', 'Klasse': 'f',
    'Auflage': 'f', 'Dynastie': 'f', 'Symphonie': 'f', 'Kolonne': 'f',
})

# Artikel, die den Kasus eindeutig festlegen. Blosse Präpositionen stehen hier
# absichtlich NICHT: "diese Zahl liegt unter 2. Zweite Entwicklung" ist ein
# Satzende, keine Ordinalzahl, und "unter" darf sie nicht dazu machen.
_ENDUNG_EN = {'im', 'am', 'dem', 'zum', 'vom', 'beim', 'zur', 'ins', 'des',
              'eines', 'einem', 'einer', 'den', 'ihrem', 'ihren', 'ihrer',
              'seinem', 'seinen', 'seiner', 'unserem', 'diesem', 'diesen',
              'dieses', 'jedem', 'jeden', 'unseres'}
_ENDUNG_E = {'das', 'die', 'ein', 'eine', 'diese', 'jene', 'jede'}
_GEMISCHT = {'der', 'dieser', 'jener'}
ARTIKEL = _ENDUNG_EN | _ENDUNG_E | _GEMISCHT


def _endung(artikel, genus):
    if artikel in _ENDUNG_EN:
        return 'en'
    if artikel in _ENDUNG_E:
        return 'e'
    if artikel in _GEMISCHT:
        # "der 14. Juli" ist Nominativ, "ab der 11. Woche" Dativ: nur das Genus
        # des Substantivs trennt die beiden.
        return 'e' if genus != 'f' else 'en'
    return {'n': 'es', 'm': 'er', 'f': 'e'}[genus or 'n']   # starke Endung


def _artikel_davor(t, i):
    """Der Artikel steht bis zu zwei Wörter vor der Zahl ("des italienischen
    16. Jahrhunderts"), aber nie jenseits eines Substantivs."""
    for wort in reversed(re.findall(r"[\wäöüßÄÖÜ]+", t[max(0, i - 60):i])[-3:]):
        if wort.lower() in ARTIKEL:
            return wort.lower()
        if wort[:1].isupper():
            return None
    return None


_UBERSPRINGEN = re.compile(r'(?:\d{1,3}\.|bis|und|auf|dem|den|der|das|die|zum|zur)'
                           r'\s*[-–]?\s*')


def _nomen_danach(t, i):
    rest = re.sub(r'^[\s*_"„“»«\-–]+', '', t[i:i + 90])
    while True:
        m = _UBERSPRINGEN.match(rest)
        if not m:
            break
        rest = re.sub(r'^[\s*_]+', '', rest[m.end():])
    m = re.match(r'[*_]*([A-ZÄÖÜ][\wäöüß]*)', rest)
    return m.group(1) if m else None


# --------------------------------------------------------------------------
# Regeln
# --------------------------------------------------------------------------

# Abkürzungen zuerst: "Ende 19. Jh." braucht das ausgeschriebene Substantiv,
# damit die Ordinalregel das Genus überhaupt nachschlagen kann.
ABKURZUNGEN = [
    (re.compile(r'\bv\.\s?Chr\.'), 'vor Christus'),
    (re.compile(r'\bn\.\s?Chr\.'), 'nach Christus'),
    (re.compile(r'\bJh\.'), 'Jahrhundert'),
    (re.compile(r'\bNr\.'), 'Nummer'),
    (re.compile(r'\bSt\.\s'), 'Sankt '),
    (re.compile(r'\bz\.\s?B\.'), 'zum Beispiel'),
    (re.compile(r'\bd\.\s?h\.'), 'das heißt'),
    (re.compile(r'\bu\.\s?a\.'), 'unter anderem'),
    (re.compile(r'\bbzw\.'), 'beziehungsweise'),
    (re.compile(r'\busw\.'), 'und so weiter'),
    (re.compile(r'\bca\.'), 'circa'),
    (re.compile(r'\bMio\.'), 'Millionen'),
    (re.compile(r'\bMrd\.'), 'Milliarden'),
]


# Feste Wendungen, die keine Regel zerlegen soll.
BEZEICHNER = [
    ('E=mc²', 'E gleich m c Quadrat'),
    ('E = mc²', 'E gleich m c Quadrat'),
    ('R&B', 'Rhythm and Blues'),
    ('rock\'n\'roll', 'Rock and Roll'),
    ('Rock\'n\'Roll', 'Rock and Roll'),
]


def fix_bezeichner(t, cid, log):
    for vor, nach in BEZEICHNER:
        if vor in t:
            for _ in range(t.count(vor)):
                log(cid, 'Bezeichner', vor, nach)
            t = t.replace(vor, nach)
    return t


def fix_abkurzungen(t, cid, log):
    for rx, wort in ABKURZUNGEN:
        def rep(m, w=wort):
            log(cid, 'Abkürzung', m.group(0), w)
            return w
        t = rx.sub(rep, t)
    return t


# Herrschernamen werden aufgezählt, nicht erraten: "Franklin D. Roosevelt" und
# "Arthur C. Clarke" tragen gültige römische Ziffern als Initiale.
HERRSCHER = {
    'Abdülhamid', 'Alarich', 'Alexander', 'Alexios', 'Clemens', 'Elisabeth',
    'Franz', 'Friedrich', 'Heinrich', 'Innozenz', 'Iwan', 'Johannes', 'Joseph',
    'Julius', 'Karl', 'Katharina', 'Konstantin', 'Leo', 'Ludwig', 'Maria',
    'Mehmed', 'Moctezuma', 'Napoleon', 'Nikolaus', 'Otto', 'Peter', 'Philipp',
    'Philippe', 'Pius', 'Urban', 'Viktoria', 'Wilhelm',
}
# Nach der Ziffer trägt der Punkt meist auch das Satzende ("Elisabeth I. Die
# Stücke"). Nur diese Namensteile setzen den Namen fort.
NAMENSZUSATZ = {'August', 'Komnenos', 'Palaiologos', 'Barbarossa', 'Plantagenet',
                'der', 'von', 'zu'}
HERRSCHERIN = {'Elisabeth', 'Katharina', 'Maria', 'Viktoria', 'Anna', 'Isabella'}

ROMISCH = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def romisch_zu_zahl(s):
    total = 0
    for i, c in enumerate(s):
        v = ROMISCH[c]
        total += -v if i + 1 < len(s) and v < ROMISCH[s[i + 1]] else v
    return total


HERRSCHER_RX = re.compile(
    r'(?P<vor>(?:\b[a-zäöü]+\s+)?)(?P<name>[A-ZÄÖÜ][\wäöüß]+)\s+'
    r'(?P<rom>[IVXLCDM]{1,5})(?P<punkt>\.)?(?!\w)')

# Präpositionen, die den Kasus des nachgestellten "der Zweite" bestimmen.
_DATIV_PRAP = {'unter', 'von', 'vom', 'mit', 'bei', 'nach', 'seit', 'zu', 'zum',
               'an', 'auf', 'in', 'aus', 'gegenüber', 'ausser', 'außer'}
_AKKUSATIV_PRAP = {'durch', 'für', 'gegen', 'ohne', 'um', 'wider'}

# Steht der Herrscher als Objekt eines Verbs, entscheidet kein Wort davor über
# den Kasus, sondern der Satzbau. Das Korpus enthält 43 Herrscherziffern; diese
# sechs Stellen sind die, an denen der Nominativ falsch wäre.
KASUS_AUSNAHMEN = [
    (re.compile(r'weckt man Ludwig'), 'akk'),
    (re.compile(r'ruft man Heinrich'), 'akk'),
    (re.compile(r'lässt Karl VII\.? krönen'), 'akk'),
    (re.compile(r'die Karl X\.? stürzt'), 'akk'),
    (re.compile(r'entgleitet Ludwig'), 'dat'),
]


def fix_herrscher(t, cid, log):
    def rep(m):
        name, rom = m.group('name'), m.group('rom')
        # Erst den ganzen Namen prüfen: "Nikolaus" und "Alexios" enden auf s,
        # ohne Genitiv zu sein. Nur wenn das misslingt, ist das s ein Genitiv-s.
        if name in HERRSCHER:
            basis, genitiv = name, False
        elif name.endswith('s') and name[:-1] in HERRSCHER:
            basis, genitiv = name[:-1], True
        else:
            return m.group(0)              # Initiale, kein Herrschername
        stamm_name = name
        weiblich = basis in HERRSCHERIN
        stamm = ordinal_stamm(romisch_zu_zahl(rom))
        vor = m.group('vor').strip().lower()
        gross = stamm[0].upper() + stamm[1:]   # "Ludwig der Sechzehnte"
        umgebung = t[max(0, m.start() - 40):m.end() + 40]
        sonderfall = next((k for rx, k in KASUS_AUSNAHMEN if rx.search(umgebung)), None)
        if genitiv:                        # "Urbans II. Aufruf"
            gelenk = ('der ' if weiblich else 'des ') + gross + 'en'
        elif sonderfall == 'akk' or vor in _AKKUSATIV_PRAP:
            gelenk = ('die ' + gross + 'e') if weiblich else ('den ' + gross + 'en')
        elif sonderfall == 'dat' or vor in _DATIV_PRAP:
            gelenk = ('der ' if weiblich else 'dem ') + gross + 'en'
        else:
            gelenk = ('die ' if weiblich else 'der ') + gross + 'e'
        out = f"{m.group('vor')}{stamm_name} {gelenk}"
        folgt = re.match(r'[*_"„]*([A-ZÄÖÜ][\wäöüß]*)', t[m.end():m.end() + 40].lstrip())
        # Ein Genitiv hängt am folgenden Substantiv; dort endet kein Satz. Und
        # ohne Punkt in der Quelle gab es nie einen zu erhalten.
        if m.group('punkt') and folgt and not genitiv and folgt.group(1) not in NAMENSZUSATZ:
            out += '.'                     # der Punkt schloss auch den Satz
        log(cid, 'Herrscher', m.group(0), out.strip())
        return out
    return HERRSCHER_RX.sub(rep, t)


INITIALE = re.compile(r'\b([A-ZÄÖÜ])\.(?=\s*[A-ZÄÖÜ])')


def fix_initialen(t, cid, log):
    """Der Punkt einer Initiale ist kein Satzende: "Franklin D. Roosevelt" darf
    die Stimme nicht absetzen lassen."""
    def rep(m):
        # Folgt der Großbuchstabe ohne Leerzeichen, trennt ein Bindestrich die
        # Buchstaben: sonst wird aus "J.R.R." ein Wort.
        out = m.group(1) + ('-' if m.end() < len(t) and t[m.end()] != ' ' else '')
        log(cid, 'Initiale', m.group(0), out)
        return out
    return INITIALE.sub(rep, t)


UHRZEIT = re.compile(r'(?<![\d.,])(?P<h>\d{1,2})\.(?P<m>\d{2})\s?Uhr\b')
ORD_BEREICH = re.compile(r'(?<![\d.,])(?P<a>\d{1,3})\.\s*[-–]\s*(?P<b>\d{1,3})\.(?!\d)')
ORDINAL = re.compile(r'(?<![\d.,])(?P<n>\d{1,3})\.(?!\d)')


def _ist_ordinal(artikel, nomen):
    return artikel is not None or (nomen in GENUS)


def fix_uhrzeit(t, cid, log):
    """« 8.46 Uhr » ist eine Uhrzeit, kein Tausenderpunkt und keine
    Ordinalzahl: "acht Uhr sechsundvierzig"."""
    def rep(m):
        out = f"{cardinal(int(m.group('h')))} Uhr {cardinal(int(m.group('m')))}"
        log(cid, 'Uhrzeit', m.group(0), out)
        return out
    return UHRZEIT.sub(rep, t)


def fix_ordinal_bereich(t, cid, log):
    def rep(m):
        artikel = _artikel_davor(t, m.start())
        nomen = _nomen_danach(t, m.end())
        if not _ist_ordinal(artikel, nomen):
            return m.group(0)
        e = _endung(artikel, GENUS.get(nomen))
        out = (ordinal_stamm(int(m.group('a'))) + e + ' bis '
               + ordinal_stamm(int(m.group('b'))) + e)
        log(cid, 'Ordinalzahl', m.group(0), out)
        return out
    return ORD_BEREICH.sub(rep, t)


def fix_ordinal(t, cid, log):
    def rep(m):
        artikel = _artikel_davor(t, m.start())
        nomen = _nomen_danach(t, m.end())
        if not _ist_ordinal(artikel, nomen):
            return m.group(0)   # "liegt diese Zahl unter 2." — Satzende
        out = ordinal_stamm(int(m.group('n'))) + _endung(artikel, GENUS.get(nomen))
        log(cid, 'Ordinalzahl', m.group(0), out)
        return out
    return ORDINAL.sub(rep, t)


ZAHL = r'\d{1,3}(?:\.\d{3})+|\d+(?:,\d+)?'

EINHEITEN = [('km/h', 'Kilometer pro Stunde'), ('km²', 'Quadratkilometer'),
             ('m²', 'Quadratmeter'), ('°C', 'Grad Celsius'),
             ('°F', 'Grad Fahrenheit'), ('km', 'Kilometer'),
             ('cm', 'Zentimeter'), ('mm', 'Millimeter'), ('kg', 'Kilogramm'),
             ('°', 'Grad')]
_EINHEIT_ALT = '|'.join(re.escape(u) for u, _ in EINHEITEN)
EINHEIT = re.compile(r'(?P<vz>[-–+~≈]?)(?P<n>' + ZAHL + r')\s?(?P<u>'
                     + _EINHEIT_ALT + r')(?![\w²])')
EINHEIT_SKALA = re.compile(r'(?P<skala>\b(?:Millionen|Million|Milliarden|Milliarde|'
                           r'Billionen|Tausend)\s)(?P<u>' + _EINHEIT_ALT + r')(?![\w²])')
PROZENT = re.compile(r'(?P<n>' + ZAHL + r')\s?%')
VORZEICHEN = {'-': 'minus ', '–': 'minus ', '+': 'plus ', '~': 'etwa ', '≈': 'etwa '}


def _zahlwort(s, attributiv=False):
    if ',' in s:
        ganz, bruch = s.split(',', 1)
        return (cardinal(int(ganz.replace('.', '')))
                + ' Komma ' + ' '.join(_E[int(c)] for c in bruch))
    return cardinal(int(s.replace('.', '')), attributiv)


def fix_einheiten(t, cid, log):
    def rep(m):
        wort = next(w for u, w in EINHEITEN if u == m.group('u'))
        out = (VORZEICHEN.get(m.group('vz'), '') + _zahlwort(m.group('n'))
               + ' ' + wort)
        log(cid, 'Einheit', m.group(0), out)
        return out
    return EINHEIT.sub(rep, t)


def fix_einheit_skala(t, cid, log):
    """Das Skalenwort trennt Zahl und Einheit: "1,1 Millionen km²"."""
    def rep(m):
        wort = next(w for u, w in EINHEITEN if u == m.group('u'))
        log(cid, 'Einheit', m.group(0), m.group('skala') + wort)
        return m.group('skala') + wort
    return EINHEIT_SKALA.sub(rep, t)


def fix_prozent(t, cid, log):
    def rep(m):
        n = m.group('n')
        # "ein Prozent", nicht "eins Prozent"
        out = _zahlwort(n, attributiv=(n == '1')) + ' Prozent'
        log(cid, 'Prozent', m.group(0), out)
        return out
    return PROZENT.sub(rep, t)


JAHR_BEREICH = re.compile(r'(?<![\d.,])(?P<a>\d{3,4})\s?[-–]\s?(?P<b>\d{3,4})(?![\d.,])')


def fix_jahr_bereich(t, cid, log):
    def rep(m):
        out = f"{jahr(int(m.group('a')))} bis {jahr(int(m.group('b')))}"
        log(cid, 'Zeitraum', m.group(0), out)
        return out
    return JAHR_BEREICH.sub(rep, t)


TAUSENDER = re.compile(r'(?<![\d.,])\d{1,3}(?:\.\d{3})+(?![\d.,])')
DEZIMAL = re.compile(r'(?<![\d.,])\d+,\d+(?!\d)(?![.,]\d)')
# Der Punkt nach der Zahl darf sie nicht schützen: in "liegt unter 2."
# ist er ein Satzende und die Zwei muss trotzdem ausgeschrieben werden.
GANZZAHL = re.compile(r'(?<![\d.,])\d+(?!\d)(?![.,]\d)')
# Vor einem Substantiv steht "ein", nicht "eins": "auf ein Rohr".
SKALA = re.compile(r'\b(Millionen|Million|Milliarden|Milliarde|Billionen)\b')


def fix_zahlen(t, cid, log):
    def rep_t(m):
        out = _zahlwort(m.group(0))
        log(cid, 'Zahl', m.group(0), out)
        return out
    t = TAUSENDER.sub(rep_t, t)
    t = DEZIMAL.sub(rep_t, t)

    def rep_g(m):
        n = int(m.group(0))
        out = jahr(n) if 1000 <= n <= 2099 else cardinal(n)
        log(cid, 'Zahl', m.group(0), out)
        return out
    return GANZZAHL.sub(rep_g, t)


SYMBOLE = [('&', ' und '), ('→', ' ergibt '), ('=', ' gleich '), ('+', ' plus '),
           ('€', ' Euro'), ('$', ' Dollar'), ('£', ' Pfund'), ('/', '-')]


def fix_symbole(t, cid, log):
    for zeichen, wort in SYMBOLE:
        if zeichen in t:
            for _ in range(t.count(zeichen)):
                log(cid, 'Symbol', zeichen, wort.strip() or '-')
            t = t.replace(zeichen, wort)
    return re.sub(r'  +', ' ', t)


SOURCE_FIXES = {
    # Glossar-Slugs, die nie eine Anzeigeform bekommen haben.
    'course_153_la_creation_d_adam_michel_ange': [
        ('[[dissection_anatomique]]', 'anatomischen Sektion'),
        ('[[manière_moderne]]', 'maniera moderna'),
    ],
    # Das Stichwort bündelt zwei Begriffe; eingefügt macht es den Satz falsch.
    'course_214_la_crise_de_l_etat_providence': [
        ('auf 1 Rentner', 'auf einen Rentner'),
    ],
}


def normalize(t, cid, log):
    t = fix_bezeichner(t, cid, log)
    t = fix_abkurzungen(t, cid, log)
    t = fix_herrscher(t, cid, log)
    t = fix_initialen(t, cid, log)
    t = fix_uhrzeit(t, cid, log)
    t = fix_ordinal_bereich(t, cid, log)
    t = fix_ordinal(t, cid, log)
    t = fix_einheiten(t, cid, log)
    t = fix_einheit_skala(t, cid, log)
    t = fix_prozent(t, cid, log)
    t = fix_jahr_bereich(t, cid, log)
    t = fix_zahlen(t, cid, log)
    return fix_symbole(t, cid, log)


# Eine deutsche Stimme liest deutsche Namen richtig; umgeschrieben würde sie
# schlechter. Nur Abkürzungen, die buchstabiert werden müssen, stehen hier.
AUSSPRACHE = [
    ('UdSSR', 'U-d-S-S-R'), ('USA', 'U-S-A'), ('BIP', 'B-I-P'),
    ('DDR', 'D-D-R'), ('BRD', 'B-R-D'), ('EZB', 'E-Z-B'),
    ('DSGVO', 'D-S-G-V-O'), ('KI', 'K-I'), ('NGO', 'N-G-O'),
]


def respell(t, cid, log):
    for vor, nach in AUSSPRACHE:
        for m in re.finditer(r'\b' + re.escape(vor) + r'\b', t):
            log(cid, 'Aussprache', m.group(0), nach)
        t = re.sub(r'\b' + re.escape(vor) + r'\b', nach, t)
    return t


# Buchstabenfolgen, die zufällig wie römische Zahlen aussehen.
KEINE_ZAHL = {'MC', 'CD', 'DVD', 'LP', 'MIX', 'DIV', 'CIV'}


def extra_checks(bare):
    found = []
    for zeichen in ('%', '°', '&', '→', '=', '€', '$', '£', '²'):
        if zeichen in bare:
            found.append(('Symbol', zeichen))
    for m in re.finditer(r'\b[IVXLCDM]{2,}\b', bare):
        if m.group(0) not in KEINE_ZAHL:
            found.append(('römische Zahl', m.group(0)))
    return found


QUOTES = {
    'course_100_les_fleurs_du_mal_baudelaire': {'attribution':
        'Das sind die ersten Verse von Correspondances, von Charles Baudelaire.'},
    'course_101_1984_george_orwell': {'attribution':
        'So lauten die drei Parolen der Partei, in neunzehnhundertvierundachtzig '
        'von George Orwell.'},
    'course_102_la_ferme_des_animaux_george_orwell': {'attribution':
        'So schreiben die Schweine das Gebot um, in Farm der Tiere von George Orwell.'},
    'course_103_hamlet_shakespeare': {'attribution':
        'So spricht Hamlet, im dritten Akt, Szene eins, bei William Shakespeare.'},
    'course_104_romeo_et_juliette_shakespeare': {'attribution':
        'Das sagt Julia, im zweiten Akt, Szene zwei von Romeo und Julia.'},
    'course_105_le_meilleur_des_mondes_aldous_huxley': {'attribution':
        'So spricht der Wilde, in Schöne neue Welt von Aldous Huxley.'},
    'course_106_frankenstein_mary_shelley': {'attribution':
        'Das sagt die Kreatur, in Frankenstein von Mary Shelley.'},
    'course_108_le_proces_kafka': {'attribution':
        'Das ist der erste Satz des Prozesses, von Franz Kafka.'},
    'course_109_don_quichotte_cervantes': {'attribution':
        'So schreibt Miguel de Cervantes im Don Quijote.'},
    'course_112_le_grand_gatsby_fitzgerald': {'attribution':
        'Das sind die Schlusszeilen des Großen Gatsby, von F. Scott Fitzgerald.'},
    'course_114_fahrenheit_451_bradbury': {'attribution':
        'So sprechen die Büchermenschen, in Fahrenheit vierhunderteinundfünfzig '
        'von Ray Bradbury.'},
    'course_117_le_maitre_et_marguerite_boulgakov': {'attribution':
        'Das sagt Woland, in Der Meister und Margarita von Michail Bulgakow.'},
    'course_119_le_petit_prince_saint_exupery': {'attribution':
        'So verrät der Fuchs sein Geheimnis, in Der kleine Prinz von '
        'Antoine de Saint-Exupéry.'},
    'course_91_les_miserables_victor_hugo': {'attribution':
        'So spricht Bischof Myriel zu Jean Valjean, in Die Elenden von Victor Hugo.'},
    'course_94_candide_voltaire': {'attribution':
        'Das sagt der Sklave von Surinam, in Candide von Voltaire.'},
    'course_96_l_etranger_camus': {'attribution':
        'Das ist der erste Satz des Fremden, von Albert Camus.'},
    'course_97_le_mythe_de_sisyphe_camus': {'attribution':
        'Das ist der Schlusssatz des Mythos des Sisyphos, von Albert Camus.'},
    'course_98_a_la_recherche_du_temps_perdu_proust': {'attribution':
        'So beschreibt Marcel Proust die Madeleine, in In Swanns Welt.'},
    'course_99_le_pere_goriot_balzac': {'attribution':
        'Das ist Rastignacs Herausforderung an Paris, am Ende von Vater Goriot '
        'von Honoré de Balzac.'},
}
