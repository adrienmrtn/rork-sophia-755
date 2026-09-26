"""Turkish reading rules for the ElevenLabs narration.

Turkish is the one language here where the number does not stand alone. A case
suffix is glued to it with an apostrophe — 1857'de, 1984'ü, 1990'ların — 797
times in this corpus. The apostrophe only exists to separate the digits from the
suffix; once the number is spelled out the suffix simply joins the word:
1857'de becomes "bin sekiz yüz elli yedide".

That works because Turkish orthography already picks the suffix that matches the
spoken form, vowel harmony included. One thing the apostrophe hides is the
consonant change: "dört" softens to "dörd" before a vowel, so 1984'ü is
"bin dokuz yüz seksen dördü", not "dörtü".

Ordinals are built the same way, with four-way vowel harmony on the last word:
19. yüzyıl is "on dokuzuncu yüzyıl". And the percent sign comes BEFORE the
number: %15 is "yüzde on beş".
"""

from __future__ import annotations

import re

LANG = 'tr'
STAR_WORD = 'yıldız'
SEE_PREFIXES = ('Bkz.', 'Bakınız')

# Rempli par la passe de rédaction turque (voir NARRATION ci-dessous).
CHAPTER_WORDS = {1: 'Birinci', 2: 'İkinci', 3: 'Üçüncü', 4: 'Dördüncü', 5: 'Beşinci'}
TAKEAWAY_LEADIN = 'Bu dersten akılda kalması gerekenler şunlar.'


def chapter_label(n):
    return f'{CHAPTER_WORDS[n]} bölüm.'


def echoes_chapter_number(heading, n):
    first = re.split(r'[\s,:;.!?]', heading.strip(), 1)[0].lower()
    # « Bir » en tête de titre est l'article indéfini, pas le nombre : 21 titres
    # du corpus commencent ainsi. Aucun n'est en section un aujourd'hui, mais la
    # pause d'écho y serait fausse.
    cardinals = {2: 'iki', 3: 'üç', 4: 'dört', 5: 'beş'}
    return first in (CHAPTER_WORDS[n].lower(), cardinals.get(n))


DETERMINERS = set()  # le turc n'a pas d'article défini

def tr_upper(c):
    """Türkçede « i »nin büyüğü noktalı « İ »dir; ASCII büyütme « I » verir ve
    ses değişir."""
    return 'İ' if c == 'i' else c.upper()


def capitalize_first(t):
    return tr_upper(t[0]) + t[1:] if t and t[0].islower() else t


SOURCE_FIXES = {
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_229_l_ue_comment_ca_marche_vraiment': [
        ('[[Avrupa Komisyonu ve yasama girişimi tekeli]]', 'yasama girişimi tekeli'),
    ],
    # L'intitulé du glossaire réunit deux notions ; inséré tel quel dans la
    # phrase, il la rend incorrecte.
    'course_168_sisyphe_punition_eternelle': [
        ("Camus [[Camus ve Sisifos'ta saçma]] olgusunu", 'Camus saçma olgusunu'),
    ],
    # L'apposition entre parenthèses s'entend comme un sixième item
    # de l'énumération, alors que la phrase en annonce cinq.
    'course_237_les_gafam_puissance_et_derives': [
        ('Meta (eski Facebook)', 'Meta, eski adıyla Facebook'),
    ],
    # Sözlük anahtarları Türkçeye çevrilmeden kalmış.
    'course_153_la_creation_d_adam_michel_ange': [
        ('[[diseksiyon_anatomik]]', 'anatomik diseksiyon'),
        ('[[maniere_moderne]]', 'modern üslup'),
    ],
}

