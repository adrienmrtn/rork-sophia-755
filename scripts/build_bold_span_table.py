#!/usr/bin/env python3
"""Compose ``scripts/bold_span_translations.json``.

The table is easier to read and to extend as "one span, every language that
needs it" than as the per-language replacement lists the applier wants, so it is
written that way here and flattened on the way out. Run this after editing
SPANS, PHRASES, CASE or KEEP, then run
``scripts/fix_untranslated_bold_spans.py``.
"""

import json
import pathlib

# span -> {lang: rendering}. The applier swaps "**span**" for "**rendering**".
SPANS = {
    "The Red and the Black": {
        "ro": "Roșu și negru", "nl": "Het rood en het zwart",
        "el": "Το Κόκκινο και το Μαύρο", "sv": "Rött och svart",
        "hu": "Vörös és fekete", "bg": "Червено и черно",
        "cs": "Červený a černý", "da": "Rødt og sort", "nb": "Rødt og svart",
        "ru": "Красное и чёрное", "hr": "Crveno i crno",
        "sk": "Červený a čierny", "sr": "Crveno i crno",
        "he": "האדום והשחור", "fi": "Punainen ja musta", "et": "Punane ja must",
    },
    "One Thousand and One Nights": {
        "el": "Χίλιες και Μία Νύχτες", "sv": "Tusen och en natt",
        "da": "Tusind og en nat", "nb": "Tusen og én natt",
        "fi": "Tuhat ja yksi yötä", "et": "Tuhat ja üks ööd",
    },
    "<The energy transition>": {
        "tr": "Enerji dönüşümü", "pl": "Transformacja energetyczna",
        "ro": "Tranziția energetică", "sv": "Energiomställningen",
        "bg": "Енергийният преход", "cs": "Energetická transformace",
        "da": "Energiomstillingen", "nb": "Energiomstillingen",
        "ru": "Энергетический переход", "hr": "Energetska tranzicija",
        "sl": "Energetski prehod", "sk": "Energetická transformácia",
        "sr": "Energetska tranzicija", "fi": "Energiamurros",
        "et": "Energiapööre", "en": "energy transition",
    },
    "<The future of work>": {
        "tr": "İşin geleceği", "pl": "Przyszłość pracy", "ro": "Viitorul muncii",
        "sv": "Arbetets framtid", "bg": "Бъдещето на труда",
        "cs": "Budoucnost práce", "da": "Arbejdets fremtid",
        "nb": "Arbeidets fremtid", "ru": "Будущее труда",
        "hr": "Budućnost rada", "sl": "Prihodnost dela",
        "sk": "Budúcnosť práce", "sr": "Budućnost rada",
        "fi": "Työn tulevaisuus", "et": "Töö tulevik", "en": "future of work",
    },
    "Belt and Road Initiative": {
        "es": "Iniciativa de la Franja y la Ruta", "de": "Neue Seidenstraße",
        "pt": "Iniciativa do Cinturão e Rota", "it": "Nuova via della seta",
        "tr": "Kuşak ve Yol Girişimi", "nl": "Belt and Road-initiatief",
        "el": "Πρωτοβουλία Ζώνη και Δρόμος", "sv": "Bälte- och väginitiativet",
        "hu": "Övezet és Út kezdeményezés", "bg": "Един пояс, един път",
        "cs": "Pás a stezka", "da": "Bælte- og vejinitiativet",
        "nb": "Belte- og vei-initiativet", "sl": "Pas in cesta",
        "sk": "Pás a cesta", "he": "יוזמת החגורה והדרך",
        "fi": "Uusi silkkitie", "et": "Vöö ja tee algatus",
    },
    "Sinbad the Sailor": {
        "ro": "Sinbad Marinarul", "el": "Σεβάχ ο Θαλασσινός",
        "sv": "Sindbad Sjöfararen", "hu": "Szindbád, a tengerész",
        "cs": "Sindibád Námořník", "da": "Sindbad Søfareren",
        "nb": "Sindbad Sjøfareren", "hr": "Sinbad Moreplovac",
        "sl": "Sinbad Pomorščak", "sk": "Sindibád Moreplavec",
        "ar": "السندباد البحري", "fi": "Merenkulkija Sindbad",
        "et": "Meremees Sindbad",
    },
    "Seven Voyages of Sinbad the Sailor": {
        "nl": "Zeven reizen van Sindbad de Zeeman",
        "el": "Επτά Ταξίδια του Σεβάχ του Θαλασσινού",
        "sv": "Sindbad Sjöfararens sju resor", "hu": "Szindbád hét utazása",
        "bg": "Седемте пътешествия на Синдбад Мореплавателя",
        "da": "Sindbad Søfarerens syv rejser",
        "nb": "Sindbad Sjøfarerens syv reiser",
        "sl": "sedmih potovanj Sinbada Pomorščaka",
        "he": "שבעת מסעות סינבאד הימאי",
        "fi": "Merenkulkija Sindbadin seitsemän matkaa",
    },
    "Liberty Leading the People": {
        "ro": "Libertatea conducând poporul", "el": "Η Ελευθερία οδηγεί τον λαό",
        "sv": "Friheten leder folket", "cs": "Svoboda vede lid",
        "da": "Friheden fører folket", "nb": "Friheten leder folket",
        "hr": "Sloboda vodi narod", "sk": "Sloboda vedie ľud",
        "ar": "الحرية تقود الشعب", "he": "החירות מובילה את העם",
        "fi": "Vapaus johtaa kansaa", "et": "Vabadus juhib rahvast",
        "nl": "De Vrijheid leidt het volk", "hu": "A Szabadság vezeti a népet",
    },
    "John the Savage": {
        "ro": "John Sălbaticul", "el": "Τζον ο Άγριος", "sv": "John Vilden",
        "bg": "Джон Дивака", "da": "John Vilden", "nb": "John Villmannen",
        "ar": "جون المتوحش", "he": "ג'ון הפרא", "fi": "John Villi",
    },
    "Concerning the Spiritual in Art": {
        "ro": "Despre spiritual în artă", "nl": "Over het geestelijke in de kunst",
        "sv": "Om det andliga i konsten", "hu": "A szellemiség a művészetben",
        "cs": "O duchovnosti v umění", "da": "Om det åndelige i kunsten",
        "nb": "Om det åndelige i kunsten", "he": "על הרוחני באמנות",
        "fi": "Taiteen henkisestä sisällöstä",
    },
    "Fellowship of the Ring": {
        "el": "Αδελφότητα του Δαχτυλιδιού", "sv": "Ringens brödraskap",
        "bg": "Задругата на пръстена", "da": "Ringens broderskab",
        "nb": "Ringens brorskap",
    },
    "Book of the Dead": {
        "ro": "Cartea Morților", "nl": "Dodenboek", "el": "Βίβλο των Νεκρών",
        "sv": "Dödboken", "da": "Dødebogen", "nb": "Dødeboken",
    },
    "Old Man of the Sea": {
        "ro": "Bătrânul Mării", "nl": "Oude Man van de Zee",
        "el": "Γέρο της Θάλασσας", "sv": "Havets gamle man",
        "nb": "Havets gamle mann", "he": "זקן הים",
    },
    "Cartel of the Seven Sisters": {
        "el": "Καρτέλ των Επτά Αδελφών", "sv": "De sju systrarnas kartell",
        "bg": "картела на седемте сестри", "da": "De syv søstres kartel",
        "nb": "De syv søstres kartell", "ar": "كارتل الأخوات السبع",
        "he": "קרטל שבע האחיות",
    },
    "Lancelot of the Lake": {
        "ro": "Lancelot al Lacului", "nl": "Lancelot van het Meer",
        "bg": "Ланселот от Езерото", "ar": "لانسلوت البحيرة",
    },
    '"The Raft of the Medusa"': {
        "nl": "Het vlot van de Medusa", "el": "Η σχεδία της Μέδουσας",
        "sv": "Medusas flotte", "da": "Medusas flåde", "nb": "Medusas flåte",
        "fi": "Medusan lautta",
    },
    '"On the Origin of Species"': {
        "nl": "Over het ontstaan van soorten", "el": "Η Καταγωγή των Ειδών",
        "sv": "Om arternas uppkomst", "da": "Arternes oprindelse",
        "nb": "Artenes opprinnelse",
    },
    "Rape of the Sabine Women": {
        "el": "Αρπαγή των Σαβίνων", "sv": "Sabinskornas bortrövande",
        "da": "Sabinerindernes rov", "nb": "Sabinerinnenes rov",
        "he": "חטיפת הנשים הסביניות",
    },
    "Admiral of the Ocean Sea": {
        "sv": "Amiral över Oceanhavet", "da": "Admiral over Oceanhavet",
        "nb": "Admiral over Oseanhavet", "he": "אדמירל הים האוקייני",
    },
    "year without a summer": {
        "sv": "året utan sommar", "hu": "nyár nélküli év",
        "da": "året uden sommer", "nb": "året uten sommer",
    },
    "the albatros": {
        "sv": "albatrossen", "da": "albatrossen", "nb": "albatrossen",
        "he": "האלבטרוס",
    },
    "Court of Justice of the European Union": {
        "sv": "EU-domstolen", "da": "EU-Domstolen", "nb": "EU-domstolen",
        "he": "בית הדין של האיחוד האירופי",
    },
    "the hippocampus": {"sv": "hippocampus", "da": "hippocampus", "nb": "hippocampus"},
    "less than five weeks": {
        "sv": "mindre än fem veckor", "da": "mindre end fem uger",
        "nb": "mindre enn fem uker",
    },
    "Apples of the Hesperides": {
        "sv": "Hesperidernas äpplen", "da": "Hesperidernes æbler",
        "nb": "Hesperidenes epler",
    },
    "the general de Gaulle": {"sv": "general de Gaulle", "da": "general de Gaulle"},
    "repair and refurbishment": {
        "sv": "reparation och renovering", "da": "reparation og renovering",
    },
    "Pact on Migration and Asylum": {
        "sv": "migrations- och asylpakt", "nb": "migrasjons- og asylpakt",
    },
    "Pieter Bruegel the Elder": {
        "bg": "Питер Брьогел Стари", "ar": "بيتر بروغل الأكبر",
    },
    "crime against humanity": {
        "nb": "forbrytelse mot menneskeheten", "he": "פשע נגד האנושות",
    },
    "Soul of the World": {"nb": "Verdenssjelen", "fi": "Maailmansielu"},
    "Pliny the Elder": {"ar": "بليني الأكبر", "he": "פליניוס הזקן"},
    "Declaration of the Rights of Man and of the Citizen": {
        "sv": "deklarationen om människans och medborgarens rättigheter",
    },
    "assault on the Capitol": {"da": "stormen på Kapitol"},
    "riddle of the Sphinx": {"nb": "Sfinxens gåte"},
    "Tensions with the West": {"nb": "Spenningene med Vesten"},
    "descent with modification": {"he": "מוצא עם שינוי"},
    # Plain mentions of the painting elsewhere in the same course, where only
    # the English article is left to drop.
    "the Mona Lisa": {
        "da": "Mona Lisa", "el": "Μόνα Λίζα", "et": "Mona Lisa", "fi": "Mona Lisa",
        "he": "המונה ליזה", "hu": "Mona Lisa", "nb": "Mona Lisa", "sv": "Mona Lisa",
    },
    '"Liberty Leading the People"': {
        "da": '"Friheden fører folket"', "el": '"Η Ελευθερία οδηγεί τον λαό"',
        "et": '"Vabadus juhib rahvast"', "fi": '"Vapaus johtaa kansaa"',
        "he": '"החירות מובילה את העם"', "hu": '"A Szabadság vezeti a népet"',
        "nb": '"Friheten leder folket"', "nl": '"De Vrijheid leidt het volk"',
        "sv": '"Friheten leder folket"',
    },
}
SPANS["Lancelot of the Lake"]["tr"] = "Göl Şövalyesi Lancelot"
SPANS["Lancelot of the Lake"]["nb"] = "Lancelot av Sjøen"

