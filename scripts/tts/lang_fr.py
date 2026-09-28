"""French reading rules for the ElevenLabs narration.

French reads years as cardinals ("mille huit cent soixante-six"), so one number
speller serves years and quantities alike — the opposite of English.
"""

from __future__ import annotations

import re

LANG = 'fr'
STAR_WORD = 'étoile'
SEE_PREFIXES = ('Voir',)
TAKEAWAY_LEADIN = "Voici ce qu'il faut retenir de ce cours."

CHAPTER_WORDS = {1: 'un', 2: 'deux', 3: 'trois', 4: 'quatre', 5: 'cinq'}


def chapter_label(n):
    return f'Chapitre {CHAPTER_WORDS[n]}.'


def echoes_chapter_number(heading, n):
    first = re.split(r'[\s,:;.!?]', heading.strip(), 1)[0].lower()
    return first in (CHAPTER_WORDS[n], 'une' if n == 1 else None)


# Exact replacements on the source text, for defects no rule should guess at.
DETERMINERS = {'le', 'la', 'les', 'un', 'une', 'des', 'du', 'au', 'aux', 'ce', 'cet', 'cette', 'ces'}

SOURCE_FIXES = {
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_8_la_chute_de_constantinople_1453': [
        ("du [[le Droit byzantin et l'héritage romain]]", "du droit byzantin et de l'héritage romain"),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_229_l_ue_comment_ca_marche_vraiment': [
        ("[[La Commission européenne et le monopole d'initiative législative]]", "monopole d'initiative législative"),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_168_sisyphe_punition_eternelle': [
        ('[[Absurde de Camus et Sisyphe]]', 'Absurde'),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_111_to_kill_a_mockingbird_harper_lee': [
        ('[[lois Jim Crow et le Sud ségrégationniste]]', 'lois Jim Crow'),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_91_les_miserables_victor_hugo': [
        ('**[[Bagne et système pénal au XIXe siècle]]**', '**bagne**'),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_44_pourquoi_l_eau_de_mer_est_elle_salee': [
        ("[[cycle hydrologique et de l'accumulation des sels]]", "cycle hydrologique et l'accumulation des sels"),
    ],
    # L'apposition entre parenthèses s'entend comme un sixième item
    # de l'énumération, alors que la phrase en annonce cinq.
    'course_237_les_gafam_puissance_et_derives': [
        ("Meta (l'ancien Facebook)", 'Meta, anciennement Facebook'),
    ],
    # The headword glues two glossary entries; spliced into the sentence it
    # makes the captivity the place he was wounded.
    'course_109_don_quichotte_cervantes': [
        ('**[[Bataille de Lépante (1571) et captivité de Cervantès]]**', '**bataille de Lépante** en 1571'),
    ],
    'course_128_l_expressionnisme_munch_et_le_cri': [
        ("l'[[Éruption du Krakatoa (1883) et le ciel rouge]]", "l'éruption du Krakatoa en 1883"),
    ],
    # Glossary slugs that were never given a display form.
    'course_153_la_creation_d_adam_michel_ange': [
        ('[[dissection_anatomique]]', 'dissection anatomique'),
        ('[[manière_moderne]]', 'manière moderne'),
    ],
}