QUOTES = {
    'course_100_les_fleurs_du_mal_baudelaire': {'attribution':
        "Bunlar, Charles Baudelaire'in Karşılıklar adlı sonesinin ilk dizeleridir."},
    'course_101_1984_george_orwell': {'attribution':
        "Bunlar, George Orwell'in bin dokuz yüz seksen dört adlı romanında Parti'nin üç sloganıdır."},
    'course_102_la_ferme_des_animaux_george_orwell': {'attribution':
        "Bu cümle, George Orwell'in Hayvan Çiftliği romanında domuzların yeniden yazdığı emirdir."},
    'course_103_hamlet_shakespeare': {'attribution':
        "Hamlet, William Shakespeare'in oyununda, üçüncü perdenin birinci sahnesinde böyle konuşur."},
    'course_104_romeo_et_juliette_shakespeare': {'attribution':
        "Juliet, William Shakespeare'in Romeo ve Juliet oyununda, ikinci perdenin ikinci sahnesinde böyle konuşur."},
    'course_105_le_meilleur_des_mondes_aldous_huxley': {'attribution':
        "Vahşi John, Aldous Huxley'nin Cesur Yeni Dünya romanında bu hakkı ister."},
    'course_106_frankenstein_mary_shelley': {'attribution':
        "Yaratık, Mary Shelley'nin Frankenstein romanında kendini böyle anlatır."},
    'course_108_le_proces_kafka': {'attribution':
        "Bu, Franz Kafka'nın Dava romanının ilk cümlesidir."},
    'course_109_don_quichotte_cervantes': {'attribution':
        "Don Kişot, Miguel de Cervantes'in romanında bunu kendisi söyler."},
    'course_112_le_grand_gatsby_fitzgerald': {'attribution':
        "Anlatıcı Nick Carraway, Francis Scott Fitzgerald'ın Muhteşem Gatsby romanının son sayfalarında böyle konuşur."},
    # Cümle Bradbury'de bulunamadı: alıntı olarak değil, özet olarak okunur.
    'course_114_fahrenheit_451_bradbury': {'paraphrase':
        "Romanın son sayfalarında, Montag'ın aralarına katıldığı sürgünlerin her biri bir kitabı ezbere öğrenmiştir. Ateş onlara değmiştir, ama kitaplar onların içinde yaşamayı sürdürür."},
    'course_117_le_maitre_et_marguerite_boulgakov': {'attribution':
        "Woland, Mihail Bulgakov'un Usta ile Margarita romanında bunu söyler."},
    'course_119_le_petit_prince_saint_exupery': {'attribution':
        "Tilki, Antoine de Saint-Exupéry'nin Küçük Prens kitabında sırrını böyle açıklar."},
    'course_91_les_miserables_victor_hugo': {'attribution':
        "Piskopos Myriel, Victor Hugo'nun Sefiller romanında Jean Valjean'a böyle seslenir."},
    # Kaynaktaki sözcük ırkçı bir hakarettir; burada « köle » denir.
    'course_94_candide_voltaire': {'attribution':
        "Surinamlı köle, Voltaire'in Candide adlı eserinde böyle konuşur."},
    'course_96_l_etranger_camus': {'attribution':
        "Bunlar, Albert Camus'nün Yabancı romanının ilk cümleleridir."},
    'course_97_le_mythe_de_sisyphe_camus': {'attribution':
        'Albert Camus, Sisifos Söyleni adlı denemesini bu cümleyle bitirir.'},
    'course_98_a_la_recherche_du_temps_perdu_proust': {'attribution':
        "Anlatıcı, Marcel Proust'un Swann'ların Tarafı romanında böyle konuşur."},
    'course_99_le_pere_goriot_balzac': {'attribution':
        "Rastignac, Honoré de Balzac'ın Goriot Baba romanının son sayfasında Paris'e böyle meydan okur."},
}


# ------------------------------------------------------------------ sayılar
BIRLER = ['sıfır', 'bir', 'iki', 'üç', 'dört', 'beş', 'altı', 'yedi', 'sekiz', 'dokuz']
ONLAR = {1: 'on', 2: 'yirmi', 3: 'otuz', 4: 'kırk', 5: 'elli', 6: 'altmış', 7: 'yetmiş',
         8: 'seksen', 9: 'doksan'}
OLCEKLER = [(10 ** 9, 'milyar'), (10 ** 6, 'milyon'), (10 ** 3, 'bin')]


def _yuz_alti(n):
    d, u = divmod(n, 10)
    parts = []
    if d:
        parts.append(ONLAR[d])
    if u:
        parts.append(BIRLER[u])
    return ' '.join(parts)


def _bin_alti(n):
    y, r = divmod(n, 100)
    parts = []
    if y:
        # « yüz », jamais « bir yüz »
        parts.append('yüz' if y == 1 else f'{BIRLER[y]} yüz')
    if r:
        parts.append(_yuz_alti(r))
    return ' '.join(parts)