#: Replacements that have to carry the words around the span, because the
#: sentence needs fixing too, not just the title inside it.
PHRASES = {
    # "The execution of the Mona Lisa" -- the engine read "execution" as a
    # death sentence in thirteen languages, so the whole clause is rewritten.
    "en": [
        ("The execution of the **the Mona Lisa** begins",
         "The painting of the **Mona Lisa** begins"),
        ("the beginning of the **« <War of the currents (Edison vs Tesla)> »**",
         "the beginning of the **war of the currents (Edison vs Tesla)**"),
    ],
    "es": [("La ejecución de La Gioconda comienza", "La realización de La Gioconda comienza")],
    "nl": [("De uitvoering van de **de Mona Lisa** begint", "De uitvoering van de **Mona Lisa** begint")],
    "tr": [("**Mona Lisa**'nin infazı Floransa'da", "**Mona Lisa**'nın yapımı Floransa'da")],
    "pl": [("Egzekucja **Mony Lisy** rozpoczyna się", "Powstawanie **Mony Lisy** rozpoczyna się")],
    "ro": [("Execuția **Mona Lisa** începe", "Realizarea **Mona Lisei** începe")],
    "bg": [("Екзекуцията на **Мона Лиза** започва", "Създаването на **Мона Лиза** започва")],
    "ru": [("Казнь **Моны Лизы** начинается", "Создание **Моны Лизы** начинается")],
    "sl": [("Usmrtitev **Mone Lise** se začne", "Nastajanje **Mone Lise** se začne")],
    "ar": [("يبدأ تنفيذ لوحة الموناليزا **Z** في فلورنسا",
            "يبدأ تنفيذ لوحة الموناليزا في فلورنسا")],
    "el": [("Η εκτέλεση της **the Mona Lisa** ξεκινά", "Η δημιουργία της **Μόνα Λίζα** ξεκινά")],
    "sv": [("Avrättningen av **the Mona Lisa** börjar", "Arbetet med **Mona Lisa** inleds")],
    "hu": [("A **the Mona Lisa** végrehajtása Firenzében kezdődik",
            "A **Mona Lisa** megfestése Firenzében kezdődik"),
           ("A **Ezeregyéjszaka**-től elválaszthatatlan", "Az **Ezeregyéjszakától** elválaszthatatlan")],
    "cs": [("Poprava **the Mona Lisa** začíná", "Vznik **Mony Lisy** začíná"),
           ("Ve hře **The Red and the Black**", "V románu **Červený a černý**"),
           ("**OTisíc a jedné noci**", "**Tisíce a jedné noci**"),
           ("popsaný v **Book of the Dead**", "popsaný v **Knize mrtvých**")],
    "da": [("Henrettelsen af **the Mona Lisa** begynder", "Arbejdet med **Mona Lisa** begynder"),
           ("konfronterer Sinbad den **Old Man of the Sea**",
            "konfronterer Sinbad **Havets gamle mand**")],
    "nb": [("Henrettelsen av **the Mona Lisa** begynner", "Arbeidet med **Mona Lisa** begynner")],
    "sk": [("Poprava **the Mona Lisa** sa začína", "Vznik **Mony Lisy** sa začína"),
           ("Vo filme **The Red and the Black**", "V románe **Červený a čierny**"),
           ("**OTisíc a jednej noci**", "**Tisíc a jednej noci**")],
    "he": [("ההוצאה להורג של **the Mona Lisa** מתחילה", "העבודה על **המונה ליזה** מתחילה")],
    "fi": [("**the Mona Lisa**:n toteuttaminen alkaa", "**Mona Lisan** maalaaminen alkaa"),
           ("**Tuhat ja yksi yö**:stä erottamaton kokonaisuus",
            "**Tuhannen ja yhden yön** erottamaton hahmo")],
    "et": [("**the Mona Lisa** hukkamine algab", "**Mona Lisa** maalimine algab"),
           ("**Tuhat ja üks ööst** lahutamatu üksus", "**Tuhande ja ühe öö** lahutamatu osa")],
    "hr": [("**OTisuću i jedne noći**", "**Tisuću i jedne noći**"),
           ("dolaskom **John the Savage**", "dolaskom **Johna Divljaka**")],
    "sr": [],
}
PHRASES["sl"].append(("**OTisoč in ene noči**", "**Tisoč in ene noči**"))
PHRASES["sl"].append(("prihod **John the Savage**", "prihod **Johna Divjaka**"))
PHRASES["sl"].append(("**Lancelot of the Lake**", "**Lancelota Jezerskega**"))
PHRASES["ro"].append(("formarea **Fellowship of the Ring**", "formarea **Frăției Inelului**"))
PHRASES["nl"].append(("van de **Fellowship of the Ring**", "van het **Reisgenootschap van de Ring**"))


