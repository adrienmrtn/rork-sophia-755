#!/usr/bin/env python3
"""Hand-written UI strings for the Slovenian, Slovak and Serbian tables.

Companion to ``new_locales_ui_data`` (Danish / Norwegian / Russian / Croatian);
both are merged by ``apply_new_locales.py``. Kept in a separate module so the
first four locales stay reviewable as written, rather than being reflowed into
seven-column rows.

Voice, fixed once and held across all 824 keys:

  sl  Slovenian — informal "ti", matching the French tutoiement. tečaj, kviz,
      raven (a gamified level, not "stopnja"), niz for a streak, knjižnica.
      Practice section = "Ponavljanje". Quotes: »…«, the modern Slovenian
      typographic pair.
  sk  Slovak — informal "ty". kurz, kvíz, úroveň, "dní v rade" for a streak,
      knižnica. Practice section = "Opakovanie". Quotes: „…“.
  sr  Serbian — informal "ti", Latin script and Ekavian, the standard of
      Serbia: "lepo", "vreme", "gde". kurs, kviz, nivo, "dana zaredom",
      biblioteka. Practice section = "Ponavljanje". Quotes: „…“.
      On the script: Serbian is written in both alphabets officially and this
      table was drafted in Cyrillic. It ships in Latin because the course
      catalog has to — Google's Serbian engine transliterates unfamiliar
      Latin proper nouns letter by letter ("Paul Verlaine" → "Паул Верлаине"),
      and converting its output back to Latin is exactly what restores them.
      UI and content then agree on one script. See ``scripts/serbian_script.py``.

Brand names (Sophia, Premium, Pro, App Store, XP) stay UNDECLINED in Serbian —
"uz Sophia", never "Sophijom" — exactly as the Russian table treats them.
Sentences are worded so the brand never needs a case ending, which is also why
the table survived the script conversion untouched. Slovenian and Slovak
decline it normally instead ("s Sophio", "so Sophiou"). Testimonial first names
are transcribed in Serbian only (Lea, Kamij, Janis, Ines, Toma, Sara, Malik),
exactly as in the Russian table.

Counting: a standalone count chip takes the genitive plural after the numeral
in sl/sk/sr, matching the Polish and Czech tables already in the app; the
Russian "Noun: %d" form is not used here because it reads foreign in these
three.
"""

from __future__ import annotations

LANGS3 = ["sl", "sk", "sr"]


def row3(sl: str, sk: str, sr: str) -> dict[str, str]:
    return {"sl": sl, "sk": sk, "sr": sr}


STRINGS3: dict[str, dict[str, str]] = {}

# --- tabs + the Practice (Entraînement) section ---------------------------
STRINGS3.update({
    "tab.home": row3("Domov", "Domov", "Početna"),
    "tab.library": row3("Knjižnica", "Knižnica", "Biblioteka"),
    "tab.collections": row3("Zbirke", "Zbierky", "Zbirke"),
    "tab.profile": row3("Profil", "Profil", "Profil"),
    "tab.training": row3("Ponavljanje", "Opakovanie", "Ponavljanje"),
    "training.title": row3("Ponavljanje", "Opakovanie", "Ponavljanje"),
    "training.readyTitle": row3(
        "Čas je za ponavljanje", "Čas na opakovanie", "Vreme je za ponavljanje"),
    "training.dueCount": row3(
        "%d vprašanj za ponovitev danes", "%d otázok na dnešné opakovanie",
        "%d pitanja za ponavljanje danas"),
    "training.emptyTitle": row3(
        "Vse je opravljeno!", "Všetko máš hotové!", "Sve je odrađeno!"),
    "training.emptyMessage": row3(
        "Vrni se jutri in nadaljuj s ponavljanjem.",
        "Vráť sa zajtra a pokračuj v opakovaní.",
        "Vrati se sutra i nastavi sa ponavljanjem."),
    "training.locked.title": row3(
        "Odkleni Ponavljanje", "Odomkni Opakovanie", "Otključaj Ponavljanje"),
    "training.locked.message": row3(
        "Reši kviz nekega tečaja in njegova vprašanja pristanejo tukaj — ponovil jih boš točno takrat, ko je treba.",
        "Dokonči kvíz niektorého kurzu a jeho otázky pristanú tu — zopakuješ si ich presne vtedy, keď treba.",
        "Uradi kviz nekog kursa i njegova pitanja stižu ovde — ponovićeš ih tačno kada treba."),
    "training.locked.tagline": row3(
        "Zapomni si, kar se učiš — zares.",
        "Zapamätaj si, čo sa učíš — natrvalo.",
        "Zapamti ono što učiš, zaista."),
    "training.unlock": row3(
        "Odkleni Ponavljanje", "Odomknúť Opakovanie", "Otključaj Ponavljanje"),
    "training.discover": row3("Odkrij", "Objaviť", "Otkrij"),
    "training.how.title": row3(
        "KAKO DELUJE", "AKO TO FUNGUJE", "KAKO FUNKCIONIŠE"),
    "training.how.step1": row3(
        "Dokončaj tečaj in njegov kviz", "Dokonči kurz a jeho kvíz",
        "Završi kurs i njegov kviz"),
    "training.how.step2": row3(
        "Njegova vprašanja gredo v Ponavljanje",
        "Jeho otázky idú do Opakovania",
        "Njegova pitanja idu u Ponavljanje"),
    "training.how.step3": row3(
        "Ponovi jih v pravem trenutku, da jih ne pozabiš",
        "Zopakuj si ich v pravý čas, aby si ich nezabudol",
        "Ponovi ih u pravom trenutku da ih ne zaboraviš"),
    "training.emptyCta": row3("Odkrij tečaj", "Objaviť kurz", "Otkrij kurs"),
    "training.ob.welcome.line": row3(
        "To je Ponavljanje.", "Toto je Opakovanie.", "Ovo je Ponavljanje."),
    "training.ob.recall.title": row3(
        "Sprašujemo te, da naučeno res ostane.",
        "Pýtame sa ťa, aby ti naučené naozaj zostalo.",
        "Postavljamo ti pitanja da naučeno zaista ostane."),
    "training.ob.recall.legend.sophia": row3(
        "S Sophio", "So Sophiou", "Uz Sophia"),
    "training.ob.recall.legend.reread": row3(
        "Navadno ponovno branje", "Obyčajné opätovné čítanie",
        "Obično ponovno čitanje"),
    "training.ob.recall.stat.prefix": row3(
        "Po enem tednu si redni uporabniki Sophia Ponavljanja zapomnijo",
        "Po týždni si pravidelní používatelia Sophia Opakovania pamätajú",
        "Posle nedelju dana redovni korisnici Sophia Ponavljanja pamte"),
    "training.ob.recall.stat.highlight": row3(
        "2,2× več", "2,2× viac", "2,2× više"),
    "training.ob.recall.stat.suffix": row3(
        "snovi svojih tečajev kot tisti, ki ga ne uporabljajo.",
        "z učiva svojich kurzov než ten, kto ho nepoužíva.",
        "gradiva svojih kurseva nego onaj ko ga ne koristi."),
    "training.ob.recall.cta": row3(
        "Kako deluje", "Ako to funguje", "Kako funkcioniše"),
    "training.ob.algo.title": row3(
        "Algoritem te sprašuje neprestano", "Algoritmus ťa skúša neustále",
        "Algoritam te ispituje neprestano"),
    "training.ob.algo.body": row3(
        "Vračamo ti kvize, ki si jih že rešil, točno ob pravem času. Vsi so zbrani tukaj.",
        "Vraciame ti kvízy, ktoré si už vyriešil, presne načas. Všetky sú tu na jednom mieste.",
        "Vraćamo ti kvizove koje si već uradio, tačno na vreme. Svi su ovde, na jednom mestu."),
})

# --- training session chrome, library chrome, language picker --------------
# Language names are autonyms: identical in every table, including these three.
STRINGS3.update({
    "training.ob.algo.highlight.value": row3(
        "5 min/dan", "5 min/deň", "5 min/dan"),
    "training.ob.algo.highlight.label": row3(
        "za spomin, ki res zdrži.",
        "pre pamäť, ktorá naozaj vydrží.",
        "za pamćenje koje stvarno traje."),
    "training.ob.cta.last": row3("Naprej", "Pokračovať", "Nastavi"),
    "training.start": row3("Začni", "Začať", "Počni"),
    "training.finish": row3("Končaj", "Dokončiť", "Završi"),
    "training.backToTraining": row3("Nazaj", "Späť", "Nazad"),
    "training.sessionComplete.title": row3(
        "Konec kroga", "Opakovanie hotové", "Kraj kruga"),
    "training.sessionComplete.summary": row3(
        "%d pravilnih od %d", "%d správne z %d", "%d tačnih od %d"),
    "library.title": row3("Knjižnica", "Knižnica", "Biblioteka"),
    "library.tab.courses": row3("Tečaji", "Kurzy", "Kursevi"),
    "library.tab.collections": row3("Zbirke", "Zbierky", "Zbirke"),
    "library.search.placeholder": row3(
        "Poišči tečaj...", "Nájdi kurz...", "Pronađi kurs..."),
    "language.section": row3("Jezik", "Jazyk", "Jezik"),
    "language.french": row3("Français", "Français", "Français"),
    "language.english": row3("English", "English", "English"),
    "language.spanish": row3("Español", "Español", "Español"),
    "language.german": row3("Deutsch", "Deutsch", "Deutsch"),
    "language.portuguese": row3("Português", "Português", "Português"),
    "language.italian": row3("Italiano", "Italiano", "Italiano"),
    "language.turkish": row3("Türkçe", "Türkçe", "Türkçe"),
    "language.polish": row3("Polski", "Polski", "Polski"),
    "language.romanian": row3("Română", "Română", "Română"),
    "language.dutch": row3("Nederlands", "Nederlands", "Nederlands"),
    "language.greek": row3("Ελληνικά", "Ελληνικά", "Ελληνικά"),
    "language.swedish": row3("Svenska", "Svenska", "Svenska"),
    "language.hungarian": row3("Magyar", "Magyar", "Magyar"),
    "language.bulgarian": row3("Български", "Български", "Български"),
    "language.czech": row3("Čeština", "Čeština", "Čeština"),
    "onboarding.intro.title": row3(
        "Postani razgledan\nv 10 minutah\nna dan",
        "Staň sa rozhľadeným\nza 10 minút\ndenne",
        "Postani načitan\nza 10 minuta\ndnevno"),
    "onboarding.intro.cta": row3("Začni", "Poďme na to", "Kreni"),
    "onboarding.language.title": row3(
        "Izberi svoj jezik", "Vyber si jazyk", "Izaberi svoj jezik"),
    "onboarding.language.subtitle": row3(
        "Pozneje ga lahko zamenjaš.", "Neskôr ho môžeš zmeniť.",
        "Kasnije ga možeš promeniti."),
})

# --- auth, account, sync conflict, onboardingV2 opening -------------------
STRINGS3.update({
    "discount.sideTab.label": row3("PONUDBA", "PONUKA", "PONUDA"),
    "auth.error.token": row3(
        "Prijava ni uspela. Poskusi znova.",
        "Prihlásenie zlyhalo. Skús to znova.",
        "Prijava nije uspela. Pokušaj ponovo."),
    "auth.error.generic": row3(
        "Nekaj je šlo narobe. Poskusi znova.",
        "Niečo sa pokazilo. Skús to znova.",
        "Nešto je pošlo naopako. Pokušaj ponovo."),
    "auth.continueWithApple": row3(
        "Nadaljuj z Apple", "Pokračovať s Apple", "Nastavi sa Apple"),
    "auth.continueWithGoogle": row3(
        "Nadaljuj z Google", "Pokračovať s Google", "Nastavi sa Google"),
    "auth.onboarding.title": row3(
        "Ustvari račun\nin začni", "Vytvor si účet\na začni",
        "Napravi nalog\ni kreni"),
    "auth.onboarding.subtitle": row3(
        "Prijavi se, da shraniš napredek in ga imaš na vseh napravah.",
        "Prihlás sa, aby si mal postup uložený a dostupný na všetkých zariadeniach.",
        "Prijavi se da sačuvaš napredak i imaš ga na svim uređajima."),
    "auth.legal.prefix": row3(
        "Z nadaljevanjem sprejmeš naše", "Pokračovaním súhlasíš s našimi",
        "Nastavljanjem prihvataš naše"),
    "account.title": row3("Račun", "Účet", "Nalog"),
    "account.signedIn.title": row3("Moj račun", "Môj účet", "Moj nalog"),
    "account.manage.subtitle": row3(
        "Upravljaj svoj račun", "Spravuj svoj účet", "Upravljaj nalogom"),
    "account.create.title": row3(
        "Ustvari račun", "Vytvor si účet", "Napravi nalog"),
    "account.create.subtitle": row3(
        "Shrani napredek v oblak", "Zálohuj svoj postup do cloudu",
        "Sačuvaj napredak u oblaku"),
    "account.signedOut.headline": row3(
        "Shrani svoj napredek", "Zálohuj svoj postup", "Sačuvaj svoj napredak"),
    "account.signedOut.body": row3(
        "Ustvari račun, da shraniš napredek in ga imaš na vseh napravah. Ni obvezno.",
        "Vytvor si účet, aby si mal postup uložený a dostupný na všetkých zariadeniach. Je to dobrovoľné.",
        "Napravi nalog da sačuvaš napredak i imaš ga na svim uređajima. Nije obavezno."),
    "account.email": row3("E-pošta", "E-mail", "Imejl"),
    "account.provider": row3(
        "Prijavljen prek", "Prihlásený cez", "Prijavljen preko"),
    "account.signOut.action": row3("Odjava", "Odhlásiť sa", "Odjava"),
    "account.signOut.title": row3("Se odjaviš?", "Odhlásiť sa?", "Odjaviti se?"),
    "account.signOut.message": row3(
        "Tvoj napredek ostane shranjen na tej napravi.",
        "Tvoj postup zostane uložený v tomto zariadení.",
        "Tvoj napredak ostaje sačuvan na ovom uređaju."),
    "account.signOut.confirm": row3("Odjava", "Odhlásiť sa", "Odjava"),
    "account.delete.action": row3(
        "Izbriši moj račun", "Zmazať môj účet", "Obriši moj nalog"),
    "account.delete.title": row3(
        "Izbrišeš račun?", "Zmazať účet?", "Obrisati nalog?"),
    "account.delete.message": row3(
        "To je nepovratno. Tvoj račun in povezani podatki bodo izbrisani.",
        "Toto je nevratné. Tvoj účet a súvisiace údaje budú zmazané.",
        "Ovo je nepovratno. Tvoj nalog i povezani podaci biće obrisani."),
    "account.delete.confirm": row3("Izbriši", "Zmazať", "Obriši"),
    "account.delete.error": row3(
        "Brisanje ni uspelo. Poskusi znova.",
        "Zmazanie zlyhalo. Skús to znova.",
        "Brisanje nije uspelo. Pokušaj ponovo."),
    "sync.conflict.title": row3(
        "Najdena sta dva napredka", "Našli sme dva postupy",
        "Pronađena su dva napretka"),
    "sync.conflict.body": row3(
        "Izberi, kateri napredek obdržiš. Drugi bo zamenjan.",
        "Vyber, ktorý postup si necháš. Druhý bude nahradený.",
        "Izaberi koji napredak zadržavaš. Drugi će biti zamenjen."),
    "sync.conflict.local": row3("Ta naprava", "Toto zariadenie", "Ovaj uređaj"),
    "sync.conflict.remote": row3("Tvoj račun", "Tvoj účet", "Tvoj nalog"),
    "sync.conflict.summary": row3(
        "%d tečajev · raven %d · %d dni zapored",
        "%d kurzov · úroveň %d · %d dní v rade",
        "%d kurseva · nivo %d · %d dana zaredom"),
    "onboardingV2.welcome.title": row3(
        "Dobrodošel v Sophii", "Vitaj v Sophii", "Dobro došao u Sophia"),
    "onboardingV2.welcome.subtitle": row3(
        "Vsak dan postani malo bolj razgledan.",
        "Každý deň buď o kúsok rozhľadenejší.",
        "Postani malo pametniji svakog dana."),
    "onboardingV2.welcome.cta": row3("Začni", "Poďme na to", "Kreni"),
    "onboardingV2.language.title": row3(
        "Izberi svoj jezik", "Vyber si jazyk", "Izaberi svoj jezik"),
    "onboardingV2.language.subtitle": row3(
        "Podrsaj in si oglej vse jezike. Pozneje ga lahko zamenjaš.",
        "Potiahni a pozri si všetky jazyky. Neskôr ho môžeš zmeniť.",
        "Prevuci da vidiš sve jezike. Kasnije ga možeš promeniti."),
    "onboardingV2.language.scrollHint": row3(
        "Podrsaj za več jezikov", "Potiahni pre ďalšie jazyky",
        "Prevuci za još jezika"),
    "onboardingV2.objective.title": row3(
        "Kakšni so tvoji cilji?", "Aké sú tvoje ciele?", "Koji su tvoji ciljevi?"),
    "onboardingV2.objective.subtitle": row3(
        "Izbereš lahko več njih.", "Môžeš si vybrať viac.",
        "Možeš izabrati više njih."),
    "onboardingV2.objective.cultivate": row3(
        "Vsak dan se naučiti kaj novega", "Každý deň sa niečo naučiť",
        "Svakog dana naučiti nešto"),
    "onboardingV2.objective.reduceScreen": row3(
        "Zmanjšati čas pred zaslonom", "Tráviť menej času na mobile",
        "Smanjiti vreme pred ekranom"),
    "onboardingV2.objective.exams": row3(
        "Uspeti v šoli in na izpitih", "Zvládnuť školu a skúšky",
        "Uspeti u školi i na ispitima"),
})