def cardinal(n):
    if n == 0:
        return 'sıfır'
    parts, reste = [], n
    for val, nom in OLCEKLER:
        q, reste = divmod(reste, val)
        if not q:
            continue
        if nom == 'bin':
            parts.append('bin' if q == 1 else f'{_bin_alti(q)} bin')
        else:
            parts.append(f'{_bin_alti(q)} {nom}')
    if reste:
        parts.append(_bin_alti(reste))
    return ' '.join(parts)


SESLILER = 'aeıioöuü'
UYUM = {'a': 'ı', 'ı': 'ı', 'e': 'i', 'i': 'i', 'o': 'u', 'u': 'u', 'ö': 'ü', 'ü': 'ü'}


def _son_sesli(w):
    for c in reversed(w):
        if c in SESLILER:
            return c
    return 'a'


def _sira_eki(w):
    """Ordinal suffix, four-way harmony: -inci / -ıncı / -uncu / -üncü."""
    if w == 'dört':
        return 'dördüncü'
    v = UYUM[_son_sesli(w)]
    if w[-1] in SESLILER:
        return w + 'nc' + v
    return w + v + 'nc' + v


def ordinal(n):
    kelimeler = cardinal(n).split(' ')
    kelimeler[-1] = _sira_eki(kelimeler[-1])
    return ' '.join(kelimeler)


def _ek_ekle(soylenen, ek):
    """Le suffixe se colle au nombre dit. L'apostrophe masque un seul
    changement : « dört » devient « dörd » devant une voyelle."""
    if ek[:1] in SESLILER and soylenen.endswith('dört'):
        soylenen = soylenen[:-1] + 'd'
    return soylenen + ek


def decimal(tam, kesir):
    return f'{cardinal(int(tam))} virgül ' + ' '.join(BIRLER[int(c)] for c in kesir)


# ------------------------------------------------------------------ romalı
ROMAN_VAL = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}


def roman_to_int(r):
    tot, prev = 0, 0
    for ch in reversed(r):
        v = ROMAN_VAL[ch]
        tot = tot - v if v < prev else tot + v
        prev = max(prev, v)
    return tot


# Türkçede sıra sayısı adın önüne gelir: « XVI. Louis » = « On Altıncı Louis ».
# Hiçbir kalıptan çıkarılamaz: « D. Roosevelt » ve « C. Clarke » aynı biçimdedir.
HUKUMDAR_ONDE = [('II', 'Urban'), ('XVI', 'Louis'), ('II', 'Julius'), ('II', 'Nikolay'),
                 ('III', 'Leo'), ('II', 'Mehmed'), ('I', 'Elizabeth'), ('I', 'François'),
                 ('II', 'Franz'), ('I', 'Aleksandr'), ('II', 'Joseph'), ('XIV', 'Louis'),
                 ('II', 'Abdülhamid'), ('III', 'Henry'), ('VI', 'Henry'), ('III', 'Napolyon'),
                 ('X', 'Charles')]
HUKUMDAR_ARKADA = [('Charles', 'VII'), ('Napolyon', 'III'), ('Moctezuma', 'II'),
                   ('Konstantin', 'XI'), ('Nicholas', 'II'), ('Charles', 'X'),
                   ('Louis-Philippe', 'I'), ('Aleksios', 'I'), ('Philip', 'II'),
                   ('Masum', 'III'), ('Klement', 'VI')]

_ONDE = re.compile(r'(?<![\w-])(' + '|'.join(f'{r}\\.\\s+{re.escape(n)}' for r, n in HUKUMDAR_ONDE)
                   + r')(?![\w])')
_ARKADA = re.compile(r'(?<![\w-])(' + '|'.join(f'{re.escape(n)}\\s+{r}' for n, r in HUKUMDAR_ARKADA)
                     + r')(?![\w.])')
ERA = re.compile(r'\bM\.\s?Ö\.|\bMÖ\b|\bM\.\s?S\.|\bMS\b')


def fix_era(t, cid, log):
    """« M.Ö. » d'abord : le M et le S sont aussi des chiffres romains."""
    def rep(m):
        out = 'milattan önce' if 'Ö' in m.group(0) else 'milattan sonra'
        log(cid, 'çağ', m.group(0), out)
        return out
    return ERA.sub(rep, t)


def fix_hukumdar(t, cid, log):
    def onde(m):
        rom, ad = m.group(1).split('.', 1)
        out = f'{capitalize_first(ordinal(roman_to_int(rom)))} {ad.strip()}'
        log(cid, 'romalı', m.group(1), out)
        return out
    t = _ONDE.sub(onde, t)

    def arkada(m):
        ad, rom = m.group(1).rsplit(' ', 1)
        # Türkçede sıra sayısı önce söylenir
        out = f'{capitalize_first(ordinal(roman_to_int(rom)))} {ad}'
        log(cid, 'romalı', m.group(1), out)
        return out
    return _ARKADA.sub(arkada, t)


