"""Spanish reading rules for the ElevenLabs narration.

Spanish sits between the other two. Like French, it reads years as cardinals
("mil ochocientos sesenta y seis") and writes centuries in Roman numerals. Like
nothing else here, it groups thousands with a POINT (30.000) and marks decimals
with a comma, so a French or English number rule reads 30.000 as a decimal.

Two things belong to Spanish alone. Numbers agree in gender — "cuatrocientas
veces", not "cuatrocientos veces" — and lose their final vowel before a
masculine noun: "trescientos ochenta y un días". And a regnal numeral is an
ordinal up to ten ("Carlos quinto") and a cardinal beyond ("Luis dieciséis").
"""

from __future__ import annotations

import re

LANG = 'es'
STAR_WORD = 'estrella'
SEE_PREFIXES = ('Ver', 'Véase')
TAKEAWAY_LEADIN = 'Esto es lo que hay que recordar de este curso.'

CHAPTER_WORDS = {1: 'uno', 2: 'dos', 3: 'tres', 4: 'cuatro', 5: 'cinco'}


def chapter_label(n):
    return f'Capítulo {CHAPTER_WORDS[n]}.'


def echoes_chapter_number(heading, n):
    first = re.split(r'[\s,:;.!?¿¡]', heading.strip(), 1)[0].lower()
    return first in (CHAPTER_WORDS[n], {1: 'una', 2: 'dos'}.get(n))


DETERMINERS = {'el', 'la', 'los', 'las', 'un', 'una', 'del', 'al'}

SOURCE_FIXES = {
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_229_l_ue_comment_ca_marche_vraiment': [
        ('[[La Comisión Europea y el monopolio de iniciativa legislativa]]', 'el monopolio de iniciativa legislativa'),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_91_les_miserables_victor_hugo': [
        ('[[Galeras y sistema penal en el siglo XIX]]', 'galeras'),
    ],
    # L'apposition entre parenthèses s'entend comme un sixième item
    # de l'énumération, alors que la phrase en annonce cinq.
    'course_237_les_gafam_puissance_et_derives': [
        ('Meta (el antiguo Facebook)', 'Meta, antes Facebook'),
    ],
    # El romano queda solo tras « dio nacimiento a la »: sin el nombre detrás,
    # ninguna regla puede saber que es la Quinta República.
    'course_23_la_guerre_d_algerie_1954_1962': [
        ('dio nacimiento a la V.', 'dio nacimiento a la Quinta República.'),
    ],
    # La entrada del glosario junta dos temas; pegada a la frase, hace que la
    # herida ocurra « en el cautiverio ».
    'course_109_don_quichotte_cervantes': [
        ('**[[Batalla de Lepanto (1571) y cautiverio de Cervantes]]**', '**batalla de Lepanto** en 1571'),
    ],
    'course_128_l_expressionnisme_munch_et_le_cri': [
        ('**[[Erupción del Krakatoa (1883) y el cielo rojo]]**', '**erupción del Krakatoa** en 1883'),
    ],
}