# --- onboardingV2: questions, screen time, exams testimonials, swipe ------
# Testimonial first names stay Latin in sl/sk and are transliterated in sr.
# The French school labels (prépa, terminale, L2, lycée) become the nearest
# local stage rather than a literal gloss.
STRINGS3.update({
    "onboardingV2.objective.impress": row3(
        "Zablesteti v družbi", "Zažiariť v spoločnosti", "Zablistati u društvu"),
    "onboardingV2.objective.curiosity": row3(
        "Učiti se iz radovednosti", "Učiť sa zo zvedavosti",
        "Učiti iz radoznalosti"),
    "onboardingV2.objectiveIntro.title": row3(
        "Sophia ti pomaga doseči vse tvoje cilje",
        "Sophia ti pomôže dosiahnuť všetky tvoje ciele",
        "Sophia ti pomaže da ostvariš sve ciljeve"),
    "onboardingV2.tapToContinue": row3(
        "Tapni kamor koli za naprej", "Ťukni kamkoľvek a pokračuj",
        "Dodirni bilo gde za nastavak"),
    "onboardingV2.questions.title": row3(
        "S Sophio boš znal odgovoriti na ta vprašanja:",
        "So Sophiou budeš vedieť odpovedať na tieto otázky:",
        "Uz Sophia znaćeš da odgovoriš na ova pitanja:"),
    "onboardingV2.questions.q1": row3(
        "Zakaj je nebo modro?", "Prečo je nebo modré?", "Zašto je nebo plavo?"),
    "onboardingV2.questions.q2": row3(
        "Kako je Napoleon zmagal pri Ulmu?",
        "Ako Napoleon vyhral pri Ulme?",
        "Kako je Napoleon pobedio kod Ulma?"),
    "onboardingV2.questions.q3": row3(
        "Kaj je črna luknja?", "Čo je čierna diera?", "Šta je crna rupa?"),
    "onboardingV2.questions.q4": row3(
        "Kaj je impresionizem?", "Čo je impresionizmus?", "Šta je impresionizam?"),
    "onboardingV2.questions.q5": row3(
        "Kako deluje javni dolg?", "Ako funguje verejný dlh?",
        "Kako funkcioniše javni dug?"),
    "onboardingV2.questions.q6": row3(
        "Zakaj Luna ne pade?", "Prečo Mesiac nespadne?", "Zašto Mesec ne pada?"),
    "onboardingV2.questions.q7": row3(
        "Kdo je bila v resnici Kleopatra?", "Kto vlastne bola Kleopatra?",
        "Ko je zapravo bila Kleopatra?"),
    "onboardingV2.questions.q8": row3(
        "Kako je nastalo vesolje?", "Ako vznikol vesmír?",
        "Kako je nastao svemir?"),
    "onboardingV2.questions.q9": row3(
        "Zakaj ponoči sanjamo?", "Prečo v noci snívame?", "Zašto sanjamo noću?"),
    "onboardingV2.questions.q10": row3(
        "Kaj je Einsteinova teorija relativnosti?",
        "Čo je Einsteinova teória relativity?",
        "Šta je Ajnštajnova teorija relativnosti?"),
    "onboardingV2.screenTime.title": row3(
        "Vzemi si čas nazaj", "Vezmi si čas späť", "Vrati svoje vreme"),
    "onboardingV2.screenTime.caption": row3(
        "Naši uporabniki zdaj na telefonu preživijo povprečno le 39 minut na dan.",
        "Naši používatelia teraz strávia na telefóne v priemere len 39 minút denne.",
        "Naši korisnici sada na telefonu provedu u proseku samo 39 minuta dnevno."),
    "onboardingV2.screenTime.minutes": row3("%d min", "%d min", "%d min"),
    "onboardingV2.phoneTime.title": row3(
        "Koliko časa na dan preživiš na telefonu?",
        "Koľko času denne tráviš na telefóne?",
        "Koliko vremena dnevno provodiš na telefonu?"),
    "onboardingV2.yearsGrid.title": row3(
        "Tukaj je tvoje življenje v letih", "Tu je tvoj život v rokoch",
        "Evo tvog života u godinama"),
    "onboardingV2.yearsGrid.caption": row3(
        "To je %d polnih let, ki jih v življenju izgubiš na telefonu.",
        "To je %d celých rokov, ktoré za život stratíš na telefóne.",
        "To je %d punih godina koje u životu izgubiš na telefonu."),
    "onboardingV2.transform.text": row3(
        "S Sophio spremeni ta čas v znanje",
        "So Sophiou premeň ten čas na vedomosti",
        "Uz Sophia pretvori to vreme u znanje"),
    "onboardingV2.transform.words": row3(
        "znanje, umetnost, filozofija, znanost, zgodovina, književnost",
        "vedomosti, umenie, filozofia, veda, história, literatúra",
        "znanje, umetnost, filozofija, nauka, istorija, književnost"),
    "onboardingV2.transform.tapHint": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Dodirni za nastavak"),
    "onboardingV2.exams.title": row3(
        "Izboljšali so svoje ocene", "Zlepšili si známky",
        "Popravili su svoje ocene"),
    "onboardingV2.exams.quote1": row3(
        "»Zaradi Sophie mi je povprečje pri zgodovini to ocenjevalno obdobje zraslo za 3 točke.«",
        "„Vďaka Sophii mi priemer z dejepisu za tento polrok stúpol o 3 body.“",
        "„Zahvaljujući Sophia, prosek iz istorije mi je ovog polugodišta porastao za 3 poena.“"),
    "onboardingV2.exams.author1": row3(
        "Thomas, študent", "Thomas, študent", "Toma, student"),
    "onboardingV2.exams.quote2": row3(
        "»Ponavljam 10 minut na dan in ocene so mi res poletele.«",
        "„Opakujem si 10 minút denne a známky mi fakt vyleteli.“",
        "„Ponavljam 10 minuta dnevno i ocene su mi stvarno skočile.“"),
    "onboardingV2.exams.author2": row3(
        "Inès, zadnji letnik", "Inès, maturitný ročník", "Ines, maturantkinja"),
    "onboardingV2.exams.quote3": row3(
        "»Kvizi so mi pomagali zapomniti si bistvo pred izpiti.«",
        "„Kvízy mi pomohli zapamätať si to podstatné pred skúškami.“",
        "„Kvizovi su mi pomogli da zapamtim suštinu pred ispite.“"),
    "onboardingV2.exams.author3": row3(
        "Camille, faks", "Camille, vysoká škola", "Kamij, fakultet"),
    "onboardingV2.exams.quote4": row3(
        "»Odlično za ponavljanje na poti. Profesorji so opazili razliko.«",
        "„Ideálne na opakovanie cestou. Učitelia si ten rozdiel všimli.“",
        "„Odlično za ponavljanje u prevozu. Profesori su primetili razliku.“"),
    "onboardingV2.exams.author4": row3(
        "Yanis, gimnazija", "Yanis, stredná škola", "Janis, srednja škola"),
    "onboardingV2.rightPlace.title": row3(
        "Na pravem mestu si", "Si na správnom mieste", "Na pravom si mestu"),
    "onboardingV2.rightPlace.ofUsers": row3(
        "uporabnikov", "používateľov", "korisnika"),
    "onboardingV2.rightPlace.caption": row3(
        "…s tem ciljem res napreduje s Sophio.",
        "…s týmto cieľom so Sophiou naozaj napreduje.",
        "…sa ovim ciljem stvarno napreduje uz Sophia."),
    "onboardingV2.swipe.title": row3(
        "Tečaji, izbrani zate", "Kurzy vybrané pre teba",
        "Kursevi izabrani za tebe"),
    "onboardingV2.swipe.subtitle": row3(
        "Kar te zanima, podrsaj v desno.",
        "Čo ťa zaujíma, potiahni doprava.",
        "Ono što te zanima prevuci udesno."),
    "onboardingV2.swipe.like": row3("Všeč mi je", "Páči sa mi", "Sviđa mi se"),
    "onboardingV2.swipe.nope": row3("Ne", "Nie", "Ne"),
    "onboardingV2.swipe.noted": row3("Zabeleženo!", "Mám to!", "Zabeleženo!"),
    "onboardingV2.phone.title": row3(
        "Koliko časa preživiš na telefonu?",
        "Koľko času tráviš na telefóne?",
        "Koliko vremena provodiš na telefonu?"),
    "onboardingV2.phone.perDay": row3("na dan", "za deň", "dnevno"),
    "onboardingV2.weeks.title": row3(
        "To je %d tednov na leto", "To je %d týždňov ročne",
        "To je %d nedelja godišnje"),
    "onboardingV2.weeks.subtitle": row3(
        "To je tvoje leto. Rdeče: čas pred zaslonom.",
        "Toto je tvoj rok. Červeno: čas strávený pri obrazovke.",
        "Ovo je tvoja godina. Crveno: vreme pred ekranom."),
})

# --- onboardingV2: review carousel, profile archetypes, loading, trial ----
# Testimonial 3 is Inès and testimonial 5 Sarah, so the Slavic past tense goes
# feminine there; the other quotes are worded to need no gender at all.
STRINGS3.update({
    "onboardingV2.weeks.caption": row3(
        "Predstavljaj si, kaj bi se lahko naučil z drobcem tega časa.",
        "Predstav si, čo by si sa stihol naučiť za zlomok toho času.",
        "Zamisli šta bi mogao da naučiš sa delićem tog vremena."),
    "onboardingV2.review.title": row3(
        "Evo, kaj o tem menijo naši uporabniki",
        "Toto si myslia naši používatelia",
        "Evo šta misle naši korisnici"),
    "onboardingV2.review.appStore": row3(
        "na App Storeu", "na App Store", "na App Store-u"),
    "onboardingV2.review.quote": row3(
        "»Prej sem na telefonu preživel 7 ur na dan. Zdaj le 40 minut s Sophio in vsak teden se počutim pametnejšega.«",
        "„Predtým som na telefóne trávil 7 hodín denne. Teraz len 40 minút so Sophiou a každý týždeň sa cítim múdrejší.“",
        "„Ranije sam na telefonu provodio 7 sati dnevno. Sada samo 40 minuta uz Sophia i svake nedelje se osećam pametnije.“"),
    "onboardingV2.review.author": row3("Léa, 24", "Léa, 24", "Lea, 24"),
    "onboardingV2.review.t1.quote": row3(
        "Odkar manj drsam po zaslonu in uporabljam Sophio, se mi zdi, da si zapomnim veliko več.",
        "Odkedy menej scrollujem a používam Sophiu, mám pocit, že si pamätám oveľa viac.",
        "Otkad manje skrolujem i koristim Sophia, čini mi se da pamtim mnogo više."),
    "onboardingV2.review.t1.author": row3(
        "Camille, 22", "Camille, 22", "Kamij, 22"),
    "onboardingV2.review.t2.quote": row3(
        "10 minut zjutraj na avtobusu in zvečer imam o čem govoriti. Iskreno, zasvojilo me je.",
        "10 minút ráno v električke a večer mám o čom hovoriť. Úprimne, chytilo ma to.",
        "10 minuta ujutru u autobusu i uveče imam o čemu da pričam. Iskreno, uvuklo me je."),
    "onboardingV2.review.t2.author": row3("Yanis, 27", "Yanis, 27", "Janis, 27"),
    "onboardingV2.review.t3.quote": row3(
        "Vedno sem sovražila »piflanje«, tukaj pa se vse usede kar samo. Spomin me preseneča.",
        "Vždy som nenávidela „bifľovanie“, ale tu to sadne samo od seba. Pamäť ma prekvapuje.",
        "Oduvek sam mrzela „bubanje“, a ovde sve sedne samo od sebe. Pamćenje me iznenađuje."),
    "onboardingV2.review.t3.author": row3("Inès, 19", "Inès, 19", "Ines, 19"),
    "onboardingV2.review.t4.quote": row3(
        "Neskončno drsanje zamenjam za tečaj. V enem mesecu so ljudje okrog mene opazili razliko.",
        "Nekonečné scrollovanie mením za kurz. Za mesiac si ľudia okolo mňa všimli rozdiel.",
        "Beskrajno skrolovanje menjam za kurs. Za mesec dana ljudi oko mene primetili su razliku."),
    "onboardingV2.review.t4.author": row3("Thomas, 31", "Thomas, 31", "Toma, 31"),
    "onboardingV2.review.t5.quote": row3(
        "Končno aplikacija, ob kateri čutim, da napredujem, ne da zapravljam čas. Odprem jo vsak dan.",
        "Konečne aplikácia, pri ktorej mám pocit, že napredujem, a nie že strácam čas. Otváram ju každý deň.",
        "Konačno aplikacija uz koju osećam da napredujem, a ne da gubim vreme. Otvaram je svakog dana."),
    "onboardingV2.review.t5.author": row3("Sarah, 26", "Sarah, 26", "Sara, 26"),
    "onboardingV2.review.t6.quote": row3(
        "Kvizi v razmikih so prava magija: stvari izpred tednov si zapomnim brez truda.",
        "Kvízy s odstupom sú čistá mágia: pamätám si veci spred týždňov bez námahy.",
        "Kvizovi u razmacima su prava magija: pamtim stvari od pre nekoliko nedelja bez muke."),
    "onboardingV2.review.t6.author": row3("Malik, 23", "Malik, 23", "Malik, 23"),
    "onboardingV2.personalize.text": row3(
        "Prilagodimo tvojo vsebino", "Prispôsobme ti obsah",
        "Prilagodimo tvoj sadržaj"),
    "onboardingV2.personalize.tapHint": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Dodirni za nastavak"),
    "onboardingV2.profile.eyebrow": row3(
        "Tukaj je tvoj profil", "Tu je tvoj profil", "Evo tvog profila"),
    "onboardingV2.profile.objectiveTitle": row3(
        "Tvoj cilj", "Tvoj cieľ", "Tvoj cilj"),
    "onboardingV2.profile.coursesTitle": row3(
        "Tečaji, ki te čakajo", "Kurzy, ktoré na teba čakajú",
        "Kursevi koji te čekaju"),
    "onboardingV2.profile.cta": row3("Gremo", "Ideme na to", "Idemo"),
    "onboardingV2.profile.nickname.cultivate": row3(
        "Radovedni um", "Zvedavá myseľ", "Radoznali um"),
    "onboardingV2.profile.nickname.reduceScreen": row3(
        "Gospodar časa", "Pán času", "Gospodar vremena"),
    "onboardingV2.profile.nickname.exams": row3("Strateg", "Stratég", "Strateg"),
    "onboardingV2.profile.nickname.impress": row3(
        "Blesteči", "Žiarivý", "Blistavi"),
    "onboardingV2.profile.nickname.curiosity": row3(
        "Raziskovalec", "Prieskumník", "Istraživač"),
    "onboardingV2.profile.tagline.cultivate": row3(
        "Svet hočeš razumeti, vsak dan malo bolj.",
        "Chceš svetu rozumieť, každý deň o kúsok viac.",
        "Želiš da razumeš svet, svakog dana malo više."),
    "onboardingV2.profile.tagline.reduceScreen": row3(
        "Nadzor nad svojim časom in pozornostjo jemlješ nazaj.",
        "Berieš si späť kontrolu nad svojím časom a pozornosťou.",
        "Vraćaš kontrolu nad svojim vremenom i pažnjom."),
    "onboardingV2.profile.tagline.exams": row3(
        "Učiš se z metodo in si pripravljen, ko je pomembno.",
        "Učíš sa systematicky a si pripravený, keď na tom záleží.",
        "Učiš sa metodom i spreman si kad je važno."),
    "onboardingV2.profile.tagline.impress": row3(
        "Kmalu boš ti imel najboljše zgodbe.",
        "Čoskoro budeš ty ten s najlepšími historkami.",
        "Uskoro ćeš ti imati najbolje priče."),
    "onboardingV2.profile.tagline.curiosity": row3(
        "Tvoja radovednost nima meja — nahranimo jo.",
        "Tvoja zvedavosť nemá hranice — nakŕmme ju.",
        "Tvoja radoznalost nema granice — nahranimo je."),
    "onboardingV2.loading.title": row3(
        "Pripravljamo tvoj profil", "Pripravujeme tvoj profil",
        "Pripremamo tvoj profil"),
    "onboardingV2.loading.step1": row3(
        "Analiza tvojega cilja", "Analýza tvojho cieľa", "Analiza tvog cilja"),
    "onboardingV2.loading.step2": row3(
        "Izbor tvojih tečajev", "Výber tvojich kurzov", "Odabir tvojih kurseva"),
    "onboardingV2.loading.step3": row3(
        "Izdelava tvojega programa", "Zostavovanie tvojho programu",
        "Izrada tvog programa"),
    "onboardingV2.loading.cta": row3(
        "Pokaži moj profil", "Zobraziť môj profil", "Prikaži moj profil"),
    "onboardingV2.loading.reviews": row3(
        "Več kot 1.000 mnenj", "Viac než 1 000 recenzií", "Više od 1.000 recenzija"),
    "onboardingV2.login.title": row3(
        "Ustvari svoj račun", "Vytvor si účet", "Napravi svoj nalog"),
    "onboardingV2.login.subtitle": row3(
        "Da shraniš napredek in ga imaš na vseh napravah.",
        "Aby si mal postup uložený a dostupný na všetkých zariadeniach.",
        "Da sačuvaš napredak i imaš ga na svim uređajima."),
    "onboardingV2.trial.title": row3(
        "Kako deluje tvoje brezplačno preizkusno obdobje",
        "Ako funguje tvoje bezplatné skúšobné obdobie",
        "Kako radi tvoj besplatni probni period"),
    "onboardingV2.trial.cta": row3(
        "Pripravljen sem", "Idem do toho", "Spreman sam"),
    "onboardingV2.trial.step0.title": row3(
        "Račun je ustvarjen", "Účet je vytvorený", "Nalog je napravljen"),
    "onboardingV2.trial.step0.detail": row3(
        "Tvoj profil je ustvarjen.", "Tvoj profil bol vytvorený.",
        "Tvoj profil je napravljen."),
})