SAAT = re.compile(r"(?<!\d)(?P<h>\d{1,2})\.(?P<d>\d{2})(?!\d)(?:['’](?P<ek>[a-zçğıöşü]+))?")
SIRA_ARALIK = re.compile(r'\b(?P<a>\d{1,3})\.\s*[-–]\s*(?P<b>\d{1,3})\.')
SIRA = re.compile(r'\b(?P<n>\d{1,3})\.\s+(?=[a-zçğıöşüA-ZÇĞİÖŞÜ])')


def fix_saat(t, cid, log):
    def rep(m):
        d = int(m.group('d'))
        # « 10.03 » : sıfır söylenmezse « on üç » olur ve saat on üçe kayar.
        dakika = 'sıfır ' + cardinal(d) if d < 10 else cardinal(d)
        out = f"{cardinal(int(m.group('h')))} {dakika}"
        if m.group('ek'):
            out = _ek_ekle(out, m.group('ek'))
        log(cid, 'saat', m.group(0), out)
        return out
    return SAAT.sub(rep, t)


def fix_sira_aralik(t, cid, log):
    """« 14.-16. yüzyıl » : ilk sayı da sıra sayısıdır."""
    def rep(m):
        out = f"{ordinal(int(m.group('a')))} - {ordinal(int(m.group('b')))}"
        log(cid, 'sıra sayısı', m.group(0), out)
        return out
    return SIRA_ARALIK.sub(rep, t)


def fix_sira(t, cid, log):
    """« 19. yüzyıl ». Le mot suivant doit être en minuscule : sinon c'est un
    nombre en fin de phrase, pas un ordinal."""
    def rep(m):
        out = ordinal(int(m.group('n'))) + ' '
        log(cid, 'sıra sayısı', m.group(0).strip(), out.strip())
        return out
    return SIRA.sub(rep, t)


# ------------------------------------------------------------ birim, yüzde
SAYI = r'\d[\d.]*(?:,\d+)?'
YUZDE_ONDE = re.compile(r'%\s?(?P<n>' + SAYI + r')')
YUZDE_ARKADA = re.compile(r'(?P<n>' + SAYI + r')\s?%')

BIRIMLER = [('km/h', 'saatte', 'kilometre'), ('km/s', 'saniyede', 'kilometre'),
            ('m/s', 'saniyede', 'metre'), ('g/l', 'litrede', 'gram')]
BASIT = [('km²', 'kilometrekare'), ('°C', 'santigrat derece'), ('°F', 'Fahrenhayt derece'),
         ('km', 'kilometre'), ('cm', 'santimetre'), ('mm', 'milimetre'), ('kg', 'kilogram'),
         ('m²', 'metrekare'), ('°', 'derece')]
_BIRIM_ALT = '|'.join(re.escape(u) for u, _, _ in BIRIMLER)
_BASIT_ALT = '|'.join(re.escape(u) for u, _ in BASIT)
BIRIM_BOLU = re.compile(r'(?P<n>' + SAYI + r')\s?(?P<u>' + _BIRIM_ALT + r')(?![\w²])')
BIRIM_OLCEK = re.compile(r'(?P<olcek>\b(?:bin|milyon|milyar) )(?P<u>' + _BASIT_ALT + r')(?![\w²])')
BIRIM = re.compile(r'(?P<isaret>[-+~≈]?)(?P<n>' + SAYI + r')\s?(?P<u>' + _BASIT_ALT + r')(?![\w²])')
ISARET = {'-': 'eksi ', '+': 'artı ', '~': 'yaklaşık ', '≈': 'yaklaşık '}


def fix_yuzde(t, cid, log):
    def rep(m):
        out = f"yüzde {m.group('n')}"
        log(cid, 'yüzde', m.group(0), out)
        return out
    t = YUZDE_ONDE.sub(rep, t)
    return YUZDE_ARKADA.sub(rep, t)