QUOTES = {
    'course_298_esope_a_t_il_vraiment_existe': {'attribution':
        'Es el mandamiento que reescriben los cerdos, en Rebelión en la granja, la fábula que George Orwell publicó en mil novecientos cuarenta y cinco.'},
    'course_100_les_fleurs_du_mal_baudelaire': {'attribution':
        'Son los primeros versos de Correspondencias, de Charles Baudelaire.'},
    'course_101_1984_george_orwell': {'attribution':
        'Son los tres lemas del Partido, en mil novecientos ochenta y cuatro de George Orwell.'},
    'course_102_la_ferme_des_animaux_george_orwell': {'attribution':
        'Es el mandamiento que reescriben los cerdos, en Rebelión en la granja de George Orwell.'},
    'course_103_hamlet_shakespeare': {'attribution':
        'Así habla Hamlet, en el acto tercero, escena primera de la obra de William Shakespeare.'},
    'course_104_romeo_et_juliette_shakespeare': {'attribution':
        'Es Julieta quien habla, en el acto segundo, escena segunda de Romeo y Julieta.'},
    'course_105_le_meilleur_des_mondes_aldous_huxley': {'attribution':
        'Así habla el Salvaje, en Un mundo feliz de Aldous Huxley.'},
    'course_106_frankenstein_mary_shelley': {'attribution':
        'Es la criatura quien habla, en Frankenstein de Mary Shelley.'},
    'course_108_le_proces_kafka': {'attribution':
        'Son las primeras palabras de El proceso, de Franz Kafka.'},
    # Don Quijote se lo dice a don Diego; no es un aparte del autor.
    'course_109_don_quichotte_cervantes': {'attribution':
        'Así habla el propio don Quijote, en la novela de Miguel de Cervantes.'},
    'course_112_le_grand_gatsby_fitzgerald': {'attribution':
        'Son palabras del narrador, Nick Carraway, en las últimas páginas de El gran Gatsby, '
        'de Francis Scott Fitzgerald.'},
    # La frase no aparece en Bradbury: se narra como paráfrasis, nunca como cita.
    'course_114_fahrenheit_451_bradbury': {'paraphrase':
        'En las últimas páginas de la novela, los exiliados a los que se une Montag han aprendido '
        'cada uno un libro de memoria. El fuego los ha tocado, pero a través de ellos los libros '
        'sobreviven.'},
    'course_117_le_maitre_et_marguerite_boulgakov': {'attribution':
        'Es Voland quien lo dice, en El maestro y Margarita de Mijaíl Bulgákov.'},
    'course_119_le_petit_prince_saint_exupery': {'attribution':
        'Es el zorro quien revela su secreto, en El principito de Antoine de Saint-Exupéry.'},
    'course_91_les_miserables_victor_hugo': {'attribution':
        'Así habla monseñor Bienvenido, en Los miserables de Victor Hugo.'},
    'course_94_candide_voltaire': {'attribution':
        'Son las palabras del esclavo de Surinam, en Cándido de Voltaire.'},
    'course_96_l_etranger_camus': {'attribution':
        'Son las primeras palabras de El extranjero, de Albert Camus.'},
    'course_97_le_mythe_de_sisyphe_camus': {'attribution':
        'Con esta frase cierra Albert Camus El mito de Sísifo.'},
    'course_98_a_la_recherche_du_temps_perdu_proust': {'attribution':
        'Así habla el narrador, en Por el camino de Swann de Marcel Proust.'},
    'course_99_le_pere_goriot_balzac': {'attribution':
        'Es el desafío que Rastignac lanza a París, en la última página de Papá Goriot '
        'de Honoré de Balzac.'},
}


# ------------------------------------------------------------------ números
U = ['cero', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez',
     'once', 'doce', 'trece', 'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho',
     'diecinueve', 'veinte', 'veintiuno', 'veintidós', 'veintitrés', 'veinticuatro',
     'veinticinco', 'veintiséis', 'veintisiete', 'veintiocho', 'veintinueve']
DECENAS = {3: 'treinta', 4: 'cuarenta', 5: 'cincuenta', 6: 'sesenta', 7: 'setenta', 8: 'ochenta',
           9: 'noventa'}
CENTENAS = {1: 'ciento', 2: 'doscientos', 3: 'trescientos', 4: 'cuatrocientos', 5: 'quinientos',
            6: 'seiscientos', 7: 'setecientos', 8: 'ochocientos', 9: 'novecientos'}


def _uno(genre, apocope):
    if genre == 'f':
        return 'una'
    return 'un' if apocope else 'uno'


def _bajo_cien(n, genre, apocope):
    if n == 1:
        return _uno(genre, apocope)
    if n == 21:
        if genre == 'f':
            return 'veintiuna'
        return 'veintiún' if apocope else 'veintiuno'
    if n < 30:
        return U[n]
    d, r = divmod(n, 10)
    if r == 0:
        return DECENAS[d]
    return f'{DECENAS[d]} y {_bajo_cien(r, genre, apocope)}'