# --- onboardingV2: trial timeline, notifications, first paywall, settings --
STRINGS3.update({
    "onboardingV2.trial.step1.title": row3(
        "Danes: preizkusi Sophia Pro", "Dnes: vyskúšaj Sophia Pro",
        "Danas: isprobaj Sophia Pro"),
    "onboardingV2.trial.step1.detail": row3(
        "Nauči se nekaj novega v 5 minutah na dan.",
        "Nauč sa niečo nové za 5 minút denne.",
        "Nauči nešto novo za 5 minuta dnevno."),
    "onboardingV2.trial.step2.title": row3(
        "2. dan: opomnik", "2. deň: pripomienka", "2. dan: podsetnik"),
    "onboardingV2.trial.step2.detail": row3(
        "Sporočili ti bomo z obvestilom. Odpoveš v 15 sekundah.",
        "Dáme ti vedieť oznámením. Zrušíš to za 15 sekúnd.",
        "Javićemo ti obaveštenjem. Otkazuješ za 15 sekundi."),
    "onboardingV2.trial.step3.title": row3(
        "3. dan: preizkus se izteče", "3. deň: skúšobné obdobie končí",
        "3. dan: probni period ističe"),
    "onboardingV2.trial.step3.detail": row3(
        "Tvoja naročnina se začne %@.", "Tvoje predplatné sa začne %@.",
        "Tvoja pretplata počinje %@."),
    "onboardingV2.reminder.title": row3(
        "Opomnik dobiš 1 dan pred koncem preizkusnega obdobja.",
        "Pripomienku dostaneš 1 deň pred koncom skúšobného obdobia.",
        "Podsetnik dobijaš 1 dan pre kraja probnog perioda."),
    "onboardingV2.reminder.cta": row3(
        "Preizkusi brezplačno", "Vyskúšaj zadarmo", "Isprobaj besplatno"),
    "onboardingV2.notifications.title": row3(
        "Ostani na tekočem", "Zostaň v obraze", "Ostani u toku"),
    "onboardingV2.notifications.subtitle": row3(
        "Diskreten opomnik, kadar je tečaj res vreden tvojega časa. Nič drugega.",
        "Nenápadná pripomienka, keď kurz naozaj stojí za tvoj čas. Nič iné.",
        "Diskretan podsetnik kad kurs stvarno vredi tvog vremena. Ništa drugo."),
    "onboardingV2.notifications.bullet1": row3(
        "Tečaj, izbran za tvoj profil", "Kurz vybraný pre tvoj profil",
        "Kurs izabran za tvoj profil"),
    "onboardingV2.notifications.bullet2": row3(
        "Ob pravem času, nikoli v nizu", "V správnej chvíli, nikdy v sérii",
        "U pravom trenutku, nikad u nizu"),
    "onboardingV2.notifications.bullet3": row3(
        "Izklopiš z enim tapom", "Vypneš jedným ťuknutím",
        "Isključuješ jednim dodirom"),
    "onboardingV2.notifications.cta": row3(
        "Vklopi obvestila", "Zapnúť oznámenia", "Uključi obaveštenja"),
    "onboardingV2.notifications.skip": row3("Pozneje", "Neskôr", "Kasnije"),
    "notification.courseNudge.title": row3(
        "Vredno ogleda danes", "Dnes stojí za pozretie", "Vredi pogledati danas"),
    "notification.courseNudge.body": row3(
        "Odkrij »%@« — dovolj je pet minut.",
        "Objav „%@“ — päť minút stačí.",
        "Otkrij „%@“ — dovoljno je pet minuta."),
    "notification.courseNudge.bodyFallback": row3(
        "Čaka te nov tečaj — dovolj je pet minut.",
        "Čaká na teba nový kurz — päť minút stačí.",
        "Čeka te novi kurs — dovoljno je pet minuta."),
    "trial.endingSoon.banner": row3(
        "Čez 1 dan izgubiš dostop do Sophia Premium.",
        "Za 1 deň stratíš prístup k Sophia Premium.",
        "Za 1 dan gubiš pristup Sophia Premium."),
    "onboardingV2.pw.tryFree": row3(
        "Preizkusi 3 dni brezplačno,", "Vyskúšaj 3 dni zadarmo,",
        "Isprobaj 3 dana besplatno,"),
    "onboardingV2.pw.thenPrice": row3(
        "nato %@ (letna naplata, %@).",
        "potom %@ (účtované ročne, %@).",
        "zatim %@ (naplata jednom godišnje, %@)."),
    "onboardingV2.pw.priceNoTrial": row3(
        "Premium za %@ (letna naplata, %@).",
        "Premium za %@ (účtované ročne, %@).",
        "Premium za %@ (naplata jednom godišnje, %@)."),
    "onboardingV2.pw.viewAllPlans": row3(
        "Vsi paketi", "Všetky plány", "Svi paketi"),
    "onboardingV2.pw.twoTaps": row3(
        "Dva tapa za začetek, odpoved je preprosta.",
        "Dve ťuknutia a ideš, zrušiť sa dá úplne ľahko.",
        "Dva dodira za početak, otkazivanje je jednostavno."),
    "onboardingV2.pw.startTrial": row3(
        "Zaženi 3 brezplačne dni", "Spustiť 3 dni zadarmo",
        "Pokreni 3 besplatna dana"),
    "onboardingV2.pw.subscribe": row3(
        "Naroči se", "Predplatiť si", "Pretplati se"),
    "onboardingV2.pw.compare.title": row3(
        "Naročniki Pro se naučijo več in hitreje",
        "Predplatitelia Pro sa učia viac a rýchlejšie",
        "Pro pretplatnici uče više i brže"),
    "onboardingV2.pw.free": row3("Brezplačno", "Zadarmo", "Besplatno"),
    "onboardingV2.pw.yearly": row3("Letno", "Ročne", "Godišnje"),
    "onboardingV2.pw.monthly": row3("Mesečno", "Mesačne", "Mesečno"),
    "onboardingV2.pw.monthlyBilling": row3(
        "naplata vsak mesec", "účtované každý mesiac", "naplata svakog meseca"),
    "onboardingV2.pw.trialBadge": row3(
        "3 dni brezplačno", "3 dni zadarmo", "3 dana besplatno"),
    "onboardingV2.pw.save": row3("Prihraniš %@", "Ušetríš %@", "Ušteda %@"),
    "onboardingV2.pw.feature.allSubjects": row3(
        "Vse teme", "Všetky témy", "Sve teme"),
    "onboardingV2.pw.feature.unlimited": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Neograničeni kursevi"),
    "onboardingV2.pw.feature.quiz": row3(
        "Kvizi in ponavljanje", "Kvízy a opakovanie", "Kvizovi i ponavljanje"),
    "onboardingV2.pw.feature.favorites": row3(
        "Neomejene priljubljene", "Neobmedzené obľúbené", "Neograničeni favoriti"),
    "onboardingV2.pw.feature.noAds": row3(
        "Brez oglasov", "Žiadne reklamy", "Bez reklama"),
    "onboardingV2.pw.feature.weekly": row3(
        "Novosti vsak teden", "Novinky každý týždeň", "Novosti svake nedelje"),
    "settings.title": row3("Nastavitve", "Nastavenia", "Podešavanja"),
    "settings.section.progress": row3("Napredek", "Pokrok", "Napredak"),
    "settings.section.premium": row3("Premium", "Premium", "Premium"),
    "settings.section.data": row3("Podatki", "Údaje", "Podaci"),
    "settings.section.help": row3("Pomoč", "Pomoc", "Pomoć"),
    "settings.section.legal": row3("Pravno", "Právne informácie", "Pravne informacije"),
    "settings.section.about": row3("O aplikaciji", "O aplikácii", "O aplikaciji"),
    "settings.section.developer": row3("Razvijalec", "Vývojár", "Programer"),
    "settings.section.appearance": row3("Videz", "Vzhľad", "Izgled"),
})

# --- settings, debug rows, feedback form ----------------------------------
STRINGS3.update({
    "settings.appearance.light": row3("Svetlo", "Svetlý", "Svetlo"),
    "settings.appearance.dark": row3("Nočno", "Nočný", "Noćno"),
    "settings.appearance.automatic": row3(
        "Samodejno", "Automaticky", "Automatski"),
    "settings.appearance.hint": row3(
        "Samodejno sledi nastavitvi telefona.",
        "Automaticky sleduje nastavenie telefónu.",
        "Automatski prati podešavanje telefona."),
    "settings.courses.completed": row3(
        "%d končanih tečajev", "%d dokončených kurzov", "%d završenih kurseva"),
    "settings.courses.available": row3(
        "od %d razpoložljivih", "z %d dostupných", "od %d dostupnih"),
    "settings.streak.title": row3(
        "%d dni zapored", "%d dní v rade", "%d dana zaredom"),
    "settings.streak.subtitle": row3(
        "Kar tako naprej!", "Len tak ďalej!", "Samo tako nastavi!"),
    "settings.premium.title": row3(
        "Preidi na Premium", "Prejdi na Premium", "Pređi na Premium"),
    "settings.premium.subtitle": row3(
        "Neomejeni tečaji in kvizi", "Neobmedzené kurzy a kvízy",
        "Neograničeni kursevi i kvizovi"),
    "settings.reset.title": row3(
        "Ponastavi napredek", "Vynulovať pokrok", "Resetuj napredak"),
    "settings.feedback.title": row3(
        "Pošlji povratno informacijo", "Odoslať spätnú väzbu",
        "Pošalji povratnu informaciju"),
    "settings.feedback.subtitle": row3(
        "Napaka, ideja ali predlog vsebine",
        "Chyba, nápad alebo návrh obsahu",
        "Greška, ideja ili predlog sadržaja"),
    "settings.ambassador.banner.badge": row3(
        "Premium brezplačno", "Premium zadarmo", "Premium besplatno"),
    "settings.ambassador.banner.title": row3(
        "Postani ambasador", "Staň sa ambasádorom", "Postani ambasador"),
    "settings.ambassador.banner.subtitle": row3(
        "Zasluži z objavljanjem Sophie na TikToku",
        "Zarábaj tým, že Sophiu zdieľaš na TikToku",
        "Zaradi objavljujući Sophia na TikTok-u"),
    "settings.terms.title": row3(
        "Pogoji uporabe", "Podmienky používania", "Uslovi korišćenja"),
    "settings.privacy.title": row3(
        "Pravilnik o zasebnosti", "Zásady ochrany súkromia",
        "Politika privatnosti"),
    "settings.restore.title": row3(
        "Obnovi nakupe", "Obnoviť nákupy", "Vrati kupovine"),
    "settings.about.version": row3("Različica", "Verzia", "Verzija"),
    "settings.about.courses": row3(
        "Razpoložljivi tečaji", "Dostupné kurzy", "Dostupni kursevi"),
    "settings.debug.resetOnboarding": row3(
        "Ponovi uvod", "Zopakovať úvod", "Ponovi uvod"),
    "settings.debug.resetDaily": row3(
        "Ponastavi dnevni tečaj", "Vynulovať denný kurz", "Resetuj dnevni kurs"),
    "settings.debug.daily.done": row3(
        "Danes opravljeno", "Dnes hotovo", "Danas odrađeno"),
    "settings.debug.daily.pending": row3(
        "Še ni opravljeno", "Ešte nie", "Još nije odrađeno"),
    "settings.footer": row3(
        "Narejeno s ♥ — Sophia", "Vyrobené s ♥ — Sophia",
        "Napravljeno s ♥ — Sophia"),
    "settings.reset.alert.title": row3(
        "Ponastaviš?", "Vynulovať?", "Resetovati?"),
    "settings.reset.alert.cancel": row3("Prekliči", "Zrušiť", "Odustani"),
    "settings.reset.alert.confirm": row3(
        "Ponastavi", "Vynulovať", "Resetuj"),
    "settings.reset.alert.message": row3(
        "Ves tvoj napredek bo izbrisan. Tega ni mogoče razveljaviti.",
        "Celý tvoj pokrok bude zmazaný. Nedá sa to vrátiť späť.",
        "Ceo tvoj napredak biće obrisan. To se ne može poništiti."),
    "settings.onboarding.alert.title": row3(
        "Ponoviš uvod?", "Zopakovať úvod?", "Ponoviti uvod?"),
    "settings.onboarding.alert.confirm": row3(
        "Ponovi", "Zopakovať", "Ponovi"),
    "settings.onboarding.alert.message": row3(
        "Uvod se bo začel od začetka (samo DEBUG).",
        "Úvod sa spustí odznova (iba DEBUG).",
        "Uvod kreće ispočetka (samo DEBUG)."),
    "feedback.title": row3(
        "Tvoja povratna informacija", "Tvoja spätná väzba",
        "Tvoja povratna informacija"),
    "feedback.subtitle": row3(
        "Preberemo vse. Povej nam, kaj ti je všeč, kaj ne deluje in česa manjka.",
        "Čítame všetko. Napíš nám, čo sa ti páči, čo nefunguje alebo čo chýba.",
        "Čitamo sve. Reci nam šta ti se sviđa, šta ne radi i šta nedostaje."),
    "feedback.category.label": row3("Kategorija", "Kategória", "Kategorija"),
    "feedback.category.bug": row3("Napaka", "Chyba", "Greška"),
    "feedback.category.idea": row3("Ideja", "Nápad", "Ideja"),
    "feedback.category.content": row3("Vsebina", "Obsah", "Sadržaj"),
    "feedback.category.other": row3("Drugo", "Iné", "Drugo"),
    "feedback.message.label": row3("Sporočilo", "Správa", "Poruka"),
    "feedback.message.placeholder": row3(
        "Opiši v nekaj stavkih…", "Popíš to v pár vetách…",
        "Opiši u par rečenica…"),
    "feedback.email.label": row3(
        "E-pošta (neobvezno)", "E-mail (nepovinné)", "Imejl (neobavezno)"),
    "feedback.email.placeholder": row3(
        "Da ti lahko odgovorimo", "Aby sme ti mohli odpovedať",
        "Da možemo da ti odgovorimo"),
    "feedback.technicalNote": row3(
        "Različica aplikacije, jezik in model naprave se priložijo samodejno, da ti lažje pomagamo.",
        "Verzia aplikácie, jazyk a model zariadenia sa prikladajú automaticky, aby sme ti vedeli pomôcť.",
        "Verzija aplikacije, jezik i model uređaja prilažu se automatski da bismo lakše pomogli."),
    "feedback.submit": row3("Pošlji", "Odoslať", "Pošalji"),
    "feedback.error.generic": row3(
        "Trenutno ni mogoče poslati. Poskusi pozneje.",
        "Teraz sa to nedá odoslať. Skús to neskôr.",
        "Trenutno ne može da se pošalje. Pokušaj kasnije."),
    "feedback.success.title": row3("Hvala!", "Ďakujeme!", "Hvala!"),
    "feedback.success.body": row3(
        "Tvoje sporočilo je poslano. Pozorno ga bomo prebrali.",
        "Tvoja správa odišla. Pozorne si ju prečítame.",
        "Tvoja poruka je poslata. Pažljivo ćemo je pročitati."),
    "feedback.success.close": row3("Zapri", "Zavrieť", "Zatvori"),
})