# Sites where the replacement has to take the case the sentence governs, which
# a bare swap of the title would not: "the beginning of the war of the currents"
# is a genitive in Czech, Slovene, Russian, Romanian and Greek, and "in The Red
# and the Black" a locative in Croatian, Serbian and Russian.
CASE = {
    "cs": [("začátek **« <War of the currents (Edison vs Tesla)> »**",
            "začátek **války proudů (Edison vs. Tesla)**")],
    "sl": [("začetek **« <War of the currents (Edison vs Tesla)> »**",
            "začetek **vojne tokov (Edison proti Tesli)**")],
    "ru": [("начало **« <War of the currents (Edison vs Tesla)> »**",
            "начало **войны токов (Эдисон против Теслы)**"),
           ("В **The Red and the Black** каждому", "В **Красном и чёрном** каждому")],
    "ro": [("începutul **« <War of the currents (Edison vs Tesla)> »**",
            "începutul **Războiului curenților (Edison vs Tesla)**")],
    "hr": [("U **The Red and the Black** svakoj", "U **Crvenom i crnom** svakoj")],
    "sr": [("U **The Red and the Black**, svakoj", "U **Crvenom i crnom**, svakoj")],
    "el": [("η αρχή του **« <War of the currents (Edison vs Tesla)> »**",
            "η αρχή του **Πολέμου των ρευμάτων (Έντισον εναντίον Τέσλα)**"),
           ("Ιουλίου, το **The Red and the Black** είναι",
            "Ιουλίου, **Το Κόκκινο και το Μαύρο** είναι"),
           ("Στο **The Red and the Black**, κάθε", "Στο **Κόκκινο και το Μαύρο**, κάθε"),
           ('η δημοσίευση του **"On the Origin of Species"** από',
            "η δημοσίευση της **Καταγωγής των Ειδών** από"),
           ("με την άφιξη του **John the Savage**", "με την άφιξη του **Τζον του Άγριου**"),
           ("στον σχηματισμό της **Fellowship of the Ring**",
            "στον σχηματισμό της **Αδελφότητας του Δαχτυλιδιού**"),
           ("περιγράφεται στο **Book of the Dead**", "περιγράφεται στη **Βίβλο των Νεκρών**"),
           ("Το « **Liberty Leading the People**» (1830)",
            "**Η Ελευθερία οδηγεί τον λαό** (1830)"),
           ("Η δομή των **Seven Voyages of Sinbad the Sailor**",
            "Η δομή των **Επτά Ταξιδιών του Σεβάχ του Θαλασσινού**"),
           ("Το **Belt and Road Initiative** (BRI)", "Η **Πρωτοβουλία Ζώνη και Δρόμος** (BRI)"),
           ("Η συλλογή των **One Thousand and One Nights** (Alf Layla wa-Layla)",
            "Η συλλογή **Χίλιες και Μία Νύχτες** (Alf Layla wa-Layla)")],
    "hu": [("Ez volt a **« <War of the currents (Edison vs Tesla)> »** kezdete",
            "Ez volt **az áramok háborújának (Edison kontra Tesla)** kezdete"),
           ("hozta létre a \u201e**year without a summer**\u201d",
            "hozta létre a \u201e**nyár nélküli évet**\u201d"),
           ("fő kiáltványát, a **Concerning the Spiritual in Art** címet, amelyben",
            "fő kiáltványát, **A szellemiség a művészetben** címmel, amelyben"),
           ("entitás, a **Sinbad the Sailor** azonban", "entitás, **Szindbád, a tengerész** azonban"),
           ("körútja után **the Mona Lisa** 1914", "körútja után **a Mona Lisa** 1914")],
}
for _lang, _pairs in CASE.items():
    PHRASES.setdefault(_lang, [])
    PHRASES[_lang] = _pairs + PHRASES[_lang]