def _bajo_mil(n, genre, apocope):
    if n < 100:
        return _bajo_cien(n, genre, apocope)
    c, r = divmod(n, 100)
    if c == 1 and r == 0:
        return 'cien'
    cab = CENTENAS[c]
    if c > 1 and genre == 'f':
        cab = cab[:-2] + 'as'      # doscientos -> doscientas
    return cab if r == 0 else f'{cab} {_bajo_cien(r, genre, apocope)}'


def cardinal(n, genre='m', apocope=False):
    if n == 0:
        return 'cero'
    partes = []
    millones, resto = divmod(n, 10 ** 6)
    if millones:
        # « millón » es masculino: « un millón de personas »
        partes.append('un millón' if millones == 1
                      else f'{cardinal(millones, "m", True)} millones')
    miles, resto = divmod(resto, 1000)
    if miles:
        partes.append('mil' if miles == 1 else f'{_bajo_mil(miles, genre, True)} mil')
    if resto:
        partes.append(_bajo_mil(resto, genre, apocope))
    return ' '.join(partes)


ORDINALES = {1: 'primer', 2: 'segund', 3: 'tercer', 4: 'cuart', 5: 'quint', 6: 'sext',
             7: 'séptim', 8: 'octav', 9: 'noven', 10: 'décim',
             # « la Decimotercera Enmienda », no « la trece Enmienda »: en los
             # nombres propios el español mantiene el ordinal más allá de diez.
             11: 'undécim', 12: 'duodécim', 13: 'decimotercer', 14: 'decimocuart',
             15: 'decimoquint', 16: 'decimosext', 17: 'decimoséptim',
             18: 'decimoctav', 19: 'decimonoven', 20: 'vigésim'}


def ordinal(n, genre='m'):
    """Ordinals are said up to twenty; past that Spanish says the cardinal."""
    if n in ORDINALES:
        return ORDINALES[n] + ('a' if genre == 'f' else 'o')
    return cardinal(n, genre)


def decimal(entero, frac):
    t = cardinal(int(entero)) + ' coma '
    if len(frac) == 1:
        return t + U[int(frac)]
    if len(frac) == 2 and frac[0] != '0':
        return t + cardinal(int(frac))
    return t + ' '.join(U[int(c)] for c in frac)


# Nombres féminins qui suivent un nombre dans ce corpus : l'accord s'entend.
FEMENINOS = {'veces', 'lenguas', 'cantatas', 'obras', 'páginas', 'partes', 'puertas', 'noches',
             'kilocalorías', 'personas', 'horas', 'mujeres', 'islas', 'ciudades', 'toneladas',
             'hectáreas', 'especies', 'víctimas', 'cartas', 'piezas', 'naves', 'libras',
             'semanas', 'monedas', 'casas', 'torres', 'estrellas', 'galaxias', 'células',
             'bajas', 'almas', 'obras', 'muertes', 'lenguas'}
# Mots qui ne sont pas des noms : pas d'apocope derrière eux.
# L'apocope ne vaut que devant un nom masculin. La liste est fermée et tirée du
# corpus : « mil novecientos cincuenta y un nació » n'est pas de l'espagnol.
NOMBRES_APOCOPE = {'días', 'millones', 'millón', 'km', 'kilómetros', 'años', 'metros', 'litros',
                   'habitantes', 'soldados', 'muertos', 'hombres', 'países', 'ríos', 'versos',
                   'minutos', 'miembros', 'ejemplares', 'cuadros', 'barcos', 'cañones', 'judíos',
                   'exoplanetas', 'periodistas', 'intelectuales', 'grados', 'siglos', 'euros',
                   'dólares', 'puntos', 'casos', 'kilos', 'mil'}
NO_APOCOPE = {'de', 'del', 'a', 'al', 'y', 'e', 'o', 'u', 'es', 'son', 'era', 'fue', 'ha', 'han',
              'se', 'que', 'por', 'en', 'con', 'para', 'usa', 'muestra', 'recuerda', 'sigue',
              'después', 'antes', 'd', 'lo', 'la', 'el', 'los', 'las'}


# ------------------------------------------------------------------- romanos
ROMAN_VAL = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def roman_to_int(r):
    tot, prev = 0, 0
    for ch in reversed(r):
        v = ROMAN_VAL[ch]
        tot = tot - v if v < prev else tot + v
        prev = max(prev, v)
    return tot