# --- ambassador program, legal, subjects ----------------------------------
STRINGS3.update({
    "ambassador.title": row3("Ambasador", "Ambasádor", "Ambasador"),
    "ambassador.step.program": row3("Program", "Program", "Program"),
    "ambassador.step.apply": row3("Prijava", "Prihláška", "Prijava"),
    "ambassador.program.heading": row3(
        "Postani ambasador Sophie", "Staň sa ambasádorom Sophie",
        "Postani Sophia ambasador"),
    "ambassador.how.title": row3(
        "Kako deluje", "Ako to funguje", "Kako funkcioniše"),
    "ambassador.how.step1": row3(
        "Prijaviš se tukaj v 1 minuti.", "Prihlásiš sa tu za 1 minútu.",
        "Prijavljuješ se ovde za 1 minut."),
    "ambassador.how.step2": row3(
        "Damo ti vsebino, primere in mentorstvo.",
        "Dáme ti obsah, príklady aj koučing.",
        "Dajemo ti sadržaj, primere i podršku."),
    "ambassador.how.step3": row3(
        "Objavljaš na TikToku in si plačan.",
        "Postuješ na TikToku a dostaneš zaplatené.",
        "Objavljuješ na TikTok-u i dobijaš plaćeno."),
    "ambassador.roles.title": row3(
        "Dva načina sodelovanja", "Dva spôsoby, ako sa zapojiť",
        "Dva načina da učestvuješ"),
    "ambassador.stat.income": row3("Zaslužek", "Príjem", "Zarada"),
    "ambassador.stat.time": row3("Čas", "Čas", "Vreme"),
    "ambassador.discover.cta": row3(
        "Prijavljam se", "Prihlasujem sa", "Prijavljujem se"),
    "ambassador.intro": row3(
        "Pridruži se ambasadorskemu programu Sophia: objavljaš vsebino na TikToku. Mi damo objave, primere in mentorstvo. Ti objavljaš in si plačan.",
        "Pridaj sa k programu ambasádorov Sophia: postuješ obsah na TikToku. Dáme ti príspevky, príklady aj koučing. Ty publikuješ a dostaneš zaplatené.",
        "Pridruži se Sophia ambasadorskom programu: objavljuješ sadržaj na TikTok-u. Mi dajemo objave, primere i podršku. Ti objavljuješ i dobijaš plaćeno."),
    "ambassador.cta48h": row3(
        "Oglasimo se v 48 urah. Pridruži se mreži!",
        "Ozveme sa do 48 hodín. Pridaj sa k sieti!",
        "Javljamo se u roku od 48 sati. Pridruži se mreži!"),
    "ambassador.bonus": row3(
        "Bonus: brezplačni Sophia Premium med programom",
        "Bonus: Sophia Premium zadarmo počas programu",
        "Bonus: besplatni Sophia Premium tokom programa"),
    "ambassador.role.slideshow.title": row3(
        "Ustvarjalec slideshowov", "Tvorca slideshow", "Autor slajdšoua"),
    "ambassador.role.slideshow.income": row3(
        "30-100 € / mes.", "30-100 € / mesiac", "30-100 € / mes."),
    "ambassador.role.slideshow.time": row3(
        "1-2 h / mes.", "1-2 h / mesiac", "1-2 č / mes."),
    "ambassador.role.slideshow.body": row3(
        "Damo ti TikTok slideshowe, pripravljene za objavo. Ti jih objaviš, mi te podpremo.",
        "Dáme ti TikTok slideshow pripravené na postnutie. Ty ich publikuješ, my ťa podržíme.",
        "Dajemo ti gotove TikTok slajdšoue. Ti ih objavljuješ, mi te podržavamo."),
    "ambassador.role.ugc.title": row3(
        "Ustvarjalec UGC", "Tvorca UGC", "UGC autor"),
    "ambassador.role.ugc.income": row3(
        "50-1000 € / mes.", "50-1000 € / mesiac", "50-1000 € / mes."),
    "ambassador.role.ugc.time": row3(
        "2-10 h / mes.", "2-10 h / mesiac", "2-10 č / mes."),
    "ambassador.role.ugc.body": row3(
        "Ustvarjaš objave za TikTok. Zaslužek je odvisen od ogledov. Damo ti primere UGC in mentorstvo.",
        "Tvoríš príspevky na TikTok. Zárobok závisí od zhliadnutí. Dáme ti UGC príklady aj koučing.",
        "Praviš TikTok objave. Zarada zavisi od pregleda. Dajemo ti UGC primere i podršku."),
    "ambassador.conditions.title": row3("Pogoji", "Podmienky", "Uslovi"),
    "ambassador.conditions.countries": row3(
        "Živeti v Franciji, Kanadi, Belgiji ali Švici",
        "Žiť vo Francúzsku, Kanade, Belgicku alebo Švajčiarsku",
        "Živeti u Francuskoj, Kanadi, Belgiji ili Švajcarskoj"),
    "ambassador.conditions.age": row3(
        "Imeti 16 let ali več", "Mať 16 alebo viac rokov",
        "Imati 16 ili više godina"),
    "ambassador.form.title": row3("Prijava", "Prihláška", "Prijava"),
    "ambassador.form.roles.label": row3(
        "Prijavljaš se za", "Hlásiš sa na", "Prijavljuješ se za"),
    "ambassador.form.role.slideshow": row3(
        "Ustvarjalec slideshowov", "Tvorca slideshow", "Autor slajdšoua"),
    "ambassador.form.role.ugc": row3(
        "Ustvarjalec UGC", "Tvorca UGC", "UGC autor"),
    "ambassador.form.email.label": row3("E-pošta", "E-mail", "Imejl"),
    "ambassador.form.email.placeholder": row3(
        "ti@email.com", "ty@email.com", "ti@email.com"),
    "ambassador.form.age.label": row3("Starost", "Vek", "Godine"),
    "ambassador.form.age.placeholder": row3("npr. 22", "napr. 22", "npr. 22"),
    "ambassador.form.presentation.label": row3(
        "Na kratko o sebi", "Krátko o sebe", "Ukratko o sebi"),
    "ambassador.form.presentation.placeholder": row3(
        "Kaj rad počneš? Splošna razgledanost, ustvarjanje vsebin …",
        "Čo ťa baví? Všeobecný prehľad, tvorba obsahu…",
        "Šta voliš da radiš? Opšta kultura, pravljenje sadržaja…"),
    "ambassador.form.presentation.hint": row3(
        "%d/%d znakov min.", "%d/%d znakov min.", "%d/%d znakova min."),
    "ambassador.form.country.confirm": row3(
        "Potrjujem, da živim v Franciji, Kanadi, Belgiji ali Švici",
        "Potvrdzujem, že žijem vo Francúzsku, Kanade, Belgicku alebo Švajčiarsku",
        "Potvrđujem da živim u Francuskoj, Kanadi, Belgiji ili Švajcarskoj"),
    "ambassador.form.submit": row3(
        "Pošlji prijavo", "Odoslať prihlášku", "Pošalji prijavu"),
    "ambassador.form.hint": row3(
        "Izpolni cel obrazec (o sebi: najmanj 10 znakov), da lahko pošlješ.",
        "Vyplň celý formulár (o sebe: min. 10 znakov), aby si mohol odoslať.",
        "Popuni ceo obrazac (o sebi: najmanje 10 znakova) da bi mogao da pošalješ."),
    "ambassador.form.error.generic": row3(
        "Trenutno ni mogoče poslati. Poskusi pozneje.",
        "Teraz sa to nedá odoslať. Skús to neskôr.",
        "Trenutno ne može da se pošalje. Pokušaj kasnije."),
    "ambassador.form.error.age": row3(
        "Imeti moraš 16 let ali več.", "Musíš mať 16 alebo viac rokov.",
        "Moraš imati 16 ili više godina."),
    "ambassador.success.title": row3(
        "Prijava poslana!", "Prihláška odoslaná!", "Prijava poslata!"),
    "ambassador.success.body": row3(
        "Hvala. Tvojo prijavo bomo pozorno prebrali.",
        "Ďakujeme. Tvoju prihlášku si pozorne prečítame.",
        "Hvala. Pažljivo ćemo pročitati tvoju prijavu."),
    "ambassador.success.close": row3("Zapri", "Zavrieť", "Zatvori"),
    "legal.terms.title": row3("Pogoji", "Podmienky", "Uslovi"),
    "legal.privacy.title": row3("Zasebnost", "Súkromie", "Privatnost"),
    "subject.histoire": row3("Zgodovina", "Dejiny", "Istorija"),
    "subject.sciences": row3("Znanost", "Veda", "Nauka"),
    "subject.litterature": row3("Književnost", "Literatúra", "Književnost"),
})

# --- subjects, home swipe, in-app explainers ------------------------------
STRINGS3.update({
    "subject.art": row3("Umetnost", "Umenie", "Umetnost"),
    "subject.mythologie": row3("Mitologija", "Mytológia", "Mitologija"),
    "subject.comprendreLeMonde": row3(
        "Razumeti današnji svet", "Pochopiť dnešný svet",
        "Razumeti današnji svet"),
    "subject.histoire.short": row3("Zgodovina", "Dejiny", "Istorija"),
    "subject.sciences.short": row3("Znanost", "Veda", "Nauka"),
    "subject.litterature.short": row3(
        "Književnost", "Literatúra", "Književnost"),
    "subject.art.short": row3("Umetnost", "Umenie", "Umetnost"),
    "subject.mythologie.short": row3("Mitologija", "Mytológia", "Mitologija"),
    "subject.comprendreLeMonde.short": row3(
        "Današnji svet", "Dnešný svet", "Današnji svet"),
    "home.skip": row3("Preskoči", "Preskočiť", "Preskoči"),
    "home.swipe.title": row3(
        "Podrsaj za menjavo tečaja", "Potiahni a zmeň kurz",
        "Prevuci da promeniš kurs"),
    "home.swipe.subtitle": row3(
        "Podrsaj levo ali desno na naslednjega",
        "Potiahni doľava alebo doprava na ďalší",
        "Prevuci levo ili desno na sledeći"),
    "course.reads": row3("%@ branj", "%@ prečítaní", "%@ čitanja"),
    "explain.tapToClose": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Dodirni za nastavak"),
    "explain.home.title": row3(
        "Navpično drsenje", "Zvislé potiahnutie", "Vertikalno prevlačenje"),
    "explain.home.body": row3(
        "Podrsaj navzgor za naslednji tečaj, navzdol za prejšnjega.",
        "Potiahnutím nahor objavíš ďalší kurz, nadol sa vrátiš na predošlý.",
        "Prevuci nagore za sledeći kurs, nadole za prethodni."),
    "explain.course.title": row3(
        "Tapni besede", "Klepni na slová", "Dodirni reči"),
    "explain.course.body": row3(
        "Poudarjeni izrazi skrivajo razlago: tapni jih in vse razumeš.",
        "Zvýraznené výrazy skrývajú definíciu: klepni na ne a všetko pochopíš.",
        "Istaknuti pojmovi kriju definiciju: dodirni ih da sve razumeš."),
    "explain.course.termBody": row3(
        "Tako kot »%@« tudi podčrtane besede skrivajo razlago. Tapni jo, da se pokaže.",
        "Ako „%@“ aj podčiarknuté slová skrývajú definíciu. Klepni na ňu a uvidíš ju.",
        "Kao i „%@“, podvučene reči kriju definiciju. Dodirni da je vidiš."),
    "explain.collections.title": row3("Zbirke", "Zbierky", "Zbirke"),
    "explain.collections.body": row3(
        "Vsaka zbirka zbere tečaje iste teme, da napreduješ korak za korakom.",
        "Každá zbierka spája kurzy na rovnakú tému, aby si postupoval krok za krokom.",
        "Svaka zbirka okuplja kurseve iste teme da napreduješ korak po korak."),
    "explain.training.title": row3(
        "Ponavljanje", "Opakovanie", "Ponavljanje"),
    "explain.training.body": row3(
        "Ponavljaj že videna vprašanja ob pravem času, da ti ostanejo.",
        "Zopakuj si už videné otázky v pravý čas, aby ti zostali.",
        "Ponavljaj već viđena pitanja u pravom trenutku da ti ostanu."),
    "home.swipe.left": row3("Podrsaj ←", "Potiahni ←", "Prevuci ←"),
    "home.swipe.right": row3("→ Podrsaj", "→ Potiahni", "→ Prevuci"),
    "home.bravo": row3("Bravo!", "Bravo!", "Bravo!"),
    "home.allCompleted": row3(
        "Končal si vse razpoložljive tečaje.",
        "Dokončil si všetky dostupné kurzy.",
        "Prošao si sve dostupne kurseve."),
    "discount.gift.title": row3(
        "Presenečenje zate!", "Prekvapenie pre teba!", "Iznenađenje za tebe!"),
    "discount.gift.tapToOpen": row3(
        "Tapni, da ga odpreš", "Ťukni a otvor ho", "Dodirni da otvoriš"),
    "discount.gift.keepTapping": row3(
        "Tapkaj naprej!", "Ťukaj ďalej!", "Nastavi da dodiruješ!"),
    "discount.gift.almost": row3("Skoraj!", "Skoro!", "Skoro!"),
    "home.locked": row3("Zaklenjeno", "Zamknuté", "Zaključano"),
    "home.start": row3("Začni", "Začať", "Počni"),
})

# --- library chrome, collections, subject cards, filters ------------------
STRINGS3.update({
    "library.empty.title": row3(
        "Ni zadetkov", "Žiadne výsledky", "Nema rezultata"),
    "library.empty.subtitle": row3(
        "Poskusi z drugo besedo.", "Skús iné kľúčové slovo.",
        "Probaj drugu reč."),
    "library.seeMore": row3("Prikaži več", "Zobraziť viac", "Prikaži više"),
    "library.section.featured": row3("Izpostavljeno", "Odporúčané", "Izdvojeno"),
    "library.featured.badge": row3("Izpostavljeno", "Odporúčané", "Izdvojeno"),
    "collections.featured": row3("Izpostavljeno", "Odporúčané", "Izdvojeno"),
    "library.section.continue": row3(
        "Nadaljuj z učenjem", "Pokračuj v učení", "Nastavi da učiš"),
    "library.section.recommended": row3(
        "Priporočeno zate", "Odporúčané pre teba", "Preporučeno za tebe"),
    "library.unlock": row3("Odkleni", "Odomknúť", "Otključaj"),
    "library.lockedBadge": row3("ZAKLENJENO", "ZAMKNUTÉ", "ZAKLJUČANO"),
    "collections.title": row3("ZBIRKE", "ZBIERKY", "ZBIRKE"),
    "collections.subtitle": row3(
        "Vodene poti, ki povezujejo ideje.",
        "Vedené cesty, ktoré prepájajú myšlienky.",
        "Vođene putanje koje povezuju ideje."),
    "collections.complete": row3(
        "Zbirka je končana", "Zbierka je dokončená", "Zbirka je završena"),
    "collections.progress": row3(
        "Končano: %d / %d", "Hotovo: %d / %d", "Završeno: %d / %d"),
    "collections.badge.complete": row3("KONČANA", "HOTOVO", "ZAVRŠENO"),
    "collections.badge.path": row3("POT", "CESTA", "PUTANJA"),
    "collections.xpAtEnd": row3(
        "+%d XP na koncu", "+%d XP na konci", "+%d XP na kraju"),
    "collections.pathComplete": row3(
        "Pot je končana", "Cesta je dokončená", "Putanja je završena"),
    "collections.path": row3("Tvoja pot", "Tvoja cesta", "Tvoja putanja"),
    "collections.reward": row3(
        "Končna nagrada", "Záverečná odmena", "Konačna nagrada"),
    "subject.courses.count": row3(
        "%d tečajev", "%d kurzov", "%d kurseva"),
    "subject.completed.singular": row3(
        "%d končan", "%d dokončený", "%d završen"),
    "subject.completed.plural": row3(
        "%d končanih", "%d dokončených", "%d završenih"),
    "subject.level": row3("RAVEN %d", "ÚROVEŇ %d", "NIVO %d"),
    "subject.progress.stats": row3(
        "%d XP · %d/%d tečajev", "%d XP · %d/%d kurzov", "%d XP · %d/%d kurseva"),
    "subject.next": row3("Naslednje", "Ďalej", "Sledeće"),
    "subject.filter.empty": row3(
        "Tukaj še ni tečajev.", "Zatiaľ tu nie sú žiadne kurzy.",
        "Ovde još nema kurseva."),
    "library.filter.all": row3("Vse", "Všetko", "Sve"),
    "library.filter.todo": row3("Za narediti", "Na urobenie", "Za uraditi"),
    "library.filter.inProgress": row3("V teku", "Prebieha", "U toku"),
    "library.filter.done": row3("Končani", "Hotové", "Završeno"),
    "library.filter.favorites": row3("Priljubljeni", "Obľúbené", "Omiljeno"),
    "library.status.done": row3("KONČANO", "HOTOVO", "ZAVRŠENO"),
    "library.status.inProgress": row3("V TEKU", "PREBIEHA", "U TOKU"),
})