def fix_birimler(t, cid, log):
    def bolu(m):
        zarf, ad = next((z, a) for u, z, a in BIRIMLER if u == m.group('u'))
        # « saatte on dört bin kilometre » : Türkçe zarfı öne alır
        out = f"{zarf} {m.group('n')} {ad}"
        log(cid, 'birim', m.group(0), out)
        return out
    t = BIRIM_BOLU.sub(bolu, t)

    def olcek(m):
        ad = next(a for u, a in BASIT if u == m.group('u'))
        log(cid, 'birim', m.group('u'), ad)
        return m.group('olcek') + ad
    t = BIRIM_OLCEK.sub(olcek, t)

    def basit(m):
        ad = next(a for u, a in BASIT if u == m.group('u'))
        # Türkçede sayıdan sonra ad tekil kalır
        out = ISARET.get(m.group('isaret'), '') + m.group('n') + ' ' + ad
        log(cid, 'birim', m.group(0), out)
        return out
    return BIRIM.sub(basit, t)


DESIGNATOR = [('CO₂', 'CO iki'), ('E=mc²', 'E eşittir m c kare'), ('4/4', 'dört dörtlük'),
              ('TCP/IP', 'TCP IP'), ('OPEC+', 'OPEC artı'), ('OPEP+', 'OPEC artı')]
SEMBOL = [
    (re.compile(r'\s*→\s*'), ' verir '),
    (re.compile(r'(?<=[\w)])\s*\+\s*(?=[\w(])'), ' artı '),
    (re.compile(r'(?<=[\w)])\s*=\s*(?=[\w(])'), ' eşittir '),
    (re.compile(r'(?<=[A-Za-zÇĞİÖŞÜçğıöşü])/(?=[A-Za-zÇĞİÖŞÜçğıöşü])'), '-'),
    (re.compile(r'\s*&\s*'), ' ve '),
    # « Plessy / Ferguson » : barre entre deux noms propres. Le vers d'une
    # citation n'est pas touché, son mot de gauche commence en minuscule.
    (re.compile(r'\b([A-ZÇĞİÖŞÜ][\wçğıöşü]*) / (?=[A-ZÇĞİÖŞÜ])'), r'\1 - '),
]


def fix_designator(t, cid, log):
    for raw, out in DESIGNATOR:
        if raw in t:
            t = t.replace(raw, out)
            log(cid, 'ad', raw, out)
    for pattern, out in SEMBOL:
        for m in pattern.finditer(t):
            log(cid, 'simge', m.group(0), out)
        t = pattern.sub(out, t)
    t2 = re.sub(r'(?<=[A-Za-z])(?=\d)', ' ', t)
    t2 = re.sub(r'(?<=\d)(?=[A-Za-z])', ' ', t2)
    return t2


ARALIK = re.compile(r'(?<![\d.,])(?P<a>\d{3,4})\s*-\s*(?P<b>\d{2,4})(?![\d])')
ARALIK_KISA = re.compile(r'(?<![\d.,])(?P<a>\d{1,2})\s*-\s*(?P<b>\d{1,2})(?![\d])')


def fix_aralik(t, cid, log):
    def rep(m):
        a, b = m.group('a'), m.group('b')
        if len(a) == 4 and len(b) == 2:
            b = a[:2] + b
        out = f'{a} ile {b}'
        log(cid, 'aralık', m.group(0), out)
        return out
    t = ARALIK.sub(rep, t)
    return ARALIK_KISA.sub(lambda m: f"{m.group('a')} ile {m.group('b')}", t)


# Le point groupe les milliers, la virgule marque la décimale.
EKLI = re.compile(r"(?P<n>\d[\d.]*(?:,\d+)?)['’](?P<ek>[a-zçğıöşü]+)")
SAYI_RE = re.compile(r'(?P<dec>\d+,\d+)|(?P<bin>\b\d{1,3}(?:\.\d{3})+\b)|(?P<tam>\d+)')
TAG = re.compile(r'<[^>]*>')


def _soyle(crude):
    if ',' in crude:
        tam, kesir = crude.split(',', 1)
        return decimal(tam.replace('.', ''), kesir)
    return cardinal(int(crude.replace('.', '')))


def _convert(t, cid, log):
    def ekli(m):
        out = _ek_ekle(_soyle(m.group('n')), m.group('ek'))
        log(cid, 'ekli sayı', m.group(0), out)
        return out
    t = EKLI.sub(ekli, t)

    def sayi(m):
        out = _soyle(m.group(0))
        log(cid, 'sayı', m.group(0), out)
        return out
    return SAYI_RE.sub(sayi, t)