# 26 soberanos del corpus. Nada se deduce del patrón: « rayos X », « una V »,
# « Franklin D. » y « a. C. » tienen exactamente la misma forma.
REGNAL_FEM = {'Isabel', 'Catalina', 'María', 'Victoria', 'Ana'}
# Una lista de parejas nombre+cifra se queda corta en cuanto llega un curso
# nuevo: se enumeran los NOMBRES, y la cifra se convierte sola.
REGNAL = {
    'Urbano', 'Nicolás', 'Luis', 'Napoleón', 'Carlos', 'Julio', 'Moctezuma',
    'León', 'Mehmed', 'Constantino', 'Isabel', 'Francisco', 'Alejandro',
    'José', 'Abdülhamid', 'Alejo', 'Alarico', 'Felipe', 'Inocencio',
    'Enrique', 'Clemente', 'Teodosio', 'Valentiniano', 'Lorenzo', 'Fernando',
    'Pedro', 'Juan', 'Pío', 'Gregorio', 'Ricardo', 'Eduardo', 'Jorge',
    'Catalina', 'María', 'Victoria', 'Ana', 'Guillermo', 'Otón', 'Federico',
}
_REGNAL_RE = re.compile(r'(?<![\w-])(?P<nom>' + '|'.join(sorted(REGNAL, key=len, reverse=True))
                        + r')(?:\s+Felipe)?\s+(?P<rom>[IVXLCDM]{1,6})'
                        + r'(?=[\s.,;:!?¿¡\'’”)]|$)')

SIGLO = re.compile(r'\b(?P<pal>[Ss]iglos?)\s+(?P<a>[IVXLCDM]+)\b'
                   r'(?:(?P<sep>\s*-\s*|\s+(?:al?|y(?:\s+el)?)\s+)(?P<b>[IVXLCDM]+)\b)?')
REPUBLICA = re.compile(r'\b(?P<rom>[IVXLCDM]+)\s+(?P<pal>Rep[úu]blica)\b')
PARTE = re.compile(r'\b(?P<pal>canto|libro|acto|capítulo|tomo|parte|volumen)\s+(?P<rom>[IVXLCDM]+)\b')
ERA = re.compile(r'\b(?P<era>[ad])\.\s?C\.')


def fix_era(t, cid, log):
    """« a. C. » antes que nada: la C es también un numeral romano."""
    def rep(m):
        out = 'antes de Cristo' if m.group('era') == 'a' else 'después de Cristo'
        log(cid, 'era', m.group(0), out)
        return out
    return ERA.sub(rep, t)


# « del siglo V o principios del VI »: la segunda cifra sigue hablando de
# siglos, pero ya no lleva la palabra delante.
SIGLO_ELIDIDO = re.compile(r'\b(?P<art>del|de la|al|a la|o|u|y|e)\s+(?P<rom>[IVXLCDM]{1,5})\b')


def fix_siglo_elidido(t, cid, log):
    def rep(m):
        avant = t[max(0, m.start() - 90):m.start()]
        if not re.search(r'[Ss]iglos?\b', avant):
            return m.group(0)
        n = roman_to_int(m.group('rom'))
        out = f"{m.group('art')} {ordinal(n, 'm') if n <= 10 else cardinal(n)}"
        log(cid, 'siglo', m.group(0), out)
        return out
    return SIGLO_ELIDIDO.sub(rep, t)


def fix_siglos(t, cid, log):
    def rep(m):
        n = roman_to_int(m.group('a'))
        # « siglo quinto », no « siglo cinco »: hasta diez el español
        # dice el ordinal, y el resto del módulo ya lo hace así.
        out = f"{m.group('pal')} {ordinal(n, 'm') if n <= 10 else cardinal(n)}"
        if m.group('b'):
            out += f"{m.group('sep')}{cardinal(roman_to_int(m.group('b')))}"
        log(cid, 'siglo', m.group(0), out)
        return out
    return SIGLO.sub(rep, t)