# --- favorites, celebrations, common chrome, welcome rotator --------------
# The rotating words complete "… partner to master …", so Slovenian and Serbian
# take the genitive and Slovak the accusative; they are written to fit that
# frame, not as standalone nouns.
STRINGS3.update({
    "favorites.badge.count": row3(
        "%d TEČAJEV", "%d KURZOV", "%d KURSEVA"),
    "favorites.empty.title": row3(
        "Ni priljubljenih", "Žiadne obľúbené", "Nema omiljenih"),
    "favorites.empty.subtitle": row3(
        "Tapni srce pri tečaju\nin našel ga boš tukaj.",
        "Klepni na srdce pri kurze\na nájdeš ho tu.",
        "Dodirni srce na kursu\ni naći ćeš ga ovde."),
    "course.funFact": row3("SI VEDEL?", "VEDEL SI?", "JESI LI ZNAO?"),
    "paywall.error.unavailable": row3(
        "Ponudbe ni mogoče naložiti", "Ponuku sa nepodarilo načítať",
        "Nije moguće učitati ponudu"),
    "paywall.error.retry": row3("Poskusi znova", "Skús znova", "Pokušaj ponovo"),
    "cards.successRate": row3(
        "pravilnih odgovorov", "správnych odpovedí", "tačnih odgovora"),
    "cards.globalXP": row3("+%d XP skupaj", "+%d XP celkom", "+%d XP ukupno"),
    "course.keyTakeaway": row3("ZAPOMNI SI", "ZAPAMÄTAJ SI", "ZAPAMTI"),
    "celebration.collectionAdvanced": row3(
        "Napredek v zbirki!", "Zbierka o krok ďalej!", "Napredak u zbirci!"),
    "celebration.coursesCompleted": row3(
        "končanih tečajev", "dokončených kurzov", "završenih kurseva"),
    "celebration.collectionComplete": row3(
        "Zbirka je končana!", "Zbierka je hotová!", "Zbirka je završena!"),
    "common.continue": row3("Naprej", "Pokračovať", "Nastavi"),
    "common.next": row3("Naslednje", "Ďalej", "Dalje"),
    "common.letsGo": row3("Gremo!", "Ideme na to!", "Idemo!"),
    "common.letsGoShort": row3("Gremo", "Ideme na to", "Idemo"),
    "common.close": row3("Zapri", "Zavrieť", "Zatvori"),
    "common.processing": row3("Trenutek…", "Moment…", "Trenutak…"),
    "common.startLearning": row3(
        "Začni se učiti", "Začni sa učiť", "Počni da učiš"),
    "common.backHome": row3(
        "Nazaj na domov", "Späť na začiatok", "Nazad na početnu"),
    "common.retryQuiz": row3(
        "Ponovi kviz", "Skúsiť kvíz znova", "Ponovi kviz"),
    "common.seeMoreArrow": row3(
        "Prikaži več →", "Zobraziť viac →", "Prikaži više →"),
    "common.streak.day": row3("DAN", "DEŇ", "DAN"),
    "common.streak.days": row3("DNI", "DNI", "DANA"),
    "common.levelShort": row3("RAV. %d", "ÚR. %d", "NIVO %d"),
    "common.increaseGoal": row3("Zvišaj cilj", "Zvýšiť cieľ", "Povećaj cilj"),
    "common.decreaseGoal": row3("Znižaj cilj", "Znížiť cieľ", "Smanji cilj"),
    "common.miniQuiz": row3("Mini kviz", "Mini kvíz", "Mini kviz"),
    "common.xpEarned": row3("+%d XP", "+%d XP", "+%d XP"),
    "common.xpBeforeNext": row3(
        "· %d do rav. %d", "· %d do úr. %d", "· %d do nivoa %d"),
    "onboarding.welcome.title": row3(
        "Sophia je tvoj partner pri obvladovanju",
        "Sophia ti pomôže zvládnuť",
        "Sophia je tvoj partner za savladavanje"),
    "onboarding.welcome.rotating.histoire": row3(
        "zgodovine", "dejiny", "istorije"),
    "onboarding.welcome.rotating.sciences": row3(
        "znanosti", "vedu", "nauke"),
    "onboarding.welcome.rotating.litterature": row3(
        "književnosti", "literatúru", "književnosti"),
    "onboarding.welcome.rotating.art": row3(
        "umetnosti", "umenie", "umetnosti"),
    "onboarding.welcome.rotating.mythologie": row3(
        "mitologije", "mytológiu", "mitologije"),
    "onboarding.welcome.rotating.comprendreLeMonde": row3(
        "današnjega sveta", "dnešný svet", "današnjeg sveta"),
})

# --- onboarding v1: phone time, wasted time, goals, interests -------------
STRINGS3.update({
    "onboarding.phone.title": row3(
        "Koliko časa\npreživiš na telefonu?",
        "Koľko času\ntráviš na telefóne?",
        "Koliko vremena\nprovodiš na telefonu?"),
    "onboarding.phone.subtitle": row3(
        "V povprečju, vsak dan.", "V priemere, každý deň.",
        "U proseku, svakog dana."),
    "onboarding.phone.intensity.light": row3("Malo", "Málo", "Malo"),
    "onboarding.phone.intensity.moderate": row3(
        "Zmerno", "Stredne", "Umereno"),
    "onboarding.phone.intensity.high": row3("Veliko", "Veľa", "Mnogo"),
    "onboarding.phone.intensity.intense": row3(
        "Zelo veliko", "Veľmi veľa", "Veoma mnogo"),
    "onboarding.phone.lessThan1h": row3(
        "Manj kot 1 h", "Menej než 1 h", "Manje od 1 č"),
    "onboarding.phone.1to2h": row3("1–2 h", "1–2 h", "1–2 č"),
    "onboarding.phone.2to4h": row3("2–4 h", "2–4 h", "2–4 č"),
    "onboarding.phone.moreThan4h": row3(
        "Več kot 4 h", "Viac než 4 h", "Više od 4 č"),
    "onboarding.phone.hours.1": row3("1 ura", "1 hodina", "1 sat"),
    "onboarding.phone.hours.2": row3("2 uri", "2 hodiny", "2 sata"),
    "onboarding.phone.hours.3": row3("3 ure", "3 hodiny", "3 sata"),
    "onboarding.phone.hours.5": row3("5 ur", "5 hodín", "5 sati"),
    "onboarding.wasted.intro": row3(
        "%@ na dan na telefonu — to je",
        "%@ denne na telefóne — to je",
        "%@ dnevno na telefonu — to je"),
    "onboarding.wasted.hoursLost": row3(
        "izgubljenih ur na leto.", "stratených hodín za rok.",
        "izgubljenih sati godišnje."),
    "onboarding.wasted.daysComplete": row3(
        "To je %@ brez prekinitve.", "To je %@ bez prestávky.",
        "To je %@ bez prekida."),
    "onboarding.wasted.transform": row3(
        "S Sophio ta čas postane znanje.",
        "So Sophiou sa ten čas zmení na vedomosti.",
        "Uz Sophia to vreme postaje znanje."),
    "onboarding.wasted.days.7": row3("7 dni", "7 dní", "7 dana"),
    "onboarding.wasted.days.23": row3("23 dni", "23 dní", "23 dana"),
    "onboarding.wasted.days.45": row3("45 dni", "45 dní", "45 dana"),
    "onboarding.wasted.days.91": row3("91 dni", "91 dní", "91 dan"),
    "onboarding.objectives.title": row3(
        "Tvoj cilj\ns Sophio?", "Tvoj cieľ\nso Sophiou?", "Tvoj cilj\nuz Sophia?"),
    "onboarding.objectives.subtitle": row3(
        "Izberi enega ali več ciljev.", "Vyber jeden alebo viac cieľov.",
        "Izaberi jedan ili više ciljeva."),
    "onboarding.objective.curious": row3(
        "Biti bolj radoveden", "Byť zvedavejší", "Biti radoznaliji"),
    "onboarding.objective.learnNew": row3(
        "Učiti se nove stvari", "Učiť sa nové veci", "Učiti nove stvari"),
    "onboarding.objective.impress": row3(
        "Navdušiti ljudi okoli sebe", "Ohromiť ľudí okolo seba",
        "Impresionirati ljude oko sebe"),
    "onboarding.objective.social": row3(
        "Se počutiti sproščeno med ljudmi", "Cítiť sa istejšie medzi ľuďmi",
        "Sigurnije se snalaziti u društvu"),
    "onboarding.objective.reduceScroll": row3(
        "Manj drsati po zaslonu", "Menej scrollovať", "Manje skrolovati"),
    "onboarding.interests.title": row3(
        "Katere teme\nte zanimajo?", "Aké témy\nťa zaujímajú?",
        "Koje teme\nte zanimaju?"),
    "onboarding.interests.subtitle": row3(
        "Izberi vsaj eno temo.", "Vyber aspoň jednu tému.",
        "Izaberi bar jednu temu."),
    "onboarding.dailyGoal.title": row3(
        "Vsak dan se želiš naučiti…", "Každý deň sa chceš naučiť…",
        "Svakog dana želiš da odradiš…"),
    "onboarding.dailyGoal.subtitle": row3(
        "Cilj lahko spremeniš pozneje.", "Cieľ si môžeš neskôr zmeniť.",
        "Cilj možeš promeniti kasnije."),
    "onboarding.dailyGoal.perDay": row3(
        "%@ na dan!", "%@ za deň!", "%@ dnevno!"),
    "onboarding.dailyGoal.singular": row3("lekcija", "lekcia", "lekcija"),
    "onboarding.dailyGoal.plural": row3("lekcije", "lekcie", "lekcije"),
})

# --- onboarding v1: loading, program card, projection, showcase -----------
STRINGS3.update({
    "onboarding.loading.title": row3(
        "Pripravljamo tvojo pot", "Pripravujeme tvoju cestu",
        "Pripremamo tvoj put"),
    "onboarding.loading.subtitle": row3(
        "Le nekaj sekund, obljubimo.", "Len pár sekúnd, sľubujeme.",
        "Samo par sekundi, obećavamo."),
    "onboarding.loading.step1": row3(
        "Analiziramo tvoje odgovore", "Analyzujeme tvoje odpovede",
        "Analiziramo tvoje odgovore"),
    "onboarding.loading.step2": row3(
        "Izbiramo tvoje 3 predmete", "Vyberáme tvoje 3 predmety",
        "Biramo tvoja 3 predmeta"),
    "onboarding.loading.step3": row3(
        "Pripravljamo tvojo pot", "Pripravujeme tvoju cestu",
        "Pripremamo tvoj put"),
    "onboarding.program.badge": row3(
        "Osebni program", "Osobný program", "Lični program"),
    "onboarding.program.title": row3(
        "Tukaj je tvoj program", "Tu je tvoj program", "Evo tvog programa"),
    "onboarding.program.profileLabel": row3(
        "TVOJ PROFIL", "TVOJ PROFIL", "TVOJ PROFIL"),
    "onboarding.program.nickname.default": row3(
        "Neutrudno radoveden", "Neúnavne zvedavý", "Neumorno radoznao"),
    "onboarding.program.nickname.histoire": row3(
        "Navdušenec nad zgodovino", "Nadšenec do dejín", "Zaljubljenik u istoriju"),
    "onboarding.program.nickname.sciences": row3(
        "Raziskovalec znanosti", "Vedecký prieskumník", "Istraživač nauke"),
    "onboarding.program.nickname.litterature": row3(
        "Ljubitelj književnosti", "Milovník literatúry", "Ljubitelj književnosti"),
    "onboarding.program.nickname.art": row3(
        "Navdušenec nad umetnostjo", "Nadšenec do umenia",
        "Zaljubljenik u umetnost"),
    "onboarding.program.nickname.mythologie": row3(
        "Raziskovalec mitologije", "Zvedavý na mytológiu", "Istraživač mitologije"),
    "onboarding.program.nickname.comprendreLeMonde": row3(
        "Opazovalec sveta", "Pozorovateľ sveta", "Posmatrač sveta"),
    "onboarding.program.dailyGoal": row3("%d %@", "%d %@", "%d %@"),
    "onboarding.program.dailyGoalCaption": row3(
        "Dnevni cilj", "Denný cieľ", "Dnevni cilj"),
    "onboarding.program.hoursSaved": row3("%d h", "%d h", "%d č"),
    "onboarding.program.hoursUnit": row3("h/leto", "h/rok", "č/god."),
    "onboarding.program.hoursSavedCaption": row3(
        "prihranjenega časa", "ušetreného času", "ušteđenog vremena"),
    "onboarding.program.topPick": row3(
        "Naš favorit", "Náš favorit", "Naš favorit"),
    "onboarding.program.coursesTitle": row3(
        "Tečaji, ki ti najbolj ustrezajo",
        "Kurzy, ktoré ti sadnú najviac",
        "Kursevi koji ti najviše odgovaraju"),
    "onboarding.projection.line1": row3(
        "Majhna navada,", "Malý zvyk,", "Mala navika —"),
    "onboarding.projection.line2": row3(
        "ogromni rezultati.", "obrovské výsledky.", "ogroman rezultat."),
    "onboarding.projection.its": row3("To je", "To je", "To je"),
    "onboarding.projection.newThings": row3(
        "novih stvari, ki jih boš znal",
        "nových vecí, ktoré budeš vedieť",
        "novih stvari koje ćeš znati"),
    "onboarding.projection.inOneYear": row3(
        "že čez leto dni.", "už o rok.", "već za godinu dana."),
    "onboarding.showcase.courses.title": row3(
        "Odkrij kratke\nin jasne tečaje",
        "Objav krátke,\nzrozumiteľné kurzy",
        "Otkrij kratke\ni jasne kurseve"),
    "onboarding.showcase.courses.swipe": row3(
        "PODRSAJ ZA ODKRIVANJE", "POTIAHNI A OBJAVUJ", "PREVUCI ZA OTKRIVANJE"),
    "onboarding.showcase.courses.lessons": row3(
        "%d lekcij", "%d lekcií", "%d lekcija"),
    "onboarding.showcase.courses.quizCount": row3(
        "%d kvizov", "%d kvízov", "%d kvizova"),
    "onboarding.showcase.quiz.title": row3(
        "Napreduj\nob kvizih", "Zlepši sa\ns kvízmi", "Napreduj\nuz kvizove"),
    "onboarding.showcase.quiz.question": row3(
        "Kaj ne more uiti iz črne luknje?",
        "Čo nemôže uniknúť z čiernej diery?",
        "Šta ne može da pobegne iz crne rupe?"),
    "onboarding.showcase.quiz.option.0": row3("Zvok", "Zvuk", "Zvuk"),
    "onboarding.showcase.quiz.option.1": row3("Svetloba", "Svetlo", "Svetlost"),
    "onboarding.showcase.quiz.option.2": row3("Toplota", "Teplo", "Toplota"),
    "onboarding.showcase.quiz.option.3": row3("Čas", "Čas", "Vreme"),
    "onboarding.showcase.collections.title": row3(
        "Sledi tematskim\npotem", "Sleduj tematické\ncesty",
        "Prati tematske\nputanje"),
})