def fix_sayilar(t, cid, log):
    parcalar, pos = [], 0
    for m in TAG.finditer(t):
        parcalar.append(_convert(t[pos:m.start()], cid, log))
        parcalar.append(m.group(0))
        pos = m.end()
    parcalar.append(_convert(t[pos:], cid, log))
    return ''.join(parcalar)


SESSIZ_SERT = set('pçtkfhsş')
# Apostroflu ek yazımı Türkçede doğrudur ve yabancı adlarla kısaltmalarda ek,
# yazılışa değil söylenişe uyar: « Cannes'da », « ABD'de », « Balzac'ta ».
# Bu yüzden kural yalnızca boru hattının simge/birim açtığı için apostrofun
# yanlış sözcüğe yapıştığı durumları onarır; kaynak metne dokunmaz.
PIPELINE_SOZCUKLERI = ({STAR_WORD}
                       | {ad for _, _, ad in BIRIMLER}
                       | {ad.split()[-1] for _, ad in BASIT})
EK_APOSTROF = re.compile(r"\b(?P<kok>[A-Za-zÇĞİÖŞÜçğıöşü]+)['’](?P<ek>[a-zçğıöşü]+)")
_DT_EKI = re.compile(r'^(?:[dt][aeıiuü](?:n|ki)?|[dt][ıiuü]r)$')


def _uyumla(kok, ek):
    """Ek, sayı yerine bir sözcüğe bağlanınca yeniden uyumlanmalı: « yıldız »
    ötümlü z ile biter, bu yüzden -tir değil -dır olur."""
    v = UYUM[_son_sesli(kok)]
    sert = kok[-1] in SESSIZ_SERT
    d = 't' if sert else 'd'
    aile = {'tir': d + v + 'r', 'dir': d + v + 'r', 'te': d + ('a' if v in 'ıu' else 'e'),
            'de': d + ('a' if v in 'ıu' else 'e'), 'ta': d + ('a' if v in 'ıu' else 'e'),
            'da': d + ('a' if v in 'ıu' else 'e'),
            'ten': d + ('a' if v in 'ıu' else 'e') + 'n', 'den': d + ('a' if v in 'ıu' else 'e') + 'n',
            'tan': d + ('a' if v in 'ıu' else 'e') + 'n', 'dan': d + ('a' if v in 'ıu' else 'e') + 'n'}
    kural = re.sub(r'[ıiuü]', lambda m: 'i', ek)
    for k, sonuc in aile.items():
        if re.sub(r'[ıiuü]', 'i', k) == kural:
            return kok + sonuc
    return _ek_ekle(kok, ek)


def fix_ek_apostrof(t, cid, log):
    def rep(m):
        kok, ek = m.group('kok'), m.group('ek')
        if kok not in PIPELINE_SOZCUKLERI:
            return m.group(0)      # kaynağın yazımı doğrudur
        # Sözcük simgenin yerine geçtiği için apostrof her hâlükârda kalkar:
        # « kilometre'den » değil « kilometreden ».
        if _DT_EKI.match(ek):
            kuyruk = 'ki' if ek.endswith('ki') else ''
            out = _uyumla(kok, ek[: len(ek) - len(kuyruk)]) + kuyruk
        else:
            out = _ek_ekle(kok, ek)
        log(cid, 'ek', m.group(0), out)
        return out
    return EK_APOSTROF.sub(rep, t)


def normalize(t, cid, log):
    t = fix_era(t, cid, log)
    t = fix_hukumdar(t, cid, log)
    t = fix_saat(t, cid, log)
    t = fix_sira_aralik(t, cid, log)
    t = fix_sira(t, cid, log)
    t = fix_yuzde(t, cid, log)
    t = fix_birimler(t, cid, log)
    t = fix_designator(t, cid, log)
    t = fix_aralik(t, cid, log)
    return fix_ek_apostrof(fix_sayilar(t, cid, log), cid, log)


def respell(t, cid, log):
    return t


KISALTMA = {'MC', 'DJ', 'CD', 'DVD'}


def extra_checks(bare):
    found = []
    for sym in ('%', '°', '/', '=', '+', '$', '€', '£', '₂', '²', '³', '&'):
        if sym in bare:
            found.append(('simge', sym))
    for m in re.finditer(r'\b[IVXLCDM]{2,}\b', bare):
        if m.group(0) not in KISALTMA:
            found.append(('romalı', m.group(0)))
    return found