# 19 quotes, keyed by course. Written by hand because the attribution field
# always says "Author, Work" while most of these lines belong to a character:
# « La guerre, c'est la paix » is the Party's slogan, not Orwell's opinion.
QUOTES = {
    'course_298_esope_a_t_il_vraiment_existe': {'attribution':
        "C'est le commandement réécrit par les cochons, dans La Ferme des animaux, la fable que George Orwell publie en mille neuf cent quarante-cinq."},
    'course_100_les_fleurs_du_mal_baudelaire': {'attribution':
        "Ce sont les premiers vers de Correspondances, de Charles Baudelaire."},
    'course_101_1984_george_orwell': {'attribution':
        "Ce sont les trois slogans du Parti, dans mille neuf cent quatre-vingt-quatre de George Orwell."},
    'course_102_la_ferme_des_animaux_george_orwell': {'attribution':
        "C'est le commandement réécrit par les cochons, dans La Ferme des animaux de George Orwell."},
    'course_103_hamlet_shakespeare': {'attribution':
        "Ainsi parle Hamlet, à l'acte trois, scène un de la pièce de William Shakespeare."},
    'course_104_romeo_et_juliette_shakespeare': {'attribution':
        "C'est Juliette qui parle, à l'acte deux, scène deux de Roméo et Juliette."},
    'course_105_le_meilleur_des_mondes_aldous_huxley': {'attribution':
        "Ainsi parle le Sauvage, dans Le Meilleur des Mondes d'Aldous Huxley."},
    'course_106_frankenstein_mary_shelley': {'attribution':
        "C'est la créature qui parle, dans Frankenstein de Mary Shelley."},
    'course_108_le_proces_kafka': {'attribution':
        "Ce sont les premiers mots du Procès, de Franz Kafka."},
    # Don Quixote says this to Don Diego, it is not Cervantes' own aside.
    'course_109_don_quichotte_cervantes': {'attribution':
        "Ainsi parle Don Quichotte, dans le roman de Miguel de Cervantès."},
    'course_112_le_grand_gatsby_fitzgerald': {'attribution':
        "C'est ainsi que Francis Scott Fitzgerald referme Le Grand Gatsby."},
    # Not a line from the novel: read as a paraphrase, never as a quote.
    'course_114_fahrenheit_451_bradbury': {'paraphrase':
        "Dans les dernières pages du roman, les exilés que rejoint Montag ont chacun appris un livre "
        "par cœur. Le feu les a touchés, mais à travers eux, les livres survivent."},
    'course_117_le_maitre_et_marguerite_boulgakov': {'attribution':
        "C'est Woland qui le dit, dans Le Maître et Marguerite de Mikhaïl Boulgakov."},
    'course_119_le_petit_prince_saint_exupery': {'attribution':
        "C'est le renard qui livre son secret, dans Le Petit Prince d'Antoine de Saint-Exupéry."},
    'course_91_les_miserables_victor_hugo': {'attribution':
        "Ainsi parle Monseigneur Bienvenu, dans Les Misérables de Victor Hugo."},
    'course_94_candide_voltaire': {'attribution':
        "Ce sont les mots de l'esclave de Surinam, dans Candide de Voltaire."},
    'course_96_l_etranger_camus': {'attribution':
        "Ce sont les premiers mots de L'Étranger, d'Albert Camus."},
    'course_97_le_mythe_de_sisyphe_camus': {'attribution':
        "C'est sur cette phrase qu'Albert Camus referme Le Mythe de Sisyphe."},
    'course_98_a_la_recherche_du_temps_perdu_proust': {'attribution':
        "Ainsi parle le narrateur, dans Du côté de chez Swann de Marcel Proust."},
    'course_99_le_pere_goriot_balzac': {'attribution':
        "C'est le défi que lance Rastignac à Paris, à la dernière page du Père Goriot d'Honoré de Balzac."},
}


# ------------------------------------------------- nombres en toutes lettres
# Orthographe traditionnelle. « vingt » et « cent » prennent un s quand ils sont
# multipliés ET non suivis d'un autre adjectif numéral. « mille » en est un et
# fait tomber le s ; « million » et « milliard » sont des noms et le laissent.
# D'où « quatre-vingt mille » mais « quatre-vingts millions ».

U = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix',
     'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize']
DIZ = {20: 'vingt', 30: 'trente', 40: 'quarante', 50: 'cinquante', 60: 'soixante'}