def fix_regnal(t, cid, log):
    def rep(m):
        nombre, rom = m.group('nom'), m.group('rom')
        n = roman_to_int(rom)
        genre = 'f' if nombre in REGNAL_FEM else 'm'
        # « Luis segundo » hasta diez, « Luis dieciséis » después.
        cifra = ordinal(n, genre) if n <= 10 else cardinal(n, genre)
        out = m.group(0)[:m.group(0).rindex(rom)] + cifra
        log(cid, 'romano', m.group(0), out)
        return out
    return _REGNAL_RE.sub(rep, t)


def fix_republica(t, cid, log):
    def rep(m):
        out = f"{ordinal(roman_to_int(m.group('rom')), 'f').capitalize()} {m.group('pal')}"
        log(cid, 'romano', m.group(0), out)
        return out
    return REPUBLICA.sub(rep, t)


def fix_partes(t, cid, log):
    def rep(m):
        out = f"{m.group('pal')} {ordinal(roman_to_int(m.group('rom')))}"
        log(cid, 'romano', m.group(0), out)
        return out
    return PARTE.sub(rep, t)


# ------------------------------------------------------------ unidades, etc.
UNIDADES = [
    ('km/h', 'kilómetro por hora', 'kilómetros por hora'),
    ('km/s', 'kilómetro por segundo', 'kilómetros por segundo'),
    ('m/s', 'metro por segundo', 'metros por segundo'),
    ('g/l', 'gramo por litro', 'gramos por litro'),
    ('km³', 'kilómetro cúbico', 'kilómetros cúbicos'),
    ('km²', 'kilómetro cuadrado', 'kilómetros cuadrados'),
    ('°C', 'grado Celsius', 'grados Celsius'),
    ('°F', 'grado Fahrenheit', 'grados Fahrenheit'),
    ('km', 'kilómetro', 'kilómetros'),
    ('cm', 'centímetro', 'centímetros'),
    ('mm', 'milímetro', 'milímetros'),
    ('kg', 'kilogramo', 'kilogramos'),
    ('m²', 'metro cuadrado', 'metros cuadrados'),
    ('°', 'grado', 'grados'),
]
_ALT = '|'.join(re.escape(u) for u, _, _ in UNIDADES)
NUM = r'\d[\d.]*(?:,\d+)?'
UNIDAD = re.compile(r'(?:(?P<signo>[-+~≈])\s*)?(?P<n>' + NUM + r')\s?(?P<u>' + _ALT + r')(?![\w²])')
UNIDAD_SOLA = re.compile(r'(?P<pre>\b(?:millones|miles|millón) de )(?P<u>' + _ALT + r')(?![\w²])')
SIGNOS = {'-': 'menos ', '+': 'más ', '~': 'unos ', '≈': 'unos '}
RELOJ = re.compile(r'\b(?P<h>\d{1,2}):(?P<m>\d{2})\b')
# El grado « ° » no es un indicador ordinal: « 233°C » es una temperatura,
# y la regla se la comía dejando la « C » pegada al número.
ORDINAL_IND = re.compile(r'(?<![\d,.])(?P<n>\d{1,3})\.?(?P<g>[ºª])(?![CF]\b)')
CIRCA = re.compile(r'(?<![A-Za-zá-ú])c\.\s?(?=\d)')
PORCIENTO = re.compile(r'(?P<n>' + NUM + r')\s?%')


def _valor(s):
    return float(s.replace('.', '').replace(',', '.'))


# « 82°17' » : des coordonnées, pas une température.
COORD = re.compile(r"(?<![\d,.])(?P<d>\d{1,3})\s?°\s?(?:(?P<m>\d{1,2})\s?')?")


def fix_coord(t, cid, log):
    def rep(m):
        out = f"{cardinal(int(m.group('d')))} grados"
        if m.group('m'):
            out += f" {cardinal(int(m.group('m')))} minutos"
        log(cid, 'coordonnées', m.group(0), out)
        return out
    return COORD.sub(rep, t)