#: The war of the currents, one glossary link that names no entry in any
#: glossary, so the link is dropped and the phrase translated.
CURRENTS = {
    "tr": "Akım Savaşları (Edison'a karşı Tesla)",
    "pl": "wojny prądów (Edison kontra Tesla)",
    "ro": "Războiul curenților (Edison vs Tesla)",
    "el": "Πόλεμος των ρευμάτων (Έντισον εναντίον Τέσλα)",
    "sv": "strömkriget (Edison mot Tesla)",
    "hu": "az áramok háborúja (Edison kontra Tesla)",
    "bg": "войната на токовете (Едисон срещу Тесла)",
    "cs": "válka proudů (Edison vs. Tesla)",
    "da": "strømkrigen (Edison mod Tesla)",
    "nb": "strømkrigen (Edison mot Tesla)",
    "ru": "война токов (Эдисон против Теслы)",
    "sl": "vojna tokov (Edison proti Tesli)",
}

KEEP = {
    "Blowin' in the Wind": "a Bob Dylan song, named in the original everywhere",
    "Grandmaster Flash and the Furious Five": "the group's name",
    "<rhythm and blues>": "the genre, and the link resolves against a glossary entry registered under that name",
    "[[search and destroy]]": "the doctrine's name, which the French source keeps in the original too, glossed in the sentence that follows it",
    "checks and balances": "a loan phrase Danish, Swedish, Norwegian and Dutch political writing uses as it stands; Hebrew takes איזונים ובלמים below",
}