# --- onboarding v1: XP showcase, growth graph, final, trial timeline ------
STRINGS3.update({
    "onboarding.showcase.xp.title": row3(
        "Rasti po ravneh\nin se povzpni na lestvici\nnajbolj razgledanih",
        "Rasti v úrovniach\na vyšvihni sa medzi\nnajrozhľadenejších",
        "Rasti kroz nivoe\ni penji se na listi\nnajobrazovanijih"),
    "onboarding.showcase.xp.level": row3("RAVEN", "ÚROVEŇ", "NIVO"),
    "onboarding.graph.title": row3(
        "Tako raste\ntvoje znanje", "Takto rastie\ntvoje vedomie",
        "Ovako raste\ntvoje znanje"),
    "onboarding.graph.subtitle": row3(
        "S Sophio in brez nje", "So Sophiou a bez nej", "Uz Sophia i bez nje"),
    "onboarding.graph.culture": row3("ZNANJE", "VEDOMOSTI", "ZNANJE"),
    "onboarding.graph.withSophia": row3(
        "S Sophio", "So Sophiou", "Uz Sophia"),
    "onboarding.graph.withoutSophia": row3(
        "Brez Sophie", "Bez Sophie", "Bez Sophia"),
    "onboarding.graph.today": row3("Danes", "Dnes", "Danas"),
    "onboarding.graph.oneYear": row3("1 leto", "1 rok", "1 godina"),
    "onboarding.graph.tagline": row3(
        "S Sophio tvoje znanje raste\neksponentno.",
        "So Sophiou tvoje vedomosti rastú\nexponenciálne.",
        "Uz Sophia tvoje znanje raste\neksponencijalno."),
    "onboarding.final.title": row3(
        "Profil je pripravljen!", "Profil je pripravený!", "Profil je spreman!"),
    "onboarding.final.subtitle": row3(
        "Dobrodošel v Sophii.\nZačni se učiti takoj.",
        "Vitaj v Sophii.\nZačni sa učiť hneď teraz.",
        "Dobro došao u Sophia.\nKreni da učiš odmah."),
    "onboarding.final.subjects": row3(
        "TVOJI PREDMETI", "TVOJE PREDMETY", "TVOJI PREDMETI"),
    "onboarding.trial.badge": row3(
        "Uvodna ponudba", "Uvítacia ponuka", "Uvodna ponuda"),
    "onboarding.trial.title": row3(
        "Prve 3 dni\nimaš brezplačno", "Prvé 3 dni\nmáš zadarmo",
        "Prva 3 dana\nsu besplatna"),
    "onboarding.trial.unlimitedCourses": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Neograničeni kursevi"),
    "onboarding.trial.allQuizzes": row3(
        "Vsi kvizi", "Všetky kvízy", "Svi kvizovi"),
    "onboarding.trial.noSurprise": row3(
        "Brez presenečenj", "Žiadne prekvapenia", "Bez iznenađenja"),
    "onboarding.trial.notifyTitle": row3(
        "Sporočili ti bomo\n1 dan pred koncem\nbrezplačnega obdobja",
        "Dáme ti vedieť\n1 deň pred koncom\nskúšobného obdobia",
        "Javićemo ti\n1 dan pre kraja\nbesplatnog perioda"),
    "onboarding.trial.cancelAnytime": row3(
        "Odpoveš kadar koli, brez stroškov.",
        "Zruš kedykoľvek, zadarmo.",
        "Otkaži kad god želiš, bez naplate."),
    "onboarding.trial.day1": row3("DAN 1", "DEŇ 1", "DAN 1"),
    "onboarding.trial.day2": row3("DAN 2", "DEŇ 2", "DAN 2"),
    "onboarding.trial.day3": row3("DAN 3", "DEŇ 3", "DAN 3"),
    "onboarding.trial.fullAccess": row3(
        "Poln dostop", "Plný prístup", "Potpun pristup"),
    "onboarding.trial.notificationSent": row3(
        "Obvestilo poslano", "Oznámenie odoslané", "Obaveštenje poslato"),
    "onboarding.trial.trialEnds": row3(
        "Konec preizkusa", "Koniec skúšobného obdobia", "Kraj probnog perioda"),
    "onboarding.premiumGift.badge": row3(
        "Darilo zate", "Darček pre teba", "Poklon za tebe"),
    "onboarding.premiumGift.title": row3(
        "Podarimo ti\nSophia Premium", "Dávame ti\nSophia Premium",
        "Poklanjamo ti\nSophia Premium"),
    "onboarding.premiumTrial.badge": row3(
        "Brezplačni preizkus", "Bezplatná skúška", "Besplatna proba"),
    "onboarding.premiumTrial.title": row3(
        "Tvoj brezplačni preizkus\nv 3 korakih",
        "Tvoja bezplatná skúška\nv 3 krokoch",
        "Tvoja besplatna proba\nu 3 koraka"),
    "onboarding.premiumTrial.step1.label": row3("ZDAJ", "TERAZ", "SADA"),
    "onboarding.premiumTrial.step1.title": row3(
        "Premium je aktiviran", "Premium je aktivovaný", "Premium je aktiviran"),
    "onboarding.premiumTrial.step2.label": row3("DAN 1", "DEŇ 1", "DAN 1"),
    "onboarding.premiumTrial.step2.title": row3(
        "Opomnik pred koncem", "Pripomienka pred koncom", "Podsetnik pred kraj"),
    "onboarding.premiumTrial.step3.label": row3("DAN 2", "DEŇ 2", "DAN 2"),
    "onboarding.premiumTrial.step3.title": row3(
        "Obdržiš ali odpoveš", "Necháš si to, alebo zrušíš",
        "Zadržiš ili otkažeš"),
    "onboarding.premiumTrial.cancelAnytime": row3(
        "Brez obveznosti", "Žiadny záväzok", "Bez obaveza"),
    "onboarding.premiumTrial.cta": row3(
        "Zaženi preizkus", "Spustiť skúšku", "Pokreni probu"),
})

# --- paywall: headlines, benefits, comparison table, plans ----------------
# `*.highlight` values MUST stay exact substrings of their headline, so the
# headlines are worded around the highlighted word rather than the reverse.
STRINGS3.update({
    "paywall.cancelAnytime": row3(
        "Odpoveš kadar koli, brez stroškov.",
        "Zruš kedykoľvek, zadarmo.",
        "Otkaži kad god želiš, bez naplate."),
    "paywall.header": row3(
        "Postani\nnajzanimivejša oseba\nv prostoru.",
        "Staň sa\nnajzaujímavejšou osobou\nv miestnosti.",
        "Postani\nnajzanimljivija\nosoba u prostoriji."),
    "paywall.header.highlight": row3(
        "najzanimivejša", "najzaujímavejšou", "najzanimljivija"),
    "paywall.weaponHeadline": row3(
        "Sophia, tvoje tajno\norožje za:",
        "Sophia, tvoja tajná\nzbraň na:",
        "Sophia, tvoje tajno\noružje za:"),
    "paywall.weaponHeadline.highlight": row3("tajno", "tajná", "tajno"),
    "paywall.benefit.conversations": row3(
        "💬 Boljši pogovori", "💬 Lepšie rozhovory", "💬 Bolji razgovori"),
    "paywall.benefit.curiosity": row3(
        "💡 Več radovednosti", "💡 Viac zvedavosti", "💡 Više radoznalosti"),
    "paywall.benefit.confidence": row3(
        "🔥 Več samozavesti", "🔥 Viac sebavedomia", "🔥 Više samopouzdanja"),
    "paywall.benefit.screenTime": row3(
        "📱 Koristnejši čas pred zaslonom",
        "📱 Čas pri telefóne, ktorý za to stojí",
        "📱 Korisnije vreme pred ekranom"),
    "paywall.premiumHeadline": row3(
        "Odkleni Premium za 3 dni\nBREZPLAČNO",
        "Odomkni Premium na 3 dni\nZADARMO",
        "Otključaj Premium na 3 dana\nBESPLATNO"),
    "paywall.premiumHeadline.highlight": row3(
        "BREZPLAČNO", "ZADARMO", "BESPLATNO"),
    "paywall.freeSubjects": row3(
        "Tvoji 3 brezplačni predmeti", "Tvoje 3 predmety zadarmo",
        "Tvoja 3 besplatna predmeta"),
    "paywall.lockedSubjects": row3(
        "3 zaklenjeni predmeti", "3 zamknuté predmety", "3 zaključana predmeta"),
    "paywall.lockedSubjectsWithPremium": row3(
        "3 predmete odkleneš s Premium",
        "3 predmety odomkneš s Premium",
        "3 predmeta otključavaš uz Premium"),
    "paywall.teaserTitle": row3(
        "Pokukaj, kaj te čaka", "Ochutnávka toho, čo ťa čaká",
        "Zaviri šta te čeka"),
    "paywall.teaserSubtitle": row3(
        "Na stotine tečajev Premium čaka, da jih odkleneš",
        "Stovky prémiových kurzov čaká na odomknutie",
        "Stotine premium kurseva čeka otključavanje"),
    "paywall.featureColumn": row3("Funkcije", "Funkcie", "Mogućnosti"),
    "paywall.freeColumn": row3("Brezplačno", "Zadarmo", "Besplatno"),
    "paywall.premiumColumn": row3("Premium", "Premium", "Premium"),
    "paywall.feature.3subjects": row3(
        "3 predmeti", "3 predmety", "3 predmeta"),
    "paywall.feature.allSubjects": row3(
        "Vsi predmeti", "Všetky predmety", "Svi predmeti"),
    "paywall.feature.unlimitedCourses": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Kursevi bez limita"),
    "paywall.feature.miniQuiz": row3("Mini kvizi", "Mini kvízy", "Mini kvizovi"),
    "paywall.feature.fullLibrary": row3(
        "Cela knjižnica", "Celá knižnica", "Cela biblioteka"),
    "paywall.plan.yearly": row3("Letno", "Ročne", "Godišnje"),
    "paywall.plan.monthly": row3("Mesečno", "Mesačne", "Mesečno"),
    "paywall.plan.yearlySubtitle": row3(
        "Zaračunano enkrat letno", "Účtované raz ročne",
        "Naplata jednom godišnje"),
    "paywall.plan.monthlySubtitle": row3(
        "Brez obveznosti", "Žiadny záväzok", "Bez obaveza"),
    "paywall.plan.perYear": row3("/ leto", "/ rok", "/ god."),
    "paywall.plan.perMonth": row3("/ mes.", "/ mes.", "/ mes."),
    "paywall.plan.discount": row3("-58%", "-58%", "-58%"),
    "paywall.plan.fallback.yearlyPrice": row3("$34.99", "$34.99", "$34.99"),
    "paywall.plan.fallback.monthlyPrice": row3("$8.99", "$8.99", "$8.99"),
    "paywall.plan.fallback.yearlyMonthly": row3(
        "2,92 $ / mesec", "2,92 $ / mesiac", "2,92 $ / mes."),
    "paywall.trialBadge": row3(
        "3 dni brezplačno", "3 dni zadarmo", "3 dana besplatno"),
    "paywall.restoreRow": row3(
        "Obnovi · Pogoji · Zasebnost",
        "Obnoviť · Podmienky · Súkromie",
        "Vrati · Uslovi · Privatnost"),
    "paywall.restore": row3("Obnovi", "Obnoviť", "Vrati"),
    "paywall.quiz.title": row3(
        "Odkleni kviz", "Odomkni kvíz", "Otključaj kviz"),
    "paywall.quiz.subtitle": row3(
        "Preveri se in utrdi, kar si se pravkar naučil, s kvizom tega tečaja.",
        "Otestuj sa a upevni si, čo si sa práve naučil, kvízom tohto kurzu.",
        "Proveri se i učvrsti ono što si upravo naučio kvizom ovog kursa."),
})

# --- paywall: FAQ, daily-course gate, reviews, CTAs -----------------------
STRINGS3.update({
    "paywall.quiz.faq.q1": row3(
        "Je naročnino lahko preprosto odpovem?",
        "Dá sa predplatné ľahko zrušiť?",
        "Da li je pretplatu lako otkazati?"),
    "paywall.quiz.faq.a1": row3(
        "Da. Pojdi v App Store → svoj račun → Naročnine → Sophia → Prekliči. Opravljeno v nekaj tapih.",
        "Áno. Choď do App Store → svoj účet → Predplatné → Sophia → Zrušiť. Hotovo na pár ťuknutí.",
        "Da. Idi u App Store → svoj nalog → Pretplate → Sophia → Otkaži. Gotovo u par dodira."),
    "paywall.quiz.faq.q2": row3(
        "Ali Sophia Pro odpre Sophia Ponavljanje?",
        "Patrí k Sophia Pro aj Sophia Opakovanie?",
        "Da li Sophia Pro otključava Sophia Ponavljanje?"),
    "paywall.quiz.faq.a2": row3(
        "Da. Sophia Pro odklene tudi Sophia Ponavljanje: aktivni priklic vrne vprašanja ob pravem času, da naučeno ostane.",
        "Áno. Sophia Pro odomkne aj Sophia Opakovanie: aktívne vybavovanie vracia otázky v pravý čas, aby ti učivo zostalo.",
        "Da. Sophia Pro otključava i Sophia Ponavljanje: aktivno prisećanje vraća pitanja u pravom trenutku da naučeno ostane."),
    "paywall.quiz.faq.q3": row3(
        "Lahko naročnino odpovem kadar koli?",
        "Môžem predplatné zrušiť kedykoľvek?",
        "Mogu li da otkažem pretplatu kad god želim?"),
    "paywall.quiz.faq.a3": row3(
        "Da — pred koncem brezplačnega obdobja in kadar koli pozneje. Brezplačno obdobje je tu zato, da spoznaš aplikacijo in vse, kar ponuja.",
        "Áno — pred koncom bezplatného obdobia aj kedykoľvek potom. Bezplatné obdobie je tu na to, aby si spoznal aplikáciu a všetko, čo ponúka.",
        "Da — pre kraja besplatnog perioda i bilo kada posle. Besplatni period tu je da upoznaš aplikaciju i sve što nudi."),
    "paywall.quiz.faq.q3.noTrial": row3(
        "Se vežem za določeno obdobje?",
        "Zaväzujem sa na nejaké obdobie?",
        "Vezujem li se na neki period?"),
    "paywall.quiz.faq.a3.noTrial": row3(
        "Ne. Brez obveznosti: odpoveš kadar koli v App Storu in dostop obdržiš do konca že plačanega obdobja.",
        "Nie. Žiadny záväzok: zruš kedykoľvek v App Store a prístup si udržíš do konca už zaplateného obdobia.",
        "Ne. Bez obaveza: otkaži kad god želiš u App Store-u i zadržavaš pristup do kraja već plaćenog perioda."),
    "paywall.course.title": row3(
        "Današnji brezplačni tečaj si že prebral",
        "Dnešný kurz zadarmo už máš prečítaný",
        "Već si pročitao današnji besplatni kurs"),
    "paywall.course.subtitle": row3(
        "Današnji brezplačni tečaj si porabil. Vrni se jutri ali odkleni vse takoj.",
        "Dnešný bezplatný kurz už máš za sebou. Vráť sa zajtra, alebo odomkni všetko hneď.",
        "Iskoristio si današnji besplatni kurs. Vrati se sutra ili otključaj sve odmah."),
    "paywall.course.subtitle.named": row3(
        "Današnji brezplačni tečaj si porabil. Odkleni »%@« in vse tečaje takoj ali se vrni jutri.",
        "Dnešný bezplatný kurz už máš za sebou. Odomkni „%@“ a všetky kurzy hneď, alebo sa vráť zajtra.",
        "Iskoristio si današnji besplatni kurs. Otključaj „%@“ i sve kurseve odmah ili se vrati sutra."),
    "paywall.course.comeBack": row3(
        "Naslednji brezplačni tečaj čez", "Ďalší bezplatný kurz o",
        "Sledeći besplatni kurs za"),
    "paywall.course.stat.value": row3("6", "6", "6"),
    "paywall.course.stat.label": row3(
        "tečajev / dan", "kurzov / deň", "kurseva / dan"),
    "paywall.course.stat.caption": row3(
        "v povprečju preberejo člani Sophia Premium",
        "v priemere prečítajú členovia Sophia Premium",
        "u proseku pročitaju članovi Sophia Premium"),
    "paywall.rating": row3("na App Storu", "na App Store", "na App Store-u"),
    "paywall.reviews.r1.quote": row3(
        "Tečaj pogoltnem takoj, ko imam 5 minut. Še nikoli se nisem toliko naučil.",
        "Zhltnem kurz vždy, keď mám 5 minút. Nikdy som sa toľko nenaučil.",
        "Progutam kurs čim imam 5 minuta. Nikad nisam toliko naučio."),
    "paywall.reviews.r1.author": row3(
        "Camille, 22 let", "Camille, 22 rokov", "Kamij, 22 godine"),
    "paywall.reviews.r2.quote": row3(
        "Naročnina se mi je povrnila v enem tednu. Preberem več tečajev na dan.",
        "Predplatné sa mi vrátilo za týždeň. Prečítam niekoľko kurzov denne.",
        "Pretplata mi se isplatila za nedelju dana. Čitam više kurseva dnevno."),
    "paywall.reviews.r2.author": row3(
        "Thomas, 29 let", "Thomas, 29 rokov", "Toma, 29 godina"),
    "paywall.reviews.r3.quote": row3(
        "Vsak teden se počutim bolj razgledanega. Težko se ustavim pri enem samem tečaju.",
        "Každý týždeň sa cítim rozhľadenejší. Ťažko sa zastaviť pri jedinom kurze.",
        "Svake nedelje se osećam obrazovanije. Teško je stati na jednom kursu."),
    "paywall.reviews.r3.author": row3(
        "Inès, 25 let", "Inès, 25 rokov", "Ines, 25 godina"),
    "paywall.benefit.unlimited": row3(
        "Neomejeni tečaji, vsak dan", "Neobmedzené kurzy, každý deň",
        "Kursevi bez limita, svakog dana"),
    "paywall.benefit.quiz": row3(
        "Vsi kvizi, da ti ostane", "Všetky kvízy, nech ti to zostane",
        "Svi kvizovi za bolje pamćenje"),
    "paywall.benefit.allSubjects": row3(
        "Vse teme, brez oglasov", "Všetky témy, bez reklám",
        "Sve teme, bez reklama"),
    "paywall.cta.unlockFree": row3(
        "Odkleni brezplačno", "Odomknúť zadarmo", "Otključaj besplatno"),
    "paywall.cta.subscribe": row3(
        "Naroči se zdaj", "Predplatiť si teraz", "Pretplati se sada"),
    "paywall.cta.activateTrial": row3(
        "Aktiviraj brezplačni preizkus", "Aktivovať bezplatnú skúšku",
        "Aktiviraj besplatnu probu"),
    "paywall.price.trialThenYearly": row3(
        "3 dni brezplačno, nato %@ / leto (%@)",
        "3 dni zadarmo, potom %@ / rok (%@)",
        "3 dana besplatno, zatim %@ / god. (%@)"),
    "paywall.price.yearlyNoTrial": row3(
        "%@ / leto (%@) · Odpoveš kadar koli",
        "%@ / rok (%@) · Zrušíš kedykoľvek",
        "%@ / god. (%@) · Otkažeš kad god želiš"),
})