def fix_unidades(t, cid, log):
    def sola(m):
        plur = next(p for u, _, p in UNIDADES if u == m.group('u'))
        log(cid, 'unidad', m.group('u'), plur)
        return m.group('pre') + plur
    t = UNIDAD_SOLA.sub(sola, t)

    def rep(m):
        sing, plur = next((s, p) for u, s, p in UNIDADES if u == m.group('u'))
        palabra = sing if _valor(m.group('n')) == 1 else plur
        out = SIGNOS.get(m.group('signo') or '', '') + m.group('n') + ' ' + palabra
        log(cid, 'unidad', m.group(0), out)
        return out
    return UNIDAD.sub(rep, t)


def fix_reloj(t, cid, log):
    def rep(m):
        h, mn = int(m.group('h')), int(m.group('m'))
        # « la una y media » : la hora concuerda en femenino.
        hora = 'una' if h == 1 else 'veintiuna' if h == 21 else cardinal(h)
        out = hora + ('' if mn == 0 else ' ' + ('cero ' + U[mn] if mn < 10 else cardinal(mn)))
        log(cid, 'hora', m.group(0), out)
        return out
    return RELOJ.sub(rep, t)


NUMERO_ABREV = re.compile(r'\b[nN][.ºo]?\s*º\s*(?=\d)')


def fix_numero(t, cid, log):
    """« el reactor n.º 4 » : aquí « º » abrevia « número », no un ordinal."""
    def rep(m):
        log(cid, 'número', m.group(0).strip(), 'número')
        return 'número '
    return NUMERO_ABREV.sub(rep, t)


def fix_ordinal_ind(t, cid, log):
    """« 6.º Ejército » : l'indicateur ordinal masculin/féminin."""
    def rep(m):
        out = ordinal(int(m.group('n')), 'f' if m.group('g') == 'ª' else 'm')
        log(cid, 'ordinal', m.group(0), out)
        return out
    return ORDINAL_IND.sub(rep, t)


def fix_circa(t, cid, log):
    def rep(m):
        log(cid, 'circa', m.group(0), 'hacia ')
        return 'hacia '
    return CIRCA.sub(rep, t)


def fix_porciento(t, cid, log):
    def rep(m):
        out = f"{m.group('n')} por ciento"
        log(cid, 'porcentaje', m.group(0), out)
        return out
    return PORCIENTO.sub(rep, t)


DESIGNADORES = [
    ('MIC', 'M-I-C'),
    ('Lascaux II', 'Lascaux dos'),

    ('CO₂', 'CO dos'),
    ('E=mc²', 'E igual a m c al cuadrado'),
    ('4/4', 'cuatro por cuatro'),
    ('TCP/IP', 'TCP IP'),
    ('OPEP+', 'OPEP más'),
    ('1.001 noches', 'mil una noches'),
]
SIMBOLOS = [
    (re.compile(r'\s*→\s*'), ' da '),
    (re.compile(r'(?<=[\w)])\s*\+\s*(?=[\w(])'), ' más '),
    (re.compile(r'(?<=[\w)])\s*=\s*(?=[\w(])'), ' igual a '),
    (re.compile(r'(?<=[A-Za-zÀ-ÿ])/(?=[A-Za-zÀ-ÿ])'), '-'),
    (re.compile(r'\s*&\s*'), ' y '),
]


def fix_designadores(t, cid, log):
    for raw, out in DESIGNADORES:
        if raw in t:
            t = t.replace(raw, out)
            log(cid, 'designador', raw, out)
    for pattern, out in SIMBOLOS:
        for m in pattern.finditer(t):
            log(cid, 'símbolo', m.group(0), out)
        t = pattern.sub(out, t)
    t2 = re.sub(r'(?<=[A-Za-z])(?=\d)', ' ', t)
    t2 = re.sub(r'(?<=\d)(?=[A-Za-z])', ' ', t2)
    if t2 != t:
        log(cid, 'designador', 'letras pegadas a cifras', 'espacio')
    return t2


RANGO = re.compile(r'(?<![\d.,])(?P<a>\d{3,4})\s*-\s*(?P<b>\d{2,4})(?![\d])')
RANGO_CORTO = re.compile(r'(?<![\d.,])(?P<a>\d{1,2})\s*-\s*(?P<b>\d{1,2})(?![\d])')