def sous_cent(n, final=True):
    if n < 17:
        return U[n]
    if n < 20:
        return 'dix-' + U[n - 10]
    if n < 70:
        d, r = (n // 10) * 10, n % 10
        if r == 0:
            return DIZ[d]
        if r == 1:
            return DIZ[d] + ' et un'
        return DIZ[d] + '-' + U[r]
    if n < 80:
        r = n - 60
        return 'soixante et onze' if r == 11 else 'soixante-' + sous_cent(r)
    r = n - 80
    if r == 0:
        return 'quatre-vingts' if final else 'quatre-vingt'
    return 'quatre-vingt-' + sous_cent(r)


def sous_mille(n, final=True):
    if n < 100:
        return sous_cent(n, final)
    c, r = n // 100, n % 100
    tete = 'cent' if c == 1 else U[c] + ' cent'
    if r == 0:
        return tete + ('s' if c > 1 and final else '')
    return tete + ' ' + sous_cent(r, final)


ECHELLES = [(10 ** 9, 'milliard'), (10 ** 6, 'million'), (10 ** 3, 'mille')]


def en_lettres(n):
    if n == 0:
        return 'zéro'
    if n < 0:
        return 'moins ' + en_lettres(-n)
    parts, reste = [], n
    for val, nom in ECHELLES:
        q, reste = divmod(reste, val)
        if not q:
            continue
        if nom == 'mille':
            parts.append('mille' if q == 1 else sous_mille(q, False) + ' mille')
        else:
            parts.append(sous_mille(q) + ' ' + nom + ('s' if q > 1 else ''))
    if reste:
        parts.append(sous_mille(reste))
    return ' '.join(parts)


def decimal_en_lettres(entier, frac):
    t = en_lettres(int(entier)) + ' virgule '
    if len(frac) == 1:
        return t + U[int(frac)]
    if len(frac) == 2 and frac[0] != '0':
        return t + en_lettres(int(frac))
    return t + ' '.join(U[int(c)] for c in frac)


def ordinal_fr(n, feminin=False):
    if n == 1:
        return 'première' if feminin else 'premier'
    c = en_lettres(n)
    # l'« s » ne tombe que s'il marque l'accord : dans « trois » il est au mot
    if c.endswith('vingts') or c.endswith('cents'):
        c = c[:-1]
    if c.endswith('e'):
        c = c[:-1]
    elif c.endswith('q'):
        c += 'u'
    elif c.endswith('f'):
        c = c[:-1] + 'v'
    return c + 'ième'


# ------------------------------------------------------------------- romains
ROMAN_VAL = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
ROMAN_WORD = {1: 'premier', 2: 'deux', 3: 'trois', 4: 'quatre', 5: 'cinq', 6: 'six', 7: 'sept',
              8: 'huit', 9: 'neuf', 10: 'dix', 11: 'onze', 12: 'douze', 13: 'treize', 14: 'quatorze',
              15: 'quinze', 16: 'seize', 17: 'dix-sept', 18: 'dix-huit',
              19: 'dix-neuf', 20: 'vingt', 21: 'vingt et un', 22: 'vingt-deux',
              23: 'vingt-trois', 24: 'vingt-quatre'}


def roman_to_int(r):
    tot, prev = 0, 0
    for ch in reversed(r):
        v = ROMAN_VAL[ch]
        tot = tot - v if v < prev else tot + v
        prev = max(prev, v)
    return tot


# Le motif canonique accepte la chaîne vide : sans la sentinelle, « ans »,
# « acte » ou « partie » suivis de n'importe quel mot déclenchent la règle
# et collent « zéro » au mot suivant.
_R = r'(?=[IVXLCDM])M{0,3}(?:CM|CD|D?C{0,3})(?:XC|XL|L?X{0,3})(?:IX|IV|V?I{0,3})'

# « XXe siècle », « François Ier », « Élisabeth Ire ». Une lettre seule n'est un
# numéral que si le contexte le dit : « Ce », « De », « Le » ont exactement la
# forme romain + suffixe.
NOMS_ORDINAUX = {'siècle', 'siècles', 'république', 'millénaire', 'millénaires', 'reich',
                 'arrondissement', 'dynastie', 'croisade', 'concile', 'symphonie', 'législature',
                 'et', 'au', 'ou'}
ROMAIN_ORD = re.compile(r'(?P<avant>[A-ZÀ-Þ][\wÀ-ÿ’\'-]*\s+)?'
                        r'\b(?P<rom>' + _R + r')(?P<suf>er|re|ème|e)\b'
                        r'(?P<apres>\s+[A-Za-zÀ-ÿ’\'-]+)?')

# « an I » se dit « an un » : après un nom commun, cardinal nu.
NOMS_CARDINAUX = ('an', 'ans', 'article', 'chapitre', 'tome', 'acte', 'scène', 'livre', 'partie',
                  'volume', 'canto', 'chant')
ROMAIN_CARD = re.compile(r'\b(?P<nom>' + '|'.join(NOMS_CARDINAUX) + r')\s+(?P<rom>' + _R + r')\b')

# Souverains et papes : « Louis XIV » -> « Louis quatorze ».
ROMAN_CTX = re.compile(
    r'(?P<lead>(?:\b(?:acte|scène|livre|chapitre|tome|partie|guerre mondiale)\s+)'
    r'|(?:\b[A-ZÀ-Þ][\wÀ-ÿ’\'-]{2,}\s+))'
    r'(?P<rom>[IVXLCDM]{1,6})\b'
)
ROMAN_BLOCK = re.compile(r'rayons?\s+X\b|\b[A-Z]\.\s*$')


def fix_romains_ordinaux(t, cid, log):
    def rep(m):
        rom, suf = m.group('rom'), m.group('suf')
        if not rom:
            return m.group(0)
        avant = m.group('avant') or ''
        apres = (m.group('apres') or '').strip().lower()
        souverain = rom == 'I' and suf in ('er', 're') and avant.strip()
        if len(rom) == 1 and not (apres in NOMS_ORDINAUX or souverain):
            return m.group(0)
        mot = ordinal_fr(roman_to_int(rom), feminin=suf == 're')
        if souverain:
            mot = mot.capitalize()
        log(cid, 'ordinal romain', (avant + rom + suf).strip(), (avant + mot).strip())
        return avant + mot + (m.group('apres') or '')
    return ROMAIN_ORD.sub(rep, t)


def fix_romains_cardinaux(t, cid, log):
    def rep(m):
        # Le motif peut encore matcher à vide juste avant un mot qui commence
        # par une lettre romaine (« livre Voici ») : sans cette garde, « zéro »
        # se colle au mot suivant.
        if not m.group('rom'):
            return m.group(0)
        out = m.group('nom') + ' ' + en_lettres(roman_to_int(m.group('rom')))
        log(cid, 'romain cardinal', m.group(0), out)
        return out
    return ROMAIN_CARD.sub(rep, t)


def fix_romans(t, cid, log):
    def rep(m):
        lead, rom = m.group('lead'), m.group('rom')
        if ROMAN_BLOCK.search(lead) or ROMAN_BLOCK.search(lead + rom) or lead.rstrip().endswith('.'):
            return m.group(0)
        n = roman_to_int(rom)
        if n not in ROMAN_WORD:
            return m.group(0)
        w = ROMAN_WORD[n]
        if w == 'premier' and not lead[0].isupper():
            w = 'un'
        log(cid, 'romain', m.group(0).strip(), (lead + w).strip())
        return lead + w
    return ROMAN_CTX.sub(rep, t)


# ------------------------------------------------------------------- nombres
RANGE = re.compile(r'\b(?P<a>1\d{3})\s*[-–]\s*(?P<b>\d{2,4})\b')
# Le lookahead refusait une virgule après la borne : or unparenthesize en
# produit une (« (610-632) » devient « , 610-632, »), et la plage se lisait
# alors comme un seul nombre à rallonge.
RANGE_ANY = re.compile(r'(?<![\d,])(?P<a>\d+)\s*[-–]\s*(?P<b>\d+)(?!\d)')


# « En 1936-1937 » ne devient pas « En de mille... » : la préposition qui
# précède commande déjà, et c'est « et » qu'il faut alors, pas « de ... à ».
PREP_ET = re.compile(r'\b(?:[Ee]n|[Vv]ers|[Ee]ntre|années)\s+$')
PREP_A = re.compile(r"\b(?:[Dd]e|[Dd]epuis|[Dd]ès|[Dd]u|jusqu'en)\s+$")


def fix_ranges(t, cid, log):
    def rep(m):
        a, b = m.group('a'), m.group('b')
        if len(b) == 2:
            b = a[:2] + b
        avant = t[max(0, m.start() - 24):m.start()]
        if PREP_ET.search(avant):
            out = f'{a} et {b}'
        elif PREP_A.search(avant):
            out = f'{a} à {b}'
        else:
            out = f'de {a} à {b}'
        log(cid, 'plage', m.group(0), out)
        return out
    t = RANGE.sub(rep, t)

    def rep_any(m):
        out = f"{m.group('a')} à {m.group('b')}"
        log(cid, 'plage', m.group(0), out)
        return out
    return RANGE_ANY.sub(rep_any, t)


ORDINAL = re.compile(r'\b(?P<n>\d{1,3})(?P<suf>er|re|ère|ème|e)\b')


def fix_ordinals(t, cid, log):
    def rep(m):
        n = int(m.group('n'))
        out = ordinal_fr(n, feminin=m.group('suf') in ('re', 'ère'))
        log(cid, 'ordinal', m.group(0), out)
        return out
    return ORDINAL.sub(rep, t)


PCT = re.compile(r'(?P<n>\d+(?:[.,]\d+)?)\s*%')


def fix_percent(t, cid, log):
    def rep(m):
        out = f"{m.group('n')} pour cent"
        log(cid, 'pourcent', m.group(0), out)
        return out
    return PCT.sub(rep, t)


HEURE = re.compile(r'\b(?P<h>\d{1,2})\s*h\s*(?P<m>\d{2})\b')


def fix_heures(t, cid, log):
    def rep(m):
        h, mn = int(m.group('h')), int(m.group('m'))
        tete = 'une heure' if h == 1 else en_lettres(h) + ' heures'   # « une heure »
        out = tete if mn == 0 else tete + ' ' + en_lettres(mn)
        log(cid, 'heure', m.group(0), out)
        return out
    return HEURE.sub(rep, t)


# « 82°17' sud » : des coordonnées, pas une température.
COORDONNEES = re.compile(r"(?<![\d,])(?P<d>\d{1,3})\s?°\s?(?:(?P<m>\d{1,2})\s?')?")


def fix_coordonnees(t, cid, log):
    def rep(m):
        out = f"{en_lettres(int(m.group('d')))} degrés"
        if m.group('m'):
            out += f" {en_lettres(int(m.group('m')))} minutes"
        log(cid, 'coordonnées', m.group(0), out)
        return out
    return COORDONNEES.sub(rep, t)


UNITES = [
    ('km/h', 'kilomètre par heure', 'kilomètres par heure'),
    ('km/s', 'kilomètre par seconde', 'kilomètres par seconde'),
    ('m/s', 'mètre par seconde', 'mètres par seconde'),
    ('g/l', 'gramme par litre', 'grammes par litre'),
    ('°C', 'degré Celsius', 'degrés Celsius'),
    ('°F', 'degré Fahrenheit', 'degrés Fahrenheit'),
    ('km³', 'kilomètre cube', 'kilomètres cubes'),
    ('km²', 'kilomètre carré', 'kilomètres carrés'),
    ('km', 'kilomètre', 'kilomètres'),
    ('cm', 'centimètre', 'centimètres'),
    ('mm', 'millimètre', 'millimètres'),
    ('kg', 'kilogramme', 'kilogrammes'),
    ('m²', 'mètre carré', 'mètres carrés'),
    ('°', 'degré', 'degrés'),
]
SIGNES = {'-': 'moins ', '+': 'plus ', '~': 'environ ', '≈': 'environ '}
_ALT = '|'.join(re.escape(s) for s, _, _ in UNITES)
UNITE = re.compile(r'(?:(?P<signe>[-+~≈])\s*)?(?P<n>\d[\d   ]*?(?:,\d+)?)\s*(?P<u>'
                   + _ALT + r')(?![\w²])')
UNITE_NUE = re.compile(r'(?<=\bde )(?P<u>' + _ALT + r')(?![\w²])')
NUMERO = re.compile(r'\b[nN]°\s*(?=\d)')


def _valeur(s):
    return float(re.sub(r'[   ]', '', s).replace(',', '.'))


def fix_unites(t, cid, log):
    def num(m):
        log(cid, 'numéro', m.group(0).strip(), 'numéro')
        return 'numéro '
    t = NUMERO.sub(num, t)

    def nue(m):
        plur = next(p for u, _, p in UNITES if u == m.group('u'))
        log(cid, 'unité', m.group('u'), plur)
        return plur
    t = UNITE_NUE.sub(nue, t)

    def rep(m):
        sing, plur = next((s, p) for u, s, p in UNITES if u == m.group('u'))
        # le singulier bascule à deux : « un virgule cinq degré », « deux degrés »
        mot = sing if _valeur(m.group('n')) < 2 else plur
        out = SIGNES.get(m.group('signe') or '', '') + m.group('n').strip() + ' ' + mot
        log(cid, 'unité', m.group(0), out)
        return out
    return UNITE.sub(rep, t)


# Noms qui collent des lettres et des chiffres : sans espace, le chiffre se
# soude au mot (« M87 » donnait « Mquatre-vingt-sept »).
DESIGNATEURS = [
    ('MIC', 'M-I-C'),
    ('Lascaux II', 'Lascaux deux'),

    ('CO₂', 'CO deux'),
    ('E=mc²', 'E égale m c au carré'),
    ('4/4', 'quatre-quatre'),
    ('TCP/IP', 'TCP IP'),
    ('OPEP+', 'OPEP plus'),
    ('R&B', 'rhythm and blues'),   # « R et B » serait faux
    ('Dungeons & Dragons', 'Dungeons and Dragons'),
]


SYMBOLES = [
    (re.compile(r'\s*→\s*'), ' donne '),
    (re.compile(r'\s*&\s*'), ' et '),
    (re.compile(r'(?<=[\w)])\s*\+\s*(?=[\w(])'), ' plus '),
    (re.compile(r'(?<=[\w)])\s*=\s*(?=[\w(])'), ' égale '),
    # « Est/Ouest » : la barre sépare deux mots, elle ne se prononce pas
    (re.compile(r'(?<=[A-Za-zÀ-ÿ])/(?=[A-Za-zÀ-ÿ])'), '-'),
]


def fix_symboles(t, cid, log):
    for pattern, out in SYMBOLES:
        for m in pattern.finditer(t):
            log(cid, 'symbole', m.group(0), out)
        t = pattern.sub(out, t)
    return t


def fix_designateurs(t, cid, log):
    for raw, out in DESIGNATEURS:
        if raw in t:
            t = t.replace(raw, out)
            log(cid, 'désignateur', raw, out)
    t2 = re.sub(r'(?<=[A-Za-z])(?=\d)', ' ', t)
    t2 = re.sub(r'(?<=\d)(?=[A-Za-z])', ' ', t2)
    if t2 != t:
        log(cid, 'désignateur', 'lettres collées aux chiffres', 'espace inséré')
    return t2


NOMBRE = re.compile(
    r'(?P<dec>\d+,\d+)'
    r'|(?P<sep>\b\d{1,3}(?:[   ]\d{3})+\b)'
    r'|(?P<ent>\d+)'
)
TAG = re.compile(r'<[^>]*>')


def _convertir(t, cid, log):
    def rep(m):
        if m.group('dec'):
            e, f = m.group('dec').split(',')
            out = decimal_en_lettres(e, f)
        elif m.group('sep'):
            out = en_lettres(int(re.sub(r'[   ]', '', m.group('sep'))))
        else:
            out = en_lettres(int(m.group('ent')))
        log(cid, 'nombre', m.group(0), out)
        return out
    return NOMBRE.sub(rep, t)


def fix_nombres(t, cid, log):
    """Les balises <break .../> portent des chiffres qu'il ne faut pas convertir."""
    morceaux, pos = [], 0
    for m in TAG.finditer(t):
        morceaux.append(_convertir(t[pos:m.start()], cid, log))
        morceaux.append(m.group(0))
        pos = m.end()
    morceaux.append(_convertir(t[pos:], cid, log))
    return ''.join(morceaux)


ELISION = re.compile(r'\b(?P<mot>[Dd]e|[Qq]ue)\s+(?=une?\b)')


def fix_elision(t, cid, log):
    """Le nombre devient un mot à initiale vocalique : « de 1 % » donnait
    « de un pour cent » au lieu de « d'un pour cent »."""
    def rep(m):
        out = m.group('mot')[:-1] + "'"
        log(cid, 'élision', m.group(0), out)
        return out
    return ELISION.sub(rep, t)


def normalize(t, cid, log):
    t = fix_ranges(t, cid, log)
    t = fix_ordinals(t, cid, log)
    t = fix_romains_ordinaux(t, cid, log)
    t = fix_romains_cardinaux(t, cid, log)
    t = fix_romans(t, cid, log)
    t = fix_percent(t, cid, log)
    t = fix_heures(t, cid, log)
    t = fix_unites(t, cid, log)
    t = fix_coordonnees(t, cid, log)
    t = fix_designateurs(t, cid, log)
    t = fix_symboles(t, cid, log)
    return fix_elision(fix_nombres(t, cid, log), cid, log)


def respell(t, cid, log):
    return t


def extra_checks(bare):
    found = []
    for sym in ('%', '°', '/', '=', '+', '&', '$', '€', '£', '₂', '²', '³'):
        if sym in bare:
            found.append(('symbole', sym))
    return found