# --- paywall: practice pitch, quiz demo ------------------------------------
STRINGS3.update({
    "paywall.training.title": row3(
        "Naj naučeno ostane za vedno", "Nech ti naučené zostane navždy",
        "Neka naučeno ostane zauvek"),
    "paywall.training.subtitle": row3(
        "Ponavljanje ti vrne vprašanja iz kvizov v popolnem trenutku — tik preden jih možgani pozabijo.",
        "Opakovanie ti vráti otázky z kvízov v dokonalej chvíli — tesne predtým, než ich mozog pustí.",
        "Ponavljanje vraća pitanja iz kvizova u savršenom trenutku — tačno pre nego što ih mozak zaboravi."),
    "paywall.training.stat1.value": row3("+200 %", "+200 %", "+200 %"),
    "paywall.training.stat1.label": row3(
        "boljše pomnjenje z razmaknjenim ponavljanjem kot z golim ponovnim branjem",
        "lepšie zapamätanie s rozloženým opakovaním než s obyčajným opätovným čítaním",
        "bolje pamćenje uz razmaknuto ponavljanje nego uz puko ponovno čitanje"),
    "paywall.training.stat2.value": row3("90 %", "90 %", "90 %"),
    "paywall.training.stat2.label": row3(
        "naučenega pozabimo v enem tednu… brez ponavljanja",
        "z toho, čo sa naučíme, zabudneme do týždňa… bez opakovania",
        "naučenog zaboravi se za nedelju dana… bez ponavljanja"),
    "paywall.training.how.title": row3(
        "KAKO DELUJE", "AKO TO FUNGUJE", "KAKO FUNKCIONIŠE"),
    "paywall.training.how.step1": row3(
        "Dokončaj tečaj in njegov kviz", "Dokonči kurz a jeho kvíz",
        "Završi kurs i njegov kviz"),
    "paywall.training.how.step2": row3(
        "Njegova vprašanja gredo v tvoje Ponavljanje",
        "Jeho otázky sa pridajú do tvojho Opakovania",
        "Njegova pitanja ulaze u tvoje Ponavljanje"),
    "paywall.training.how.step3": row3(
        "Ponavljaj ob pravem trenutku in nikoli več ne pozabiš",
        "Opakuj v tú správnu chvíľu, aby si už nikdy nezabudol",
        "Ponavljaj u pravom trenutku i više nikad ne zaboraviš"),
    "paywall.training.footnote": row3(
        "Razmaknjeno ponavljanje je najbolje dokazana metoda, da znanje postane trajno.",
        "Rozložené opakovanie je najlepšie dokázaný spôsob, ako urobiť vedomosti trvalými.",
        "Razmaknuto ponavljanje najbolje je dokazan način da znanje postane trajno."),
    "paywall.quiz.rating": row3(
        "na App Storu", "na App Store", "na App Store-u"),
    "paywall.quiz.demo.title": row3(
        "Preveri se po vsakem tečaju", "Otestuj sa po každom kurze",
        "Proveri se posle svakog kursa"),
    "paywall.quiz.demo.badge.mcq": row3(
        "Izbor odgovora", "Výber odpovede", "Izbor odgovora"),
    "paywall.quiz.demo.badge.trueFalse": row3(
        "Prav / narobe", "Pravda / nepravda", "Tačno / netačno"),
    "paywall.quiz.demo.badge.slider": row3("Ocena", "Odhad", "Procena"),
    "paywall.quiz.demo.badge.chrono": row3(
        "Časovnica", "Časová os", "Hronologija"),
    "paywall.quiz.demo.mcq.q": row3(
        "Kdo je naslikal Zvezdno noč?", "Kto namaľoval Hviezdnu noc?",
        "Ko je naslikao Zvezdanu noć?"),
    "paywall.quiz.demo.mcq.o1": row3("Van Gogh", "Van Gogh", "Van Gog"),
    "paywall.quiz.demo.mcq.o2": row3("Monet", "Monet", "Mone"),
    "paywall.quiz.demo.mcq.o3": row3("Picasso", "Picasso", "Pikaso"),
    "paywall.quiz.demo.tf.q": row3(
        "Kitajski zid je viden z Lune.",
        "Veľký čínsky múr je vidno z Mesiaca.",
        "Kineski zid se vidi sa Meseca."),
    "paywall.quiz.demo.tf.true": row3("Prav", "Pravda", "Tačno"),
    "paywall.quiz.demo.tf.false": row3("Narobe", "Nepravda", "Netačno"),
    "paywall.quiz.demo.slider.q": row3(
        "Katerega leta se je začela francoska revolucija?",
        "V ktorom roku sa začala Francúzska revolúcia?",
        "Koje godine je počela Francuska revolucija?"),
    "paywall.quiz.demo.chrono.q": row3(
        "Razvrsti obdobja po času", "Zoraď obdobia chronologicky",
        "Poređaj razdoblja hronološki"),
    "paywall.quiz.demo.chrono.i1": row3("Antika", "Starovek", "Antika"),
    "paywall.quiz.demo.chrono.i2": row3(
        "Srednji vek", "Stredovek", "Srednji vek"),
    "paywall.quiz.demo.chrono.i3": row3(
        "Renesansa", "Renesancia", "Renesansa"),
    "paywall.quiz.reviews.title": row3(
        "Napredujejo s Sophio", "Učia sa so Sophiou", "Napreduju uz Sophia"),
    "paywall.quiz.review1.quote": row3(
        "Ob kvizih sem si zapomnil veliko več kot samo z branjem. 5 minut in ostane.",
        "Vďaka kvízom som si zapamätal oveľa viac než len čítaním. 5 minút a drží to.",
        "Uz kvizove sam zapamtio mnogo više nego samo čitanjem. 5 minuta i ostaje."),
    "paywall.quiz.review1.author": row3(
        "Camille, 22 let", "Camille, 22 rokov", "Kamij, 22 godine"),
    "paywall.quiz.review2.quote": row3(
        "Končno aplikacija, v kateri si res zapomnim, kar se naučim. Kvizi so zasvojljivi.",
        "Konečne aplikácia, kde si naozaj pamätám, čo sa naučím. Kvízy sú návykové.",
        "Konačno aplikacija u kojoj stvarno pamtim ono što učim. Kvizovi su zarazni."),
})

# --- paywall: flash offer, trial timeline, review carousel ----------------
STRINGS3.update({
    "paywall.quiz.review2.author": row3(
        "Thomas, 29 let", "Thomas, 29 rokov", "Toma, 29 godina"),
    "paywall.quiz.review3.quote": row3(
        "Vsak teden se počutim bolj razgledanega. Kvizi vse utrdijo.",
        "Každý týždeň sa cítim rozhľadenejší. Kvízy všetko ukotvia.",
        "Svake nedelje se osećam obrazovanije. Kvizovi sve učvrste."),
    "paywall.quiz.review3.author": row3(
        "Inès, 25 let", "Inès, 25 rokov", "Ines, 25 godina"),
    "paywall.discount.endsIn": row3("Konča se čez", "Končí o", "Završava se za"),
    "paywall.discount.title": row3(
        "Bliskovita ponudba, samo danes", "Bleskový výpredaj, iba dnes",
        "Munjevita ponuda, samo danas"),
    "paywall.discount.subtitle": row3(
        "Vse življenje znanja s Premium, po najnižji ceni doslej.",
        "Celý život vedomostí s Premium, za najnižšiu cenu, akú sme kedy dali.",
        "Ceo život znanja uz Premium, po najnižoj ceni koju smo ikad dali."),
    "paywall.discount.perYear": row3(
        "na leto, brez obveznosti", "ročne, bez záväzku", "godišnje, bez obaveza"),
    "paywall.discount.cta": row3(
        "Vzamem ponudbo", "Beriem to hneď", "Uzimam ponudu"),
    "paywall.discount.noTrial": row3(
        "Brez brezplačnega preizkusa · Odpoveš kadar koli",
        "Bez skúšobného obdobia · Zrušíš kedykoľvek",
        "Bez probnog perioda · Otkažeš kad god želiš"),
    "paywall.discount.fallbackPrice": row3("$19.99", "$19.99", "$19.99"),
    "paywall.terms": row3("Pogoji", "Podmienky", "Uslovi"),
    "paywall.privacy": row3("Zasebnost", "Súkromie", "Privatnost"),
    "paywall.trialSheet.title": row3(
        "Začni brezplačni\npreizkus za 3 dni",
        "Začni bezplatnú\nskúšku na 3 dni",
        "Pokreni besplatnu\nprobu od 3 dana"),
    "paywall.trialSheet.start": row3(
        "Začni brezplačni preizkus", "Spustiť bezplatnú skúšku",
        "Pokreni besplatnu probu"),
    "paywall.trial.today": row3("Danes", "Dnes", "Danas"),
    "paywall.trial.noPayment": row3(
        "Brez plačila", "Žiadna platba", "Bez plaćanja"),
    "paywall.trial.todayDetail": row3(
        "Dostop do vseh funkcij Premium.",
        "Prístup ku všetkým funkciám Premium.",
        "Pristup svim Premium mogućnostima."),
    "paywall.trial.in2days": row3("Čez 2 dni", "O 2 dni", "Za 2 dana"),
    "paywall.trial.reminder": row3(
        "Sporočimo ti", "Dáme ti vedieť", "Javićemo ti"),
    "paywall.trial.reminderDetail": row3(
        "Obvestilo 1 dan pred koncem preizkusa.",
        "Oznámenie 1 deň pred koncom skúšky.",
        "Obaveštenje 1 dan pre kraja probe."),
    "paywall.trial.in3days": row3("Čez 3 dni", "O 3 dni", "Za 3 dana"),
    "paywall.trial.starts": row3(
        "Tvoja naročnina se začne", "Tvoje predplatné sa začína",
        "Počinje tvoja pretplata"),
    "paywall.trial.startsDetail": row3(
        "Če ne želiš nadaljevati, odpovej prej.",
        "Ak nechceš pokračovať, zruš to vopred.",
        "Otkaži ranije ako ne želiš da nastaviš."),
    "paywall.review1.quote": row3(
        "Odlično na poti. Vsak dan se naučim nekaj brez truda.",
        "Ideálne cestou. Každý deň sa niečo naučím bez námahy.",
        "Savršeno u prevozu. Svakog dana naučim nešto bez napora."),
    "paywall.review1.author": row3(
        "Marie, 28 let", "Marie, 28 rokov", "Mari, 28 godina"),
    "paywall.review2.quote": row3(
        "Končno aplikacija, ki drsanje po zaslonu spremeni v znanje.",
        "Konečne aplikácia, ktorá scrollovanie mení na vedomosti.",
        "Konačno aplikacija koja skrolovanje pretvara u znanje."),
    "paywall.review2.author": row3(
        "Thomas, 34 let", "Thomas, 34 rokov", "Toma, 34 godine"),
    "paywall.review3.quote": row3(
        "Tečaji so kratki, zabavni in res si jih zapomnim.",
        "Kurzy sú krátke, zábavné a naozaj si ich pamätám.",
        "Kursevi su kratki, zabavni i stvarno ih pamtim."),
    "paywall.review3.author": row3(
        "Inès, 22 let", "Inès, 22 rokov", "Ines, 22 godine"),
    "paywall.review4.quote": row3(
        "Prijatelji me sprašujejo, od kod mi vse te zanimivosti.",
        "Kamaráti sa ma pýtajú, odkiaľ mám všetky tie historky.",
        "Prijatelji me pitaju odakle mi sve te zanimljivosti."),
    "paywall.review4.author": row3(
        "Lucas, 31 let", "Lucas, 31 rokov", "Lukas, 31 godina"),
    "paywall.review5.quote": row3(
        "Osebni uvod me je prepričal že v prvi minuti.",
        "Osobný úvod ma presvedčil hneď v prvej minúte.",
        "Lični uvod me je ubedio u prvom minutu."),
    "paywall.review5.author": row3(
        "Sarah, 26 let", "Sarah, 26 rokov", "Sara, 26 godina"),
})