# « desde X a Y » se dice; « en X a Y » y « entre X a Y » no: allí va « y ».
PREP_A = re.compile(r'\b(?:desde|Desde|de|De|hasta|Hasta)\s+$')
PREP_Y = re.compile(r'\b(?:en|En|entre|Entre|hacia|Hacia)\s+$')


def fix_rangos(t, cid, log):
    def rep(m):
        a, b = m.group('a'), m.group('b')
        if len(a) == 4 and len(b) == 2:
            b = a[:2] + b
        # « En 1936-1937 » ne doit pas devenir « En de 1936 a 1937 »
        antes = t[:m.start()]
        if PREP_Y.search(antes):
            out = f'{a} y {b}'
        elif PREP_A.search(antes):
            out = f'{a} a {b}'
        else:
            out = f'de {a} a {b}'
        log(cid, 'rango', m.group(0), out)
        return out
    t = RANGO.sub(rep, t)

    def corto(m):
        out = f"{m.group('a')} a {m.group('b')}"
        log(cid, 'rango', m.group(0), out)
        return out
    return RANGO_CORTO.sub(corto, t)


# El punto agrupa millares y la coma marca el decimal: al revés que en inglés.
NUMERO = re.compile(
    r'(?P<dec>\d+,\d+)'
    r'|(?P<mil>\b\d{1,3}(?:\.\d{3})+\b)'
    r'|(?P<ent>\d+)'
)
TAG = re.compile(r'<[^>]*>')


def _convertir(t, cid, log):
    def rep(m):
        if m.group('dec'):
            e, f = m.group('dec').split(',')
            out = decimal(e, f)
        else:
            crudo = m.group('mil') or m.group('ent')
            n = int(crudo.replace('.', ''))
            # el género y la apócope dependen de la palabra que sigue
            resto = t[m.end():].lstrip()
            siguiente = re.match(r"[a-záéíóúüñ]+", resto)
            palabra = siguiente.group(0) if siguiente else ''
            # « unas setecientas mil bajas » : le nom est derrière l'échelle
            suite = re.match(r'(?:mil|millones|millón|de)\s+([a-záéíóúüñ]+)', resto)
            nom = suite.group(1) if suite and palabra in ('mil', 'millones', 'millón', 'de') else palabra
            genre = 'f' if (palabra in FEMENINOS or nom in FEMENINOS) else 'm'
            apocope = genre == 'm' and palabra in NOMBRES_APOCOPE
            out = cardinal(n, genre, apocope)
        log(cid, 'número', m.group(0), out)
        return out
    return NUMERO.sub(rep, t)


def fix_numeros(t, cid, log):
    trozos, pos = [], 0
    for m in TAG.finditer(t):
        trozos.append(_convertir(t[pos:m.start()], cid, log))
        trozos.append(m.group(0))
        pos = m.end()
    trozos.append(_convertir(t[pos:], cid, log))
    return ''.join(trozos)


def normalize(t, cid, log):
    t = fix_era(t, cid, log)
    t = fix_siglos(t, cid, log)
    t = fix_siglo_elidido(t, cid, log)
    t = fix_regnal(t, cid, log)
    t = fix_republica(t, cid, log)
    t = fix_partes(t, cid, log)
    t = fix_circa(t, cid, log)
    t = fix_unidades(t, cid, log)
    t = fix_coord(t, cid, log)
    t = fix_numero(t, cid, log)
    t = fix_ordinal_ind(t, cid, log)
    t = fix_reloj(t, cid, log)
    t = fix_porciento(t, cid, log)
    t = fix_designadores(t, cid, log)
    t = fix_rangos(t, cid, log)
    return fix_numeros(t, cid, log)


def respell(t, cid, log):
    return t


ACRONIMOS = {'MC', 'CD', 'DVD', 'MIX'}


def extra_checks(bare):
    found = []
    for sym in ('%', '°', 'º', 'ª', '/', '=', '+', '$', '€', '£', '₂', '²', '³', '&'):
        if sym in bare:
            found.append(('símbolo', sym))
    for m in re.finditer(r'\b[IVXLCDM]{2,}\b', bare):
        if m.group(0) in ACRONIMOS:
            continue
        found.append(('romano', m.group(0)))
    return found