def build() -> dict:
    out: dict[str, list[list[str]]] = {}
    for span, by_lang in SPANS.items():
        for lang, rendering in by_lang.items():
            out.setdefault(lang, []).append([f"**{span}**", f"**{rendering}**"])
    for lang, rendering in CURRENTS.items():
        out.setdefault(lang, []).append(
            [f"**« <War of the currents (Edison vs Tesla)> »**", f"**{rendering}**"]
        )
    out.setdefault("he", []).append(["**checks and balances**", "**איזונים ובלמים**"])
    # Phrase replacements run first, so the clause they rewrite is still intact.
    for lang, pairs in PHRASES.items():
        if pairs:
            out[lang] = [list(p) for p in pairs] + out.get(lang, [])
    return {lang: out[lang] for lang in sorted(out)}


payload = {
    "_comment": [
        "Bold spans the engine handed back as the English it was given.",
        "Each language's list is applied in order, longest match first, to every",
        "lesson body: the catalogue, CoursesV2 and content/courses.",
        "Most entries swap the span alone. The ones that carry words around it",
        "are fixing the sentence too -- the engine read the 'execution' of the",
        "Mona Lisa as a death sentence in thirteen languages, and left a stray O",
        "in front of 'Tisic a jedne noci' where it moved 'One' out of the title.",
        "English is in here as well: it is the pack every other language is",
        "translated from, and it is where the doubled article in",
        "'the **the Mona Lisa**' and the two links naming no glossary entry",
        "('<The energy transition>', '<The future of work>') come from.",
    ],
    "keep": KEEP,
    "replacements": build(),
}

path = pathlib.Path(__file__).resolve().parent / "bold_span_translations.json"
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{sum(len(v) for v in payload['replacements'].values())} replacements "
      f"across {len(payload['replacements'])} languages")