# --- one-time offer, profile ----------------------------------------------
STRINGS3.update({
    "offer.unique": row3(
        "Tvoja enkratna ponudba", "Tvoja jednorazová ponuka",
        "Tvoja jedinstvena ponuda"),
    "offer.discount": row3(
        "-70 % ZA VEDNO", "-70 % NAVŽDY", "-70 % ZAUVEK"),
    "offer.perMonth": row3("/mes.", "/mes.", "/mes."),
    "offer.billed": row3("zaračunano", "účtované", "naplaćeno"),
    "offer.expiresIn": row3("Poteče čez", "Platnosť vyprší o", "Ističe za"),
    "offer.unlock": row3(
        "Odkleni mojih -70 %", "Odomknúť mojich -70 %", "Otključaj mojih -70 %"),
    "offer.restore": row3(
        "Obnovi nakupe", "Obnoviť nákupy", "Vrati kupovine"),
    "offer.feature1": row3(
        "240 tečajev splošne razgledanosti", "240 kurzov všeobecného prehľadu",
        "240 kurseva opšte kulture"),
    "offer.feature2": row3(
        "Neomejeni interaktivni kvizi", "Neobmedzené interaktívne kvízy",
        "Neograničeni interaktivni kvizovi"),
    "offer.feature3": row3(
        "Nova vsebina vsak teden", "Nový obsah každý týždeň",
        "Novi sadržaj svake nedelje"),
    "profile.title": row3("Profil", "Profil", "Profil"),
    "profile.streak.start": row3(
        "Preberi tečaj in začni!", "Prečítaj si kurz a rozbehni to!",
        "Pročitaj kurs i kreni!"),
    "profile.streak.beginning": row3(
        "Začel si — kar tako naprej!", "Začal si — pokračuj!",
        "Krenuo si — samo nastavi!"),
    "profile.streak.good": row3(
        "Lepa rednost 👏", "Pekná pravidelnosť 👏", "Odlična redovnost 👏"),
    "profile.streak.great": row3("Goriš 🔥", "Horíš 🔥", "Gori ti 🔥"),
    "profile.favorites": row3(
        "Moje priljubljene", "Moje obľúbené", "Moji favoriti"),
    "profile.favorites.count": row3(
        "%d shranjenih tečajev", "%d uložených kurzov", "%d sačuvanih kurseva"),
    "profile.quiz.recent": row3(
        "MOJI ZADNJI KVIZI", "MOJE POSLEDNÉ KVÍZY", "MOJI NEDAVNI KVIZOVI"),
    "profile.quiz.locked": row3(
        "Kvizi so zaklenjeni", "Kvízy sú zamknuté", "Kvizovi su zaključani"),
    "profile.quiz.lockedSubtitle": row3(
        "Na voljo z brezplačnim preizkusom — 3 dni zastonj",
        "Dostupné s bezplatnou skúškou — 3 dni zadarmo",
        "Dostupni uz besplatnu probu — 3 dana gratis"),
    "profile.quiz.unlock": row3(
        "Odkleni moje kvize", "Odomknúť moje kvízy", "Otključaj moje kvizove"),
    "profile.quiz.emptyTitle": row3(
        "Kvizov še ni", "Zatiaľ žiadne kvízy", "Još nema kvizova"),
    "profile.quiz.emptySubtitle": row3(
        "Dokončaj tečaj in opravi svoj prvi kviz.",
        "Dokonči kurz a daj si prvý kvíz.",
        "Završi kurs da odradiš svoj prvi kviz."),
    "profile.progress.bySubject": row3(
        "NAPREDEK PO TEMAH", "POKROK PODĽA TÉM", "NAPREDAK PO TEMAMA"),
    "profile.stats.coursesDone": row3(
        "Končani tečaji", "Dokončené kurzy", "Završeni kursevi"),
    "profile.mastery.title": row3(
        "TVOJ ZEMLJEVID ZNANJA", "TVOJA MAPA VEDOMOSTÍ", "TVOJA MAPA ZNANJA"),
    "profile.mastery.details": row3(
        "Prikaži podrobnosti po predmetih", "Zobraziť detaily podľa predmetu",
        "Prikaži detalje po predmetima"),
    "profile.mastery.hide": row3(
        "Skrij podrobnosti", "Skryť detaily", "Sakrij detalje"),
    "profile.unlock.trial": row3(
        "Odkleni z brezplačnim preizkusom", "Odomkni bezplatnou skúškou",
        "Otključaj uz besplatnu probu"),
    "profile.quiz.retry": row3("Ponovi", "Znova", "Ponovi"),
    "profile.quiz.all": row3(
        "Vsi moji kvizi", "Všetky moje kvízy", "Svi moji kvizovi"),
    "profile.quiz.none": row3(
        "Trenutno ni kvizov.", "Zatiaľ žiadne kvízy.", "Trenutno nema kvizova."),
    "profile.progress.max": row3(
        "%d XP · najvišja raven", "%d XP · max. úroveň", "%d XP · maks. nivo"),
    "profile.progress.toNext": row3(
        "%d XP · %d do rav. %d", "%d XP · %d do úr. %d", "%d XP · %d do nivoa %d"),
})

# --- friends leaderboard ---------------------------------------------------
STRINGS3.update({
    "friends.title": row3(
        "LESTVICA PRIJATELJEV", "REBRÍČEK PRIATEĽOV", "LISTA PRIJATELJA"),
    "friends.you": row3("Ti", "Ty", "Ti"),
    "friends.add.short": row3("Dodaj", "Pridať", "Dodaj"),
    "friends.add.title": row3(
        "Dodaj prijatelja", "Pridať priateľa", "Dodaj prijatelja"),
    "friends.add.subtitle": row3(
        "Vpiši @ svojega prijatelja, da ga dodaš na svojo lestvico.",
        "Zadaj @ svojho kamaráta a pridaj ho do svojho rebríčka.",
        "Upiši @ svog prijatelja da ga dodaš na svoju listu."),
    "friends.add.requestSubtitle": row3(
        "Vpiši @ svojega prijatelja: prejel bo prošnjo, ki jo lahko sprejme.",
        "Zadaj @ svojho kamaráta: príde mu žiadosť na potvrdenie.",
        "Upiši @ svog prijatelja: dobiće zahtev koji može da prihvati."),
    "friends.request.send": row3(
        "Pošlji prošnjo", "Odoslať žiadosť", "Pošalji zahtev"),
    "friends.request.sent": row3(
        "Prošnja poslana!", "Žiadosť odoslaná!", "Zahtev poslat!"),
    "friends.request.autoAccepted": row3(
        "Zdaj sta prijatelja!", "Teraz ste priatelia!", "Sada ste prijatelji!"),
    "friends.requests.title": row3(
        "PREJETE PROŠNJE", "PRIJATÉ ŽIADOSTI", "PRIMLJENI ZAHTEVI"),
    "friends.requests.accept": row3("Sprejmi", "Prijať", "Prihvati"),
    "friends.requests.decline": row3("Zavrni", "Odmietnuť", "Odbij"),
    "friends.error.alreadyFriends": row3(
        "Že sta prijatelja.", "Už ste priatelia.", "Već ste prijatelji."),
    "friends.error.requestAlreadySent": row3(
        "Prošnja je že poslana.", "Žiadosť je už odoslaná.",
        "Zahtev je već poslat."),
    "friends.error.requestNotFound": row3(
        "Ta prošnja ni več na voljo.", "Táto žiadosť už nie je dostupná.",
        "Ovaj zahtev više nije dostupan."),
    "friends.add.action": row3("Dodaj", "Pridať", "Dodaj"),
    "friends.add.success": row3(
        "Prijatelj dodan!", "Priateľ pridaný!", "Prijatelj dodat!"),
    "friends.handle.placeholder": row3(
        "uporabniško ime", "používateľské meno", "korisničko ime"),
    "friends.handle.edit.title": row3(
        "Spremeni svoj @", "Uprav svoje @", "Promeni svoj @"),
    "friends.handle.edit.subtitle": row3(
        "Po @ te prijatelji najdejo.", "Vďaka @ ťa kamaráti nájdu.",
        "Po @ te prijatelji mogu pronaći."),
    "friends.handle.save": row3("Shrani", "Uložiť", "Sačuvaj"),
    "friends.handle.rules": row3(
        "3–20 znakov, samo črke in številke, začne se s črko.",
        "3–20 znakov, iba písmená a číslice, musí začínať písmenom.",
        "3–20 znakova, samo slova i brojevi, počinje slovom."),
    "friends.period.week": row3("7 dni", "7 dní", "7 dana"),
    "friends.period.all": row3("Skupaj", "Celkovo", "Ukupno"),
    "friends.empty.title": row3(
        "Še ni prijateljev", "Zatiaľ žiadni priatelia", "Još nema prijatelja"),
    "friends.empty.body": row3(
        "Dodaj prijatelje prek @ in primerjajta XP.",
        "Pridaj si kamarátov cez ich @ a porovnávajte XP.",
        "Dodaj prijatelje preko @ da uporedite XP."),
    "friends.signedOut.title": row3(
        "Prijavi se za prijatelje", "Prihlás sa a pridaj priateľov",
        "Prijavi se za prijatelje"),
    "friends.signedOut.body": row3(
        "Ustvari račun, da dobiš @ in dodajaš prijatelje.",
        "Vytvor si účet, získaj @ a pridávaj kamarátov.",
        "Napravi nalog da dobiješ @ i dodaješ prijatelje."),
    "friends.remove": row3(
        "Odstrani prijatelja", "Odobrať priateľa", "Ukloni prijatelja"),
    "friends.remove.title": row3(
        "Odstraniš tega prijatelja?", "Odobrať tohto priateľa?",
        "Ukloniti ovog prijatelja?"),
    "friends.remove.message": row3(
        "Pozneje ga lahko spet dodaš prek @.",
        "Neskôr si ho môžeš znova pridať cez jeho @.",
        "Kasnije ga možeš ponovo dodati preko @."),
    "friends.remove.confirm": row3("Odstrani", "Odstrániť", "Ukloni"),
    "friends.stats.streak": row3("Dni zapored", "Dní v rade", "Dana zaredom"),
    "friends.stats.quizzes": row3(
        "Končani kvizi", "Hotové kvízy", "Završeni kvizovi"),
})

# --- quiz feedback, course end, prepaywall, global ranks ------------------
# `globalRank.xpBefore` inserts a rank NAME after a preposition governing the
# genitive in all three, so the frame reads "do ranga %@" / "do ranga %@" and
# the name keeps its nominative dictionary form. Same reason
# `course.streak.message` puts the subject in apposition after "tema"/"tema".
STRINGS3.update({
    "friends.error.generic": row3(
        "Prišlo je do napake. Poskusi znova.",
        "Niečo sa pokazilo. Skús to znova.",
        "Došlo je do greške. Pokušaj ponovo."),
    "friends.error.notSignedIn": row3(
        "Prijavi se za nadaljevanje.", "Prihlás sa, aby si mohol pokračovať.",
        "Prijavi se da nastaviš."),
    "friends.error.invalidHandle": row3(
        "Ta @ ni veljaven.", "Toto @ je neplatné.", "Ovaj @ nije važeći."),
    "friends.error.handleTaken": row3(
        "Ta @ je že zaseden.", "Toto @ je už obsadené.", "Ovaj @ je već zauzet."),
    "friends.error.userNotFound": row3(
        "Nobenega uporabnika s tem @.", "Žiadny používateľ s týmto @.",
        "Nema korisnika s tim @."),
    "friends.error.cannotAddSelf": row3(
        "Sebe ne moreš dodati.", "Sám seba pridať nemôžeš.",
        "Ne možeš dodati samog sebe."),
    "friends.error.notFriends": row3(
        "Nista prijatelja.", "Nie ste priatelia.", "Niste prijatelji."),
    "quiz.feedback.correct": row3("Pravilno!", "Správne!", "Tačno!"),
    "quiz.feedback.excellent": row3("Odlično!", "Skvelé!", "Odlično!"),
    "quiz.feedback.amazing": row3("Neverjetno!", "Úžasné!", "Neverovatno!"),
    "quiz.feedback.wrong": row3(
        "Ne čisto...", "Nie celkom...", "Ne baš..."),
    "quiz.completed": row3(
        "Bravo, kviz je končan!", "Výborne, kvíz je hotový!",
        "Bravo, kviz je gotov!"),
    "quiz.correctAnswers": row3(
        "pravilnih odgovorov", "správnych odpovedí", "tačnih odgovora"),
    "quiz.xpProgress": row3("Napredek XP", "Pokrok v XP", "XP napredak"),
    "quiz.levelUp": row3("Nova raven!", "Nová úroveň!", "Novi nivo!"),
    "quiz.breakdown.correct": row3(
        "Pravilni odgovori", "Správne odpovede", "Tačni odgovori"),
    "quiz.breakdown.completed": row3(
        "Kviz končan", "Kvíz dokončený", "Kviz završen"),
    "quiz.xpProgress.max": row3(
        "%d XP · najvišja raven", "%d XP · max. úroveň", "%d XP · maks. nivo"),
    "quiz.xpProgress.toNext": row3(
        "%d XP do rav. %d", "%d XP do úr. %d", "%d XP do nivoa %d"),
    "quiz.pointsEarned": row3(
        "osvojenih točk", "získaných bodov", "osvojenih poena"),
    "quiz.feedback.close": row3("Skoraj!", "Skoro!", "Skoro!"),
    "quiz.feedback.far": row3("Blizu", "Blízko", "Blizu"),
    "quiz.trueFalse.true": row3("Prav", "Pravda", "Tačno"),
    "quiz.trueFalse.false": row3("Narobe", "Nepravda", "Netačno"),
    "quiz.chronological.instruction": row3(
        "Razvrsti dogodke po času (tapni ali povleci).",
        "Zoraď udalosti chronologicky (ťukni alebo potiahni).",
        "Poređaj događaje hronološki (dodirni ili prevuci)."),
    "quiz.chronological.remaining": row3(
        "Preostali odgovori", "Zostávajúce odpovede", "Preostali odgovori"),
    "quiz.chronological.emptySlot": row3(
        "Prazno mesto", "Prázdne miesto", "Prazno mesto"),
    "quiz.chronological.validate": row3(
        "Potrdi vrstni red", "Potvrdiť poradie", "Potvrdi redosled"),
    "quiz.chronological.correctOrder": row3(
        "Pravilni vrstni red", "Správne poradie", "Tačan redosled"),
    "quiz.slider.validate": row3("Potrdi", "Potvrdiť", "Potvrdi"),
    "quiz.slider.yourGuess": row3(
        "Tvoj odgovor", "Tvoja odpoveď", "Tvoj odgovor"),
    "quiz.slider.correctAnswer": row3(
        "Pravilni odgovor", "Správna odpoveď", "Tačan odgovor"),
    "course.completed": row3(
        "Tečaj je končan!", "Kurz je dokončený!", "Kurs je završen!"),
    "course.dailyFreeDone": row3(
        "Končal si današnji brezplačni tečaj",
        "Dokončil si dnešný bezplatný kurz",
        "Završio si današnji besplatni kurs"),
    "course.unlock.free": row3(
        "Odkleni brezplačno", "Odomknúť zadarmo", "Otključaj besplatno"),
    "course.quiz.access": row3(
        "Odpri kviz", "Otvoriť kvíz", "Otvori kviz"),
    "course.unlock.cta": row3(
        "Odkleni tečaj", "Odomknúť kurz", "Otključaj kurs"),
    "course.streak.day": row3("Dan zapored", "Deň v rade", "Dan zaredom"),
    "course.streak.days": row3("Dni zapored", "Dní v rade", "Dana zaredom"),
    "course.streak.message": row3(
        "Res napreduješ — tema »%@« ti ne more več nič!",
        "Naozaj napreduješ — téma „%@“ ti už nič nespraví!",
        "Stvarno napreduješ — tema „%@“ ti više ne može ništa!"),
    "course.streak.onTrack": row3(
        "Niz se že začenja!", "Séria je na spadnutie!", "Niz je na pomolu!"),
    "prepaywall.quiz.title": row3(
        "Odkleni kvize\nbrezplačno", "Odomkni kvízy\nzadarmo",
        "Otključaj kvizove\nbesplatno"),
    "prepaywall.quiz.subtitle": row3(
        "Preveri svoje znanje in\nnapreduj vsak dan",
        "Over si vedomosti a\nposúvaj sa každý deň",
        "Proveri znanje i\nnapreduj svakog dana"),
    "prepaywall.course.subtitle": row3(
        "Uči se naprej in\nodkrivaj nove teme",
        "Uč sa ďalej a\nobjavuj nové témy",
        "Nastavi da učiš i\notkrivaj nove teme"),
    "prepaywall.course.access": row3(
        "Odpri tečaj", "Otvoriť kurz", "Otvori kurs"),
    "levelUp.title": row3("Nova raven!", "Nová úroveň!", "Novi nivo!"),
    "globalRank.curieux": row3("Radovednež", "Zvedavec", "Radoznalac"),
    "globalRank.erudit": row3("Razgledanec", "Znalec", "Erudita"),
    "globalRank.savant": row3("Učenjak", "Učenec", "Znalac"),
    "globalRank.maitre": row3("Mojster", "Majster", "Majstor"),
    "globalRank.legende": row3("Legenda", "Legenda", "Legenda"),
    "globalRank.title": row3(
        "Globalni rang", "Globálna hodnosť", "Globalni rang"),
    "globalRank.badge": row3(
        "GLOBALNI RANG", "GLOBÁLNA HODNOSŤ", "GLOBALNI RANG"),
    "globalRank.maxLevel": row3(
        "Najvišja raven", "Najvyššia úroveň", "Najviši nivo"),
    "globalRank.xpBefore": row3(
        "%d XP do ranga %@", "%d XP do hodnosti %@", "%d XP do ranga %@"),
    "globalRank.newRank": row3("Nov rang!", "Nová hodnosť!", "Novi rang!"),
    "globalRank.reachedLevel": row3(
        "Pravkar si dosegel raven %d", "Práve si dosiahol úroveň %d",
        "Upravo si dostigao nivo %d"),
    "paywall.unavailable.title": row3(
        "Ponudba ni na voljo", "Ponuka nie je dostupná", "Ponuda nije dostupna"),
    "paywall.unavailable.message": row3(
        "Te ponudbe trenutno ni mogoče naložiti.",
        "Túto ponuku sa teraz nedá načítať.",
        "Trenutno nije moguće učitati ovu ponudu."),
    "course.finish": row3(
        "Končaj tečaj", "Dokončiť kurz", "Završi kurs"),
    "course.funFact.hint": row3(
        "Tapni za razkritje", "Ťukni a odhaľ", "Dodirni da otkriješ"),
    "onboardingV2.pw.pro": row3("PRO", "PRO", "PRO"),
    "quiz.combo": row3("Kombo x%d", "Kombo x%d", "Kombo x%d"),
})
