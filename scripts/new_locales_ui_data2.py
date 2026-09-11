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
  sr  Serbian — informal "ти", Cyrillic (the default script for the `sr`
      locale on iOS) and Ekavian, the standard of Serbia: "лепо", "време",
      "где". курс, квиз, ниво, "дана заредом", библиотека. Practice section =
      "Понављање". Quotes: „…“.

Latin brand names (Sophia, Premium, Pro, App Store, XP) stay Latin in Serbian:
that is what Serbian tech writing does, and it keeps the StoreKit product names
matching what the App Store actually shows. In Cyrillic they also stay
UNDECLINED — "уз Sophia", never the hyphenated "Sophia-om" — exactly as the
Russian table treats them; sentences are worded so the brand never needs a case
ending. Slovenian and Slovak decline it normally instead ("s Sophio",
"so Sophiou"), because there the name sits in the same script as the sentence. Testimonial first names are
transliterated in Serbian only (Леа, Камиј, Јанис, Инес, Тома, Сара, Малик),
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
    "tab.home": row3("Domov", "Domov", "Почетна"),
    "tab.library": row3("Knjižnica", "Knižnica", "Библиотека"),
    "tab.collections": row3("Zbirke", "Zbierky", "Збирке"),
    "tab.profile": row3("Profil", "Profil", "Профил"),
    "tab.training": row3("Ponavljanje", "Opakovanie", "Понављање"),
    "training.title": row3("Ponavljanje", "Opakovanie", "Понављање"),
    "training.readyTitle": row3(
        "Čas je za ponavljanje", "Čas na opakovanie", "Време је за понављање"),
    "training.dueCount": row3(
        "%d vprašanj za ponovitev danes", "%d otázok na dnešné opakovanie",
        "%d питања за понављање данас"),
    "training.emptyTitle": row3(
        "Vse je opravljeno!", "Všetko máš hotové!", "Све је одрађено!"),
    "training.emptyMessage": row3(
        "Vrni se jutri in nadaljuj s ponavljanjem.",
        "Vráť sa zajtra a pokračuj v opakovaní.",
        "Врати се сутра и настави са понављањем."),
    "training.locked.title": row3(
        "Odkleni Ponavljanje", "Odomkni Opakovanie", "Откључај Понављање"),
    "training.locked.message": row3(
        "Reši kviz nekega tečaja in njegova vprašanja pristanejo tukaj — ponovil jih boš točno takrat, ko je treba.",
        "Dokonči kvíz niektorého kurzu a jeho otázky pristanú tu — zopakuješ si ich presne vtedy, keď treba.",
        "Уради квиз неког курса и његова питања стижу овде — поновићеш их тачно када треба."),
    "training.locked.tagline": row3(
        "Zapomni si, kar se učiš — zares.",
        "Zapamätaj si, čo sa učíš — natrvalo.",
        "Запамти оно што учиш, заиста."),
    "training.unlock": row3(
        "Odkleni Ponavljanje", "Odomknúť Opakovanie", "Откључај Понављање"),
    "training.discover": row3("Odkrij", "Objaviť", "Откриј"),
    "training.how.title": row3(
        "KAKO DELUJE", "AKO TO FUNGUJE", "КАКО ФУНКЦИОНИШЕ"),
    "training.how.step1": row3(
        "Dokončaj tečaj in njegov kviz", "Dokonči kurz a jeho kvíz",
        "Заврши курс и његов квиз"),
    "training.how.step2": row3(
        "Njegova vprašanja gredo v Ponavljanje",
        "Jeho otázky idú do Opakovania",
        "Његова питања иду у Понављање"),
    "training.how.step3": row3(
        "Ponovi jih v pravem trenutku, da jih ne pozabiš",
        "Zopakuj si ich v pravý čas, aby si ich nezabudol",
        "Понови их у правом тренутку да их не заборавиш"),
    "training.emptyCta": row3("Odkrij tečaj", "Objaviť kurz", "Откриј курс"),
    "training.ob.welcome.line": row3(
        "To je Ponavljanje.", "Toto je Opakovanie.", "Ово је Понављање."),
    "training.ob.recall.title": row3(
        "Sprašujemo te, da naučeno res ostane.",
        "Pýtame sa ťa, aby ti naučené naozaj zostalo.",
        "Постављамо ти питања да научено заиста остане."),
    "training.ob.recall.legend.sophia": row3(
        "S Sophio", "So Sophiou", "Уз Sophia"),
    "training.ob.recall.legend.reread": row3(
        "Navadno ponovno branje", "Obyčajné opätovné čítanie",
        "Обично поновно читање"),
    "training.ob.recall.stat.prefix": row3(
        "Po enem tednu si redni uporabniki Sophia Ponavljanja zapomnijo",
        "Po týždni si pravidelní používatelia Sophia Opakovania pamätajú",
        "После недељу дана редовни корисници Sophia Понављања памте"),
    "training.ob.recall.stat.highlight": row3(
        "2,2× več", "2,2× viac", "2,2× више"),
    "training.ob.recall.stat.suffix": row3(
        "snovi svojih tečajev kot tisti, ki ga ne uporabljajo.",
        "z učiva svojich kurzov než ten, kto ho nepoužíva.",
        "градива својих курсева него онај ко га не користи."),
    "training.ob.recall.cta": row3(
        "Kako deluje", "Ako to funguje", "Како функционише"),
    "training.ob.algo.title": row3(
        "Algoritem te sprašuje neprestano", "Algoritmus ťa skúša neustále",
        "Алгоритам те испитује непрестано"),
    "training.ob.algo.body": row3(
        "Vračamo ti kvize, ki si jih že rešil, točno ob pravem času. Vsi so zbrani tukaj.",
        "Vraciame ti kvízy, ktoré si už vyriešil, presne načas. Všetky sú tu na jednom mieste.",
        "Враћамо ти квизове које си већ урадио, тачно на време. Сви су овде, на једном месту."),
})

# --- training session chrome, library chrome, language picker --------------
# Language names are autonyms: identical in every table, including these three.
STRINGS3.update({
    "training.ob.algo.highlight.value": row3(
        "5 min/dan", "5 min/deň", "5 мин/дан"),
    "training.ob.algo.highlight.label": row3(
        "za spomin, ki res zdrži.",
        "pre pamäť, ktorá naozaj vydrží.",
        "за памћење које стварно траје."),
    "training.ob.cta.last": row3("Naprej", "Pokračovať", "Настави"),
    "training.start": row3("Začni", "Začať", "Почни"),
    "training.finish": row3("Končaj", "Dokončiť", "Заврши"),
    "training.backToTraining": row3("Nazaj", "Späť", "Назад"),
    "training.sessionComplete.title": row3(
        "Konec kroga", "Opakovanie hotové", "Крај круга"),
    "training.sessionComplete.summary": row3(
        "%d pravilnih od %d", "%d správne z %d", "%d тачних од %d"),
    "library.title": row3("Knjižnica", "Knižnica", "Библиотека"),
    "library.tab.courses": row3("Tečaji", "Kurzy", "Курсеви"),
    "library.tab.collections": row3("Zbirke", "Zbierky", "Збирке"),
    "library.search.placeholder": row3(
        "Poišči tečaj...", "Nájdi kurz...", "Пронађи курс..."),
    "language.section": row3("Jezik", "Jazyk", "Језик"),
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
        "Постани начитан\nза 10 минута\nдневно"),
    "onboarding.intro.cta": row3("Začni", "Poďme na to", "Крени"),
    "onboarding.language.title": row3(
        "Izberi svoj jezik", "Vyber si jazyk", "Изабери свој језик"),
    "onboarding.language.subtitle": row3(
        "Pozneje ga lahko zamenjaš.", "Neskôr ho môžeš zmeniť.",
        "Касније га можеш променити."),
})

# --- auth, account, sync conflict, onboardingV2 opening -------------------
STRINGS3.update({
    "discount.sideTab.label": row3("PONUDBA", "PONUKA", "ПОНУДА"),
    "auth.error.token": row3(
        "Prijava ni uspela. Poskusi znova.",
        "Prihlásenie zlyhalo. Skús to znova.",
        "Пријава није успела. Покушај поново."),
    "auth.error.generic": row3(
        "Nekaj je šlo narobe. Poskusi znova.",
        "Niečo sa pokazilo. Skús to znova.",
        "Нешто је пошло наопако. Покушај поново."),
    "auth.continueWithApple": row3(
        "Nadaljuj z Apple", "Pokračovať s Apple", "Настави са Apple"),
    "auth.continueWithGoogle": row3(
        "Nadaljuj z Google", "Pokračovať s Google", "Настави са Google"),
    "auth.onboarding.title": row3(
        "Ustvari račun\nin začni", "Vytvor si účet\na začni",
        "Направи налог\nи крени"),
    "auth.onboarding.subtitle": row3(
        "Prijavi se, da shraniš napredek in ga imaš na vseh napravah.",
        "Prihlás sa, aby si mal postup uložený a dostupný na všetkých zariadeniach.",
        "Пријави се да сачуваш напредак и имаш га на свим уређајима."),
    "auth.legal.prefix": row3(
        "Z nadaljevanjem sprejmeš naše", "Pokračovaním súhlasíš s našimi",
        "Настављањем прихваташ наше"),
    "account.title": row3("Račun", "Účet", "Налог"),
    "account.signedIn.title": row3("Moj račun", "Môj účet", "Мој налог"),
    "account.manage.subtitle": row3(
        "Upravljaj svoj račun", "Spravuj svoj účet", "Управљај налогом"),
    "account.create.title": row3(
        "Ustvari račun", "Vytvor si účet", "Направи налог"),
    "account.create.subtitle": row3(
        "Shrani napredek v oblak", "Zálohuj svoj postup do cloudu",
        "Сачувај напредак у облаку"),
    "account.signedOut.headline": row3(
        "Shrani svoj napredek", "Zálohuj svoj postup", "Сачувај свој напредак"),
    "account.signedOut.body": row3(
        "Ustvari račun, da shraniš napredek in ga imaš na vseh napravah. Ni obvezno.",
        "Vytvor si účet, aby si mal postup uložený a dostupný na všetkých zariadeniach. Je to dobrovoľné.",
        "Направи налог да сачуваш напредак и имаш га на свим уређајима. Није обавезно."),
    "account.email": row3("E-pošta", "E-mail", "Имејл"),
    "account.provider": row3(
        "Prijavljen prek", "Prihlásený cez", "Пријављен преко"),
    "account.signOut.action": row3("Odjava", "Odhlásiť sa", "Одјава"),
    "account.signOut.title": row3("Se odjaviš?", "Odhlásiť sa?", "Одјавити се?"),
    "account.signOut.message": row3(
        "Tvoj napredek ostane shranjen na tej napravi.",
        "Tvoj postup zostane uložený v tomto zariadení.",
        "Твој напредак остаје сачуван на овом уређају."),
    "account.signOut.confirm": row3("Odjava", "Odhlásiť sa", "Одјава"),
    "account.delete.action": row3(
        "Izbriši moj račun", "Zmazať môj účet", "Обриши мој налог"),
    "account.delete.title": row3(
        "Izbrišeš račun?", "Zmazať účet?", "Обрисати налог?"),
    "account.delete.message": row3(
        "To je nepovratno. Tvoj račun in povezani podatki bodo izbrisani.",
        "Toto je nevratné. Tvoj účet a súvisiace údaje budú zmazané.",
        "Ово је неповратно. Твој налог и повезани подаци биће обрисани."),
    "account.delete.confirm": row3("Izbriši", "Zmazať", "Обриши"),
    "account.delete.error": row3(
        "Brisanje ni uspelo. Poskusi znova.",
        "Zmazanie zlyhalo. Skús to znova.",
        "Брисање није успело. Покушај поново."),
    "sync.conflict.title": row3(
        "Najdena sta dva napredka", "Našli sme dva postupy",
        "Пронађена су два напретка"),
    "sync.conflict.body": row3(
        "Izberi, kateri napredek obdržiš. Drugi bo zamenjan.",
        "Vyber, ktorý postup si necháš. Druhý bude nahradený.",
        "Изабери који напредак задржаваш. Други ће бити замењен."),
    "sync.conflict.local": row3("Ta naprava", "Toto zariadenie", "Овај уређај"),
    "sync.conflict.remote": row3("Tvoj račun", "Tvoj účet", "Твој налог"),
    "sync.conflict.summary": row3(
        "%d tečajev · raven %d · %d dni zapored",
        "%d kurzov · úroveň %d · %d dní v rade",
        "%d курсева · ниво %d · %d дана заредом"),
    "onboardingV2.welcome.title": row3(
        "Dobrodošel v Sophii", "Vitaj v Sophii", "Добро дошао у Sophia"),
    "onboardingV2.welcome.subtitle": row3(
        "Vsak dan postani malo bolj razgledan.",
        "Každý deň buď o kúsok rozhľadenejší.",
        "Постани мало паметнији сваког дана."),
    "onboardingV2.welcome.cta": row3("Začni", "Poďme na to", "Крени"),
    "onboardingV2.language.title": row3(
        "Izberi svoj jezik", "Vyber si jazyk", "Изабери свој језик"),
    "onboardingV2.language.subtitle": row3(
        "Podrsaj in si oglej vse jezike. Pozneje ga lahko zamenjaš.",
        "Potiahni a pozri si všetky jazyky. Neskôr ho môžeš zmeniť.",
        "Превуци да видиш све језике. Касније га можеш променити."),
    "onboardingV2.language.scrollHint": row3(
        "Podrsaj za več jezikov", "Potiahni pre ďalšie jazyky",
        "Превуци за још језика"),
    "onboardingV2.objective.title": row3(
        "Kakšni so tvoji cilji?", "Aké sú tvoje ciele?", "Који су твоји циљеви?"),
    "onboardingV2.objective.subtitle": row3(
        "Izbereš lahko več njih.", "Môžeš si vybrať viac.",
        "Можеш изабрати више њих."),
    "onboardingV2.objective.cultivate": row3(
        "Vsak dan se naučiti kaj novega", "Každý deň sa niečo naučiť",
        "Сваког дана научити нешто"),
    "onboardingV2.objective.reduceScreen": row3(
        "Zmanjšati čas pred zaslonom", "Tráviť menej času na mobile",
        "Смањити време пред екраном"),
    "onboardingV2.objective.exams": row3(
        "Uspeti v šoli in na izpitih", "Zvládnuť školu a skúšky",
        "Успети у школи и на испитима"),
})

# --- onboardingV2: questions, screen time, exams testimonials, swipe ------
# Testimonial first names stay Latin in sl/sk and are transliterated in sr.
# The French school labels (prépa, terminale, L2, lycée) become the nearest
# local stage rather than a literal gloss.
STRINGS3.update({
    "onboardingV2.objective.impress": row3(
        "Zablesteti v družbi", "Zažiariť v spoločnosti", "Заблистати у друштву"),
    "onboardingV2.objective.curiosity": row3(
        "Učiti se iz radovednosti", "Učiť sa zo zvedavosti",
        "Учити из радозналости"),
    "onboardingV2.objectiveIntro.title": row3(
        "Sophia ti pomaga doseči vse tvoje cilje",
        "Sophia ti pomôže dosiahnuť všetky tvoje ciele",
        "Sophia ти помаже да оствариш све циљеве"),
    "onboardingV2.tapToContinue": row3(
        "Tapni kamor koli za naprej", "Ťukni kamkoľvek a pokračuj",
        "Додирни било где за наставак"),
    "onboardingV2.questions.title": row3(
        "S Sophio boš znal odgovoriti na ta vprašanja:",
        "So Sophiou budeš vedieť odpovedať na tieto otázky:",
        "Уз Sophia знаћеш да одговориш на ова питања:"),
    "onboardingV2.questions.q1": row3(
        "Zakaj je nebo modro?", "Prečo je nebo modré?", "Зашто је небо плаво?"),
    "onboardingV2.questions.q2": row3(
        "Kako je Napoleon zmagal pri Ulmu?",
        "Ako Napoleon vyhral pri Ulme?",
        "Како је Наполеон победио код Улма?"),
    "onboardingV2.questions.q3": row3(
        "Kaj je črna luknja?", "Čo je čierna diera?", "Шта је црна рупа?"),
    "onboardingV2.questions.q4": row3(
        "Kaj je impresionizem?", "Čo je impresionizmus?", "Шта је импресионизам?"),
    "onboardingV2.questions.q5": row3(
        "Kako deluje javni dolg?", "Ako funguje verejný dlh?",
        "Како функционише јавни дуг?"),
    "onboardingV2.questions.q6": row3(
        "Zakaj Luna ne pade?", "Prečo Mesiac nespadne?", "Зашто Месец не пада?"),
    "onboardingV2.questions.q7": row3(
        "Kdo je bila v resnici Kleopatra?", "Kto vlastne bola Kleopatra?",
        "Ко је заправо била Клеопатра?"),
    "onboardingV2.questions.q8": row3(
        "Kako je nastalo vesolje?", "Ako vznikol vesmír?",
        "Како је настао свемир?"),
    "onboardingV2.questions.q9": row3(
        "Zakaj ponoči sanjamo?", "Prečo v noci snívame?", "Зашто сањамо ноћу?"),
    "onboardingV2.questions.q10": row3(
        "Kaj je Einsteinova teorija relativnosti?",
        "Čo je Einsteinova teória relativity?",
        "Шта је Ајнштајнова теорија релативности?"),
    "onboardingV2.screenTime.title": row3(
        "Vzemi si čas nazaj", "Vezmi si čas späť", "Врати своје време"),
    "onboardingV2.screenTime.caption": row3(
        "Naši uporabniki zdaj na telefonu preživijo povprečno le 39 minut na dan.",
        "Naši používatelia teraz strávia na telefóne v priemere len 39 minút denne.",
        "Наши корисници сада на телефону проведу у просеку само 39 минута дневно."),
    "onboardingV2.screenTime.minutes": row3("%d min", "%d min", "%d мин"),
    "onboardingV2.phoneTime.title": row3(
        "Koliko časa na dan preživiš na telefonu?",
        "Koľko času denne tráviš na telefóne?",
        "Колико времена дневно проводиш на телефону?"),
    "onboardingV2.yearsGrid.title": row3(
        "Tukaj je tvoje življenje v letih", "Tu je tvoj život v rokoch",
        "Ево твог живота у годинама"),
    "onboardingV2.yearsGrid.caption": row3(
        "To je %d polnih let, ki jih v življenju izgubiš na telefonu.",
        "To je %d celých rokov, ktoré za život stratíš na telefóne.",
        "То је %d пуних година које у животу изгубиш на телефону."),
    "onboardingV2.transform.text": row3(
        "S Sophio spremeni ta čas v znanje",
        "So Sophiou premeň ten čas na vedomosti",
        "Уз Sophia претвори то време у знање"),
    "onboardingV2.transform.words": row3(
        "znanje, umetnost, filozofija, znanost, zgodovina, književnost",
        "vedomosti, umenie, filozofia, veda, história, literatúra",
        "знање, уметност, филозофија, наука, историја, књижевност"),
    "onboardingV2.transform.tapHint": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Додирни за наставак"),
    "onboardingV2.exams.title": row3(
        "Izboljšali so svoje ocene", "Zlepšili si známky",
        "Поправили су своје оцене"),
    "onboardingV2.exams.quote1": row3(
        "»Zaradi Sophie mi je povprečje pri zgodovini to ocenjevalno obdobje zraslo za 3 točke.«",
        "„Vďaka Sophii mi priemer z dejepisu za tento polrok stúpol o 3 body.“",
        "„Захваљујући Sophia, просек из историје ми је овог полугодишта порастао за 3 поена.“"),
    "onboardingV2.exams.author1": row3(
        "Thomas, študent", "Thomas, študent", "Тома, студент"),
    "onboardingV2.exams.quote2": row3(
        "»Ponavljam 10 minut na dan in ocene so mi res poletele.«",
        "„Opakujem si 10 minút denne a známky mi fakt vyleteli.“",
        "„Понављам 10 минута дневно и оцене су ми стварно скочиле.“"),
    "onboardingV2.exams.author2": row3(
        "Inès, zadnji letnik", "Inès, maturitný ročník", "Инес, матуранткиња"),
    "onboardingV2.exams.quote3": row3(
        "»Kvizi so mi pomagali zapomniti si bistvo pred izpiti.«",
        "„Kvízy mi pomohli zapamätať si to podstatné pred skúškami.“",
        "„Квизови су ми помогли да запамтим суштину пред испите.“"),
    "onboardingV2.exams.author3": row3(
        "Camille, faks", "Camille, vysoká škola", "Камиј, факултет"),
    "onboardingV2.exams.quote4": row3(
        "»Odlično za ponavljanje na poti. Profesorji so opazili razliko.«",
        "„Ideálne na opakovanie cestou. Učitelia si ten rozdiel všimli.“",
        "„Одлично за понављање у превозу. Професори су приметили разлику.“"),
    "onboardingV2.exams.author4": row3(
        "Yanis, gimnazija", "Yanis, stredná škola", "Јанис, средња школа"),
    "onboardingV2.rightPlace.title": row3(
        "Na pravem mestu si", "Si na správnom mieste", "На правом си месту"),
    "onboardingV2.rightPlace.ofUsers": row3(
        "uporabnikov", "používateľov", "корисника"),
    "onboardingV2.rightPlace.caption": row3(
        "…s tem ciljem res napreduje s Sophio.",
        "…s týmto cieľom so Sophiou naozaj napreduje.",
        "…са овим циљем стварно напредује уз Sophia."),
    "onboardingV2.swipe.title": row3(
        "Tečaji, izbrani zate", "Kurzy vybrané pre teba",
        "Курсеви изабрани за тебе"),
    "onboardingV2.swipe.subtitle": row3(
        "Kar te zanima, podrsaj v desno.",
        "Čo ťa zaujíma, potiahni doprava.",
        "Оно што те занима превуци удесно."),
    "onboardingV2.swipe.like": row3("Všeč mi je", "Páči sa mi", "Свиђа ми се"),
    "onboardingV2.swipe.nope": row3("Ne", "Nie", "Не"),
    "onboardingV2.swipe.noted": row3("Zabeleženo!", "Mám to!", "Забележено!"),
    "onboardingV2.phone.title": row3(
        "Koliko časa preživiš na telefonu?",
        "Koľko času tráviš na telefóne?",
        "Колико времена проводиш на телефону?"),
    "onboardingV2.phone.perDay": row3("na dan", "za deň", "дневно"),
    "onboardingV2.weeks.title": row3(
        "To je %d tednov na leto", "To je %d týždňov ročne",
        "То је %d недеља годишње"),
    "onboardingV2.weeks.subtitle": row3(
        "To je tvoje leto. Rdeče: čas pred zaslonom.",
        "Toto je tvoj rok. Červeno: čas strávený pri obrazovke.",
        "Ово је твоја година. Црвено: време пред екраном."),
})

# --- onboardingV2: review carousel, profile archetypes, loading, trial ----
# Testimonial 3 is Inès and testimonial 5 Sarah, so the Slavic past tense goes
# feminine there; the other quotes are worded to need no gender at all.
STRINGS3.update({
    "onboardingV2.weeks.caption": row3(
        "Predstavljaj si, kaj bi se lahko naučil z drobcem tega časa.",
        "Predstav si, čo by si sa stihol naučiť za zlomok toho času.",
        "Замисли шта би могао да научиш са делићем тог времена."),
    "onboardingV2.review.title": row3(
        "Evo, kaj o tem menijo naši uporabniki",
        "Toto si myslia naši používatelia",
        "Ево шта мисле наши корисници"),
    "onboardingV2.review.appStore": row3(
        "na App Storeu", "na App Store", "на App Store-у"),
    "onboardingV2.review.quote": row3(
        "»Prej sem na telefonu preživel 7 ur na dan. Zdaj le 40 minut s Sophio in vsak teden se počutim pametnejšega.«",
        "„Predtým som na telefóne trávil 7 hodín denne. Teraz len 40 minút so Sophiou a každý týždeň sa cítim múdrejší.“",
        "„Раније сам на телефону проводио 7 сати дневно. Сада само 40 минута уз Sophia и сваке недеље се осећам паметније.“"),
    "onboardingV2.review.author": row3("Léa, 24", "Léa, 24", "Леа, 24"),
    "onboardingV2.review.t1.quote": row3(
        "Odkar manj drsam po zaslonu in uporabljam Sophio, se mi zdi, da si zapomnim veliko več.",
        "Odkedy menej scrollujem a používam Sophiu, mám pocit, že si pamätám oveľa viac.",
        "Откад мање скролујем и користим Sophia, чини ми се да памтим много више."),
    "onboardingV2.review.t1.author": row3(
        "Camille, 22", "Camille, 22", "Камиј, 22"),
    "onboardingV2.review.t2.quote": row3(
        "10 minut zjutraj na avtobusu in zvečer imam o čem govoriti. Iskreno, zasvojilo me je.",
        "10 minút ráno v električke a večer mám o čom hovoriť. Úprimne, chytilo ma to.",
        "10 минута ујутру у аутобусу и увече имам о чему да причам. Искрено, увукло ме је."),
    "onboardingV2.review.t2.author": row3("Yanis, 27", "Yanis, 27", "Јанис, 27"),
    "onboardingV2.review.t3.quote": row3(
        "Vedno sem sovražila »piflanje«, tukaj pa se vse usede kar samo. Spomin me preseneča.",
        "Vždy som nenávidela „bifľovanie“, ale tu to sadne samo od seba. Pamäť ma prekvapuje.",
        "Одувек сам мрзела „бубање“, а овде све седне само од себе. Памћење ме изненађује."),
    "onboardingV2.review.t3.author": row3("Inès, 19", "Inès, 19", "Инес, 19"),
    "onboardingV2.review.t4.quote": row3(
        "Neskončno drsanje zamenjam za tečaj. V enem mesecu so ljudje okrog mene opazili razliko.",
        "Nekonečné scrollovanie mením za kurz. Za mesiac si ľudia okolo mňa všimli rozdiel.",
        "Бескрајно скроловање мењам за курс. За месец дана људи око мене приметили су разлику."),
    "onboardingV2.review.t4.author": row3("Thomas, 31", "Thomas, 31", "Тома, 31"),
    "onboardingV2.review.t5.quote": row3(
        "Končno aplikacija, ob kateri čutim, da napredujem, ne da zapravljam čas. Odprem jo vsak dan.",
        "Konečne aplikácia, pri ktorej mám pocit, že napredujem, a nie že strácam čas. Otváram ju každý deň.",
        "Коначно апликација уз коју осећам да напредујем, а не да губим време. Отварам је сваког дана."),
    "onboardingV2.review.t5.author": row3("Sarah, 26", "Sarah, 26", "Сара, 26"),
    "onboardingV2.review.t6.quote": row3(
        "Kvizi v razmikih so prava magija: stvari izpred tednov si zapomnim brez truda.",
        "Kvízy s odstupom sú čistá mágia: pamätám si veci spred týždňov bez námahy.",
        "Квизови у размацима су права магија: памтим ствари од пре неколико недеља без муке."),
    "onboardingV2.review.t6.author": row3("Malik, 23", "Malik, 23", "Малик, 23"),
    "onboardingV2.personalize.text": row3(
        "Prilagodimo tvojo vsebino", "Prispôsobme ti obsah",
        "Прилагодимо твој садржај"),
    "onboardingV2.personalize.tapHint": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Додирни за наставак"),
    "onboardingV2.profile.eyebrow": row3(
        "Tukaj je tvoj profil", "Tu je tvoj profil", "Ево твог профила"),
    "onboardingV2.profile.objectiveTitle": row3(
        "Tvoj cilj", "Tvoj cieľ", "Твој циљ"),
    "onboardingV2.profile.coursesTitle": row3(
        "Tečaji, ki te čakajo", "Kurzy, ktoré na teba čakajú",
        "Курсеви који те чекају"),
    "onboardingV2.profile.cta": row3("Gremo", "Ideme na to", "Идемо"),
    "onboardingV2.profile.nickname.cultivate": row3(
        "Radovedni um", "Zvedavá myseľ", "Радознали ум"),
    "onboardingV2.profile.nickname.reduceScreen": row3(
        "Gospodar časa", "Pán času", "Господар времена"),
    "onboardingV2.profile.nickname.exams": row3("Strateg", "Stratég", "Стратег"),
    "onboardingV2.profile.nickname.impress": row3(
        "Blesteči", "Žiarivý", "Блистави"),
    "onboardingV2.profile.nickname.curiosity": row3(
        "Raziskovalec", "Prieskumník", "Истраживач"),
    "onboardingV2.profile.tagline.cultivate": row3(
        "Svet hočeš razumeti, vsak dan malo bolj.",
        "Chceš svetu rozumieť, každý deň o kúsok viac.",
        "Желиш да разумеш свет, сваког дана мало више."),
    "onboardingV2.profile.tagline.reduceScreen": row3(
        "Nadzor nad svojim časom in pozornostjo jemlješ nazaj.",
        "Berieš si späť kontrolu nad svojím časom a pozornosťou.",
        "Враћаш контролу над својим временом и пажњом."),
    "onboardingV2.profile.tagline.exams": row3(
        "Učiš se z metodo in si pripravljen, ko je pomembno.",
        "Učíš sa systematicky a si pripravený, keď na tom záleží.",
        "Учиш са методом и спреман си кад је важно."),
    "onboardingV2.profile.tagline.impress": row3(
        "Kmalu boš ti imel najboljše zgodbe.",
        "Čoskoro budeš ty ten s najlepšími historkami.",
        "Ускоро ћеш ти имати најбоље приче."),
    "onboardingV2.profile.tagline.curiosity": row3(
        "Tvoja radovednost nima meja — nahranimo jo.",
        "Tvoja zvedavosť nemá hranice — nakŕmme ju.",
        "Твоја радозналост нема границе — нахранимо је."),
    "onboardingV2.loading.title": row3(
        "Pripravljamo tvoj profil", "Pripravujeme tvoj profil",
        "Припремамо твој профил"),
    "onboardingV2.loading.step1": row3(
        "Analiza tvojega cilja", "Analýza tvojho cieľa", "Анализа твог циља"),
    "onboardingV2.loading.step2": row3(
        "Izbor tvojih tečajev", "Výber tvojich kurzov", "Одабир твојих курсева"),
    "onboardingV2.loading.step3": row3(
        "Izdelava tvojega programa", "Zostavovanie tvojho programu",
        "Израда твог програма"),
    "onboardingV2.loading.cta": row3(
        "Pokaži moj profil", "Zobraziť môj profil", "Прикажи мој профил"),
    "onboardingV2.loading.reviews": row3(
        "Več kot 1.000 mnenj", "Viac než 1 000 recenzií", "Више од 1.000 рецензија"),
    "onboardingV2.login.title": row3(
        "Ustvari svoj račun", "Vytvor si účet", "Направи свој налог"),
    "onboardingV2.login.subtitle": row3(
        "Da shraniš napredek in ga imaš na vseh napravah.",
        "Aby si mal postup uložený a dostupný na všetkých zariadeniach.",
        "Да сачуваш напредак и имаш га на свим уређајима."),
    "onboardingV2.trial.title": row3(
        "Kako deluje tvoje brezplačno preizkusno obdobje",
        "Ako funguje tvoje bezplatné skúšobné obdobie",
        "Како ради твој бесплатни пробни период"),
    "onboardingV2.trial.cta": row3(
        "Pripravljen sem", "Idem do toho", "Спреман сам"),
    "onboardingV2.trial.step0.title": row3(
        "Račun je ustvarjen", "Účet je vytvorený", "Налог је направљен"),
    "onboardingV2.trial.step0.detail": row3(
        "Tvoj profil je ustvarjen.", "Tvoj profil bol vytvorený.",
        "Твој профил је направљен."),
})

# --- onboardingV2: trial timeline, notifications, first paywall, settings --
STRINGS3.update({
    "onboardingV2.trial.step1.title": row3(
        "Danes: preizkusi Sophia Pro", "Dnes: vyskúšaj Sophia Pro",
        "Данас: испробај Sophia Pro"),
    "onboardingV2.trial.step1.detail": row3(
        "Nauči se nekaj novega v 5 minutah na dan.",
        "Nauč sa niečo nové za 5 minút denne.",
        "Научи нешто ново за 5 минута дневно."),
    "onboardingV2.trial.step2.title": row3(
        "2. dan: opomnik", "2. deň: pripomienka", "2. дан: подсетник"),
    "onboardingV2.trial.step2.detail": row3(
        "Sporočili ti bomo z obvestilom. Odpoveš v 15 sekundah.",
        "Dáme ti vedieť oznámením. Zrušíš to za 15 sekúnd.",
        "Јавићемо ти обавештењем. Отказујеш за 15 секунди."),
    "onboardingV2.trial.step3.title": row3(
        "3. dan: preizkus se izteče", "3. deň: skúšobné obdobie končí",
        "3. дан: пробни период истиче"),
    "onboardingV2.trial.step3.detail": row3(
        "Tvoja naročnina se začne %@.", "Tvoje predplatné sa začne %@.",
        "Твоја претплата почиње %@."),
    "onboardingV2.reminder.title": row3(
        "Opomnik dobiš 1 dan pred koncem preizkusnega obdobja.",
        "Pripomienku dostaneš 1 deň pred koncom skúšobného obdobia.",
        "Подсетник добијаш 1 дан пре краја пробног периода."),
    "onboardingV2.reminder.cta": row3(
        "Preizkusi brezplačno", "Vyskúšaj zadarmo", "Испробај бесплатно"),
    "onboardingV2.notifications.title": row3(
        "Ostani na tekočem", "Zostaň v obraze", "Остани у току"),
    "onboardingV2.notifications.subtitle": row3(
        "Diskreten opomnik, kadar je tečaj res vreden tvojega časa. Nič drugega.",
        "Nenápadná pripomienka, keď kurz naozaj stojí za tvoj čas. Nič iné.",
        "Дискретан подсетник кад курс стварно вреди твог времена. Ништа друго."),
    "onboardingV2.notifications.bullet1": row3(
        "Tečaj, izbran za tvoj profil", "Kurz vybraný pre tvoj profil",
        "Курс изабран за твој профил"),
    "onboardingV2.notifications.bullet2": row3(
        "Ob pravem času, nikoli v nizu", "V správnej chvíli, nikdy v sérii",
        "У правом тренутку, никад у низу"),
    "onboardingV2.notifications.bullet3": row3(
        "Izklopiš z enim tapom", "Vypneš jedným ťuknutím",
        "Искључујеш једним додиром"),
    "onboardingV2.notifications.cta": row3(
        "Vklopi obvestila", "Zapnúť oznámenia", "Укључи обавештења"),
    "onboardingV2.notifications.skip": row3("Pozneje", "Neskôr", "Касније"),
    "notification.courseNudge.title": row3(
        "Vredno ogleda danes", "Dnes stojí za pozretie", "Вреди погледати данас"),
    "notification.courseNudge.body": row3(
        "Odkrij »%@« — dovolj je pet minut.",
        "Objav „%@“ — päť minút stačí.",
        "Откриј „%@“ — довољно је пет минута."),
    "notification.courseNudge.bodyFallback": row3(
        "Čaka te nov tečaj — dovolj je pet minut.",
        "Čaká na teba nový kurz — päť minút stačí.",
        "Чека те нови курс — довољно је пет минута."),
    "trial.endingSoon.banner": row3(
        "Čez 1 dan izgubiš dostop do Sophia Premium.",
        "Za 1 deň stratíš prístup k Sophia Premium.",
        "За 1 дан губиш приступ Sophia Premium."),
    "onboardingV2.pw.tryFree": row3(
        "Preizkusi 3 dni brezplačno,", "Vyskúšaj 3 dni zadarmo,",
        "Испробај 3 дана бесплатно,"),
    "onboardingV2.pw.thenPrice": row3(
        "nato %@ (letna naplata, %@).",
        "potom %@ (účtované ročne, %@).",
        "затим %@ (наплата једном годишње, %@)."),
    "onboardingV2.pw.priceNoTrial": row3(
        "Premium za %@ (letna naplata, %@).",
        "Premium za %@ (účtované ročne, %@).",
        "Premium за %@ (наплата једном годишње, %@)."),
    "onboardingV2.pw.viewAllPlans": row3(
        "Vsi paketi", "Všetky plány", "Сви пакети"),
    "onboardingV2.pw.twoTaps": row3(
        "Dva tapa za začetek, odpoved je preprosta.",
        "Dve ťuknutia a ideš, zrušiť sa dá úplne ľahko.",
        "Два додира за почетак, отказивање је једноставно."),
    "onboardingV2.pw.startTrial": row3(
        "Zaženi 3 brezplačne dni", "Spustiť 3 dni zadarmo",
        "Покрени 3 бесплатна дана"),
    "onboardingV2.pw.subscribe": row3(
        "Naroči se", "Predplatiť si", "Претплати се"),
    "onboardingV2.pw.compare.title": row3(
        "Naročniki Pro se naučijo več in hitreje",
        "Predplatitelia Pro sa učia viac a rýchlejšie",
        "Pro претплатници уче више и брже"),
    "onboardingV2.pw.free": row3("Brezplačno", "Zadarmo", "Бесплатно"),
    "onboardingV2.pw.yearly": row3("Letno", "Ročne", "Годишње"),
    "onboardingV2.pw.monthly": row3("Mesečno", "Mesačne", "Месечно"),
    "onboardingV2.pw.monthlyBilling": row3(
        "naplata vsak mesec", "účtované každý mesiac", "наплата сваког месеца"),
    "onboardingV2.pw.trialBadge": row3(
        "3 dni brezplačno", "3 dni zadarmo", "3 дана бесплатно"),
    "onboardingV2.pw.save": row3("Prihraniš %@", "Ušetríš %@", "Уштеда %@"),
    "onboardingV2.pw.feature.allSubjects": row3(
        "Vse teme", "Všetky témy", "Све теме"),
    "onboardingV2.pw.feature.unlimited": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Неограничени курсеви"),
    "onboardingV2.pw.feature.quiz": row3(
        "Kvizi in ponavljanje", "Kvízy a opakovanie", "Квизови и понављање"),
    "onboardingV2.pw.feature.favorites": row3(
        "Neomejene priljubljene", "Neobmedzené obľúbené", "Неограничени фаворити"),
    "onboardingV2.pw.feature.noAds": row3(
        "Brez oglasov", "Žiadne reklamy", "Без реклама"),
    "onboardingV2.pw.feature.weekly": row3(
        "Novosti vsak teden", "Novinky každý týždeň", "Новости сваке недеље"),
    "settings.title": row3("Nastavitve", "Nastavenia", "Подешавања"),
    "settings.section.progress": row3("Napredek", "Pokrok", "Напредак"),
    "settings.section.premium": row3("Premium", "Premium", "Premium"),
    "settings.section.data": row3("Podatki", "Údaje", "Подаци"),
    "settings.section.help": row3("Pomoč", "Pomoc", "Помоћ"),
    "settings.section.legal": row3("Pravno", "Právne informácie", "Правне информације"),
    "settings.section.about": row3("O aplikaciji", "O aplikácii", "О апликацији"),
    "settings.section.developer": row3("Razvijalec", "Vývojár", "Програмер"),
    "settings.section.appearance": row3("Videz", "Vzhľad", "Изглед"),
})

# --- settings, debug rows, feedback form ----------------------------------
STRINGS3.update({
    "settings.appearance.light": row3("Svetlo", "Svetlý", "Светло"),
    "settings.appearance.dark": row3("Nočno", "Nočný", "Ноћно"),
    "settings.appearance.automatic": row3(
        "Samodejno", "Automaticky", "Аутоматски"),
    "settings.appearance.hint": row3(
        "Samodejno sledi nastavitvi telefona.",
        "Automaticky sleduje nastavenie telefónu.",
        "Аутоматски прати подешавање телефона."),
    "settings.courses.completed": row3(
        "%d končanih tečajev", "%d dokončených kurzov", "%d завршених курсева"),
    "settings.courses.available": row3(
        "od %d razpoložljivih", "z %d dostupných", "од %d доступних"),
    "settings.streak.title": row3(
        "%d dni zapored", "%d dní v rade", "%d дана заредом"),
    "settings.streak.subtitle": row3(
        "Kar tako naprej!", "Len tak ďalej!", "Само тако настави!"),
    "settings.premium.title": row3(
        "Preidi na Premium", "Prejdi na Premium", "Пређи на Premium"),
    "settings.premium.subtitle": row3(
        "Neomejeni tečaji in kvizi", "Neobmedzené kurzy a kvízy",
        "Неограничени курсеви и квизови"),
    "settings.reset.title": row3(
        "Ponastavi napredek", "Vynulovať pokrok", "Ресетуј напредак"),
    "settings.feedback.title": row3(
        "Pošlji povratno informacijo", "Odoslať spätnú väzbu",
        "Пошаљи повратну информацију"),
    "settings.feedback.subtitle": row3(
        "Napaka, ideja ali predlog vsebine",
        "Chyba, nápad alebo návrh obsahu",
        "Грешка, идеја или предлог садржаја"),
    "settings.ambassador.banner.badge": row3(
        "Premium brezplačno", "Premium zadarmo", "Premium бесплатно"),
    "settings.ambassador.banner.title": row3(
        "Postani ambasador", "Staň sa ambasádorom", "Постани амбасадор"),
    "settings.ambassador.banner.subtitle": row3(
        "Zasluži z objavljanjem Sophie na TikToku",
        "Zarábaj tým, že Sophiu zdieľaš na TikToku",
        "Заради објављујући Sophia на TikTok-у"),
    "settings.terms.title": row3(
        "Pogoji uporabe", "Podmienky používania", "Услови коришћења"),
    "settings.privacy.title": row3(
        "Pravilnik o zasebnosti", "Zásady ochrany súkromia",
        "Политика приватности"),
    "settings.restore.title": row3(
        "Obnovi nakupe", "Obnoviť nákupy", "Врати куповине"),
    "settings.about.version": row3("Različica", "Verzia", "Верзија"),
    "settings.about.courses": row3(
        "Razpoložljivi tečaji", "Dostupné kurzy", "Доступни курсеви"),
    "settings.debug.resetOnboarding": row3(
        "Ponovi uvod", "Zopakovať úvod", "Понови увод"),
    "settings.debug.resetDaily": row3(
        "Ponastavi dnevni tečaj", "Vynulovať denný kurz", "Ресетуј дневни курс"),
    "settings.debug.daily.done": row3(
        "Danes opravljeno", "Dnes hotovo", "Данас одрађено"),
    "settings.debug.daily.pending": row3(
        "Še ni opravljeno", "Ešte nie", "Још није одрађено"),
    "settings.footer": row3(
        "Narejeno s ♥ — Sophia", "Vyrobené s ♥ — Sophia",
        "Направљено с ♥ — Sophia"),
    "settings.reset.alert.title": row3(
        "Ponastaviš?", "Vynulovať?", "Ресетовати?"),
    "settings.reset.alert.cancel": row3("Prekliči", "Zrušiť", "Одустани"),
    "settings.reset.alert.confirm": row3(
        "Ponastavi", "Vynulovať", "Ресетуј"),
    "settings.reset.alert.message": row3(
        "Ves tvoj napredek bo izbrisan. Tega ni mogoče razveljaviti.",
        "Celý tvoj pokrok bude zmazaný. Nedá sa to vrátiť späť.",
        "Цео твој напредак биће обрисан. То се не може поништити."),
    "settings.onboarding.alert.title": row3(
        "Ponoviš uvod?", "Zopakovať úvod?", "Поновити увод?"),
    "settings.onboarding.alert.confirm": row3(
        "Ponovi", "Zopakovať", "Понови"),
    "settings.onboarding.alert.message": row3(
        "Uvod se bo začel od začetka (samo DEBUG).",
        "Úvod sa spustí odznova (iba DEBUG).",
        "Увод креће испочетка (само DEBUG)."),
    "feedback.title": row3(
        "Tvoja povratna informacija", "Tvoja spätná väzba",
        "Твоја повратна информација"),
    "feedback.subtitle": row3(
        "Preberemo vse. Povej nam, kaj ti je všeč, kaj ne deluje in česa manjka.",
        "Čítame všetko. Napíš nám, čo sa ti páči, čo nefunguje alebo čo chýba.",
        "Читамо све. Реци нам шта ти се свиђа, шта не ради и шта недостаје."),
    "feedback.category.label": row3("Kategorija", "Kategória", "Категорија"),
    "feedback.category.bug": row3("Napaka", "Chyba", "Грешка"),
    "feedback.category.idea": row3("Ideja", "Nápad", "Идеја"),
    "feedback.category.content": row3("Vsebina", "Obsah", "Садржај"),
    "feedback.category.other": row3("Drugo", "Iné", "Друго"),
    "feedback.message.label": row3("Sporočilo", "Správa", "Порука"),
    "feedback.message.placeholder": row3(
        "Opiši v nekaj stavkih…", "Popíš to v pár vetách…",
        "Опиши у пар реченица…"),
    "feedback.email.label": row3(
        "E-pošta (neobvezno)", "E-mail (nepovinné)", "Имејл (необавезно)"),
    "feedback.email.placeholder": row3(
        "Da ti lahko odgovorimo", "Aby sme ti mohli odpovedať",
        "Да можемо да ти одговоримо"),
    "feedback.technicalNote": row3(
        "Različica aplikacije, jezik in model naprave se priložijo samodejno, da ti lažje pomagamo.",
        "Verzia aplikácie, jazyk a model zariadenia sa prikladajú automaticky, aby sme ti vedeli pomôcť.",
        "Верзија апликације, језик и модел уређаја прилажу се аутоматски да бисмо лакше помогли."),
    "feedback.submit": row3("Pošlji", "Odoslať", "Пошаљи"),
    "feedback.error.generic": row3(
        "Trenutno ni mogoče poslati. Poskusi pozneje.",
        "Teraz sa to nedá odoslať. Skús to neskôr.",
        "Тренутно не може да се пошаље. Покушај касније."),
    "feedback.success.title": row3("Hvala!", "Ďakujeme!", "Хвала!"),
    "feedback.success.body": row3(
        "Tvoje sporočilo je poslano. Pozorno ga bomo prebrali.",
        "Tvoja správa odišla. Pozorne si ju prečítame.",
        "Твоја порука је послата. Пажљиво ћемо је прочитати."),
    "feedback.success.close": row3("Zapri", "Zavrieť", "Затвори"),
})

# --- ambassador program, legal, subjects ----------------------------------
STRINGS3.update({
    "ambassador.title": row3("Ambasador", "Ambasádor", "Амбасадор"),
    "ambassador.step.program": row3("Program", "Program", "Програм"),
    "ambassador.step.apply": row3("Prijava", "Prihláška", "Пријава"),
    "ambassador.program.heading": row3(
        "Postani ambasador Sophie", "Staň sa ambasádorom Sophie",
        "Постани Sophia амбасадор"),
    "ambassador.how.title": row3(
        "Kako deluje", "Ako to funguje", "Како функционише"),
    "ambassador.how.step1": row3(
        "Prijaviš se tukaj v 1 minuti.", "Prihlásiš sa tu za 1 minútu.",
        "Пријављујеш се овде за 1 минут."),
    "ambassador.how.step2": row3(
        "Damo ti vsebino, primere in mentorstvo.",
        "Dáme ti obsah, príklady aj koučing.",
        "Дајемо ти садржај, примере и подршку."),
    "ambassador.how.step3": row3(
        "Objavljaš na TikToku in si plačan.",
        "Postuješ na TikToku a dostaneš zaplatené.",
        "Објављујеш на TikTok-у и добијаш плаћено."),
    "ambassador.roles.title": row3(
        "Dva načina sodelovanja", "Dva spôsoby, ako sa zapojiť",
        "Два начина да учествујеш"),
    "ambassador.stat.income": row3("Zaslužek", "Príjem", "Зарада"),
    "ambassador.stat.time": row3("Čas", "Čas", "Време"),
    "ambassador.discover.cta": row3(
        "Prijavljam se", "Prihlasujem sa", "Пријављујем се"),
    "ambassador.intro": row3(
        "Pridruži se ambasadorskemu programu Sophia: objavljaš vsebino na TikToku. Mi damo objave, primere in mentorstvo. Ti objavljaš in si plačan.",
        "Pridaj sa k programu ambasádorov Sophia: postuješ obsah na TikToku. Dáme ti príspevky, príklady aj koučing. Ty publikuješ a dostaneš zaplatené.",
        "Придружи се Sophia амбасадорском програму: објављујеш садржај на TikTok-у. Ми дајемо објаве, примере и подршку. Ти објављујеш и добијаш плаћено."),
    "ambassador.cta48h": row3(
        "Oglasimo se v 48 urah. Pridruži se mreži!",
        "Ozveme sa do 48 hodín. Pridaj sa k sieti!",
        "Јављамо се у року од 48 сати. Придружи се мрежи!"),
    "ambassador.bonus": row3(
        "Bonus: brezplačni Sophia Premium med programom",
        "Bonus: Sophia Premium zadarmo počas programu",
        "Бонус: бесплатни Sophia Premium током програма"),
    "ambassador.role.slideshow.title": row3(
        "Ustvarjalec slideshowov", "Tvorca slideshow", "Аутор слајдшоуа"),
    "ambassador.role.slideshow.income": row3(
        "30-100 € / mes.", "30-100 € / mesiac", "30-100 € / мес."),
    "ambassador.role.slideshow.time": row3(
        "1-2 h / mes.", "1-2 h / mesiac", "1-2 č / мес."),
    "ambassador.role.slideshow.body": row3(
        "Damo ti TikTok slideshowe, pripravljene za objavo. Ti jih objaviš, mi te podpremo.",
        "Dáme ti TikTok slideshow pripravené na postnutie. Ty ich publikuješ, my ťa podržíme.",
        "Дајемо ти готове TikTok слајдшоуе. Ти их објављујеш, ми те подржавамо."),
    "ambassador.role.ugc.title": row3(
        "Ustvarjalec UGC", "Tvorca UGC", "UGC аутор"),
    "ambassador.role.ugc.income": row3(
        "50-1000 € / mes.", "50-1000 € / mesiac", "50-1000 € / мес."),
    "ambassador.role.ugc.time": row3(
        "2-10 h / mes.", "2-10 h / mesiac", "2-10 č / мес."),
    "ambassador.role.ugc.body": row3(
        "Ustvarjaš objave za TikTok. Zaslužek je odvisen od ogledov. Damo ti primere UGC in mentorstvo.",
        "Tvoríš príspevky na TikTok. Zárobok závisí od zhliadnutí. Dáme ti UGC príklady aj koučing.",
        "Правиш TikTok објаве. Зарада зависи од прегледа. Дајемо ти UGC примере и подршку."),
    "ambassador.conditions.title": row3("Pogoji", "Podmienky", "Услови"),
    "ambassador.conditions.countries": row3(
        "Živeti v Franciji, Kanadi, Belgiji ali Švici",
        "Žiť vo Francúzsku, Kanade, Belgicku alebo Švajčiarsku",
        "Живети у Француској, Канади, Белгији или Швајцарској"),
    "ambassador.conditions.age": row3(
        "Imeti 16 let ali več", "Mať 16 alebo viac rokov",
        "Имати 16 или више година"),
    "ambassador.form.title": row3("Prijava", "Prihláška", "Пријава"),
    "ambassador.form.roles.label": row3(
        "Prijavljaš se za", "Hlásiš sa na", "Пријављујеш се за"),
    "ambassador.form.role.slideshow": row3(
        "Ustvarjalec slideshowov", "Tvorca slideshow", "Аутор слајдшоуа"),
    "ambassador.form.role.ugc": row3(
        "Ustvarjalec UGC", "Tvorca UGC", "UGC аутор"),
    "ambassador.form.email.label": row3("E-pošta", "E-mail", "Имејл"),
    "ambassador.form.email.placeholder": row3(
        "ti@email.com", "ty@email.com", "ти@email.com"),
    "ambassador.form.age.label": row3("Starost", "Vek", "Године"),
    "ambassador.form.age.placeholder": row3("npr. 22", "napr. 22", "нпр. 22"),
    "ambassador.form.presentation.label": row3(
        "Na kratko o sebi", "Krátko o sebe", "Укратко о себи"),
    "ambassador.form.presentation.placeholder": row3(
        "Kaj rad počneš? Splošna razgledanost, ustvarjanje vsebin …",
        "Čo ťa baví? Všeobecný prehľad, tvorba obsahu…",
        "Шта волиш да радиш? Општа култура, прављење садржаја…"),
    "ambassador.form.presentation.hint": row3(
        "%d/%d znakov min.", "%d/%d znakov min.", "%d/%d знакова мин."),
    "ambassador.form.country.confirm": row3(
        "Potrjujem, da živim v Franciji, Kanadi, Belgiji ali Švici",
        "Potvrdzujem, že žijem vo Francúzsku, Kanade, Belgicku alebo Švajčiarsku",
        "Потврђујем да живим у Француској, Канади, Белгији или Швајцарској"),
    "ambassador.form.submit": row3(
        "Pošlji prijavo", "Odoslať prihlášku", "Пошаљи пријаву"),
    "ambassador.form.hint": row3(
        "Izpolni cel obrazec (o sebi: najmanj 10 znakov), da lahko pošlješ.",
        "Vyplň celý formulár (o sebe: min. 10 znakov), aby si mohol odoslať.",
        "Попуни цео образац (о себи: најмање 10 знакова) да би могао да пошаљеш."),
    "ambassador.form.error.generic": row3(
        "Trenutno ni mogoče poslati. Poskusi pozneje.",
        "Teraz sa to nedá odoslať. Skús to neskôr.",
        "Тренутно не може да се пошаље. Покушај касније."),
    "ambassador.form.error.age": row3(
        "Imeti moraš 16 let ali več.", "Musíš mať 16 alebo viac rokov.",
        "Мораш имати 16 или више година."),
    "ambassador.success.title": row3(
        "Prijava poslana!", "Prihláška odoslaná!", "Пријава послата!"),
    "ambassador.success.body": row3(
        "Hvala. Tvojo prijavo bomo pozorno prebrali.",
        "Ďakujeme. Tvoju prihlášku si pozorne prečítame.",
        "Хвала. Пажљиво ћемо прочитати твоју пријаву."),
    "ambassador.success.close": row3("Zapri", "Zavrieť", "Затвори"),
    "legal.terms.title": row3("Pogoji", "Podmienky", "Услови"),
    "legal.privacy.title": row3("Zasebnost", "Súkromie", "Приватност"),
    "subject.histoire": row3("Zgodovina", "Dejiny", "Историја"),
    "subject.sciences": row3("Znanost", "Veda", "Наука"),
    "subject.litterature": row3("Književnost", "Literatúra", "Књижевност"),
})

# --- subjects, home swipe, in-app explainers ------------------------------
STRINGS3.update({
    "subject.art": row3("Umetnost", "Umenie", "Уметност"),
    "subject.mythologie": row3("Mitologija", "Mytológia", "Митологија"),
    "subject.comprendreLeMonde": row3(
        "Razumeti današnji svet", "Pochopiť dnešný svet",
        "Разумети данашњи свет"),
    "subject.histoire.short": row3("Zgodovina", "Dejiny", "Историја"),
    "subject.sciences.short": row3("Znanost", "Veda", "Наука"),
    "subject.litterature.short": row3(
        "Književnost", "Literatúra", "Књижевност"),
    "subject.art.short": row3("Umetnost", "Umenie", "Уметност"),
    "subject.mythologie.short": row3("Mitologija", "Mytológia", "Митологија"),
    "subject.comprendreLeMonde.short": row3(
        "Današnji svet", "Dnešný svet", "Данашњи свет"),
    "home.skip": row3("Preskoči", "Preskočiť", "Прескочи"),
    "home.swipe.title": row3(
        "Podrsaj za menjavo tečaja", "Potiahni a zmeň kurz",
        "Превуци да промениш курс"),
    "home.swipe.subtitle": row3(
        "Podrsaj levo ali desno na naslednjega",
        "Potiahni doľava alebo doprava na ďalší",
        "Превуци лево или десно на следећи"),
    "course.reads": row3("%@ branj", "%@ prečítaní", "%@ читања"),
    "explain.tapToClose": row3(
        "Tapni za naprej", "Ťukni a pokračuj", "Додирни за наставак"),
    "explain.home.title": row3(
        "Navpično drsenje", "Zvislé potiahnutie", "Вертикално превлачење"),
    "explain.home.body": row3(
        "Podrsaj navzgor za naslednji tečaj, navzdol za prejšnjega.",
        "Potiahnutím nahor objavíš ďalší kurz, nadol sa vrátiš na predošlý.",
        "Превуци нагоре за следећи курс, надоле за претходни."),
    "explain.course.title": row3(
        "Tapni besede", "Klepni na slová", "Додирни речи"),
    "explain.course.body": row3(
        "Poudarjeni izrazi skrivajo razlago: tapni jih in vse razumeš.",
        "Zvýraznené výrazy skrývajú definíciu: klepni na ne a všetko pochopíš.",
        "Истакнути појмови крију дефиницију: додирни их да све разумеш."),
    "explain.course.termBody": row3(
        "Tako kot »%@« tudi podčrtane besede skrivajo razlago. Tapni jo, da se pokaže.",
        "Ako „%@“ aj podčiarknuté slová skrývajú definíciu. Klepni na ňu a uvidíš ju.",
        "Као и „%@“, подвучене речи крију дефиницију. Додирни да је видиш."),
    "explain.collections.title": row3("Zbirke", "Zbierky", "Збирке"),
    "explain.collections.body": row3(
        "Vsaka zbirka zbere tečaje iste teme, da napreduješ korak za korakom.",
        "Každá zbierka spája kurzy na rovnakú tému, aby si postupoval krok za krokom.",
        "Свака збирка окупља курсеве исте теме да напредујеш корак по корак."),
    "explain.training.title": row3(
        "Ponavljanje", "Opakovanie", "Понављање"),
    "explain.training.body": row3(
        "Ponavljaj že videna vprašanja ob pravem času, da ti ostanejo.",
        "Zopakuj si už videné otázky v pravý čas, aby ti zostali.",
        "Понављај већ виђена питања у правом тренутку да ти остану."),
    "home.swipe.left": row3("Podrsaj ←", "Potiahni ←", "Превуци ←"),
    "home.swipe.right": row3("→ Podrsaj", "→ Potiahni", "→ Превуци"),
    "home.bravo": row3("Bravo!", "Bravo!", "Браво!"),
    "home.allCompleted": row3(
        "Končal si vse razpoložljive tečaje.",
        "Dokončil si všetky dostupné kurzy.",
        "Прошао си све доступне курсеве."),
    "discount.gift.title": row3(
        "Presenečenje zate!", "Prekvapenie pre teba!", "Изненађење за тебе!"),
    "discount.gift.tapToOpen": row3(
        "Tapni, da ga odpreš", "Ťukni a otvor ho", "Додирни да отвориш"),
    "discount.gift.keepTapping": row3(
        "Tapkaj naprej!", "Ťukaj ďalej!", "Настави да додирујеш!"),
    "discount.gift.almost": row3("Skoraj!", "Skoro!", "Скоро!"),
    "home.locked": row3("Zaklenjeno", "Zamknuté", "Закључано"),
    "home.start": row3("Začni", "Začať", "Почни"),
})

# --- library chrome, collections, subject cards, filters ------------------
STRINGS3.update({
    "library.empty.title": row3(
        "Ni zadetkov", "Žiadne výsledky", "Нема резултата"),
    "library.empty.subtitle": row3(
        "Poskusi z drugo besedo.", "Skús iné kľúčové slovo.",
        "Пробај другу реч."),
    "library.seeMore": row3("Prikaži več", "Zobraziť viac", "Прикажи више"),
    "library.section.featured": row3("Izpostavljeno", "Odporúčané", "Издвојено"),
    "library.featured.badge": row3("Izpostavljeno", "Odporúčané", "Издвојено"),
    "collections.featured": row3("Izpostavljeno", "Odporúčané", "Издвојено"),
    "library.section.continue": row3(
        "Nadaljuj z učenjem", "Pokračuj v učení", "Настави да учиш"),
    "library.section.recommended": row3(
        "Priporočeno zate", "Odporúčané pre teba", "Препоручено за тебе"),
    "library.unlock": row3("Odkleni", "Odomknúť", "Откључај"),
    "library.lockedBadge": row3("ZAKLENJENO", "ZAMKNUTÉ", "ЗАКЉУЧАНО"),
    "collections.title": row3("ZBIRKE", "ZBIERKY", "ЗБИРКЕ"),
    "collections.subtitle": row3(
        "Vodene poti, ki povezujejo ideje.",
        "Vedené cesty, ktoré prepájajú myšlienky.",
        "Вођене путање које повезују идеје."),
    "collections.complete": row3(
        "Zbirka je končana", "Zbierka je dokončená", "Збирка је завршена"),
    "collections.progress": row3(
        "Končano: %d / %d", "Hotovo: %d / %d", "Завршено: %d / %d"),
    "collections.badge.complete": row3("KONČANA", "HOTOVO", "ЗАВРШЕНО"),
    "collections.badge.path": row3("POT", "CESTA", "ПУТАЊА"),
    "collections.xpAtEnd": row3(
        "+%d XP na koncu", "+%d XP na konci", "+%d XP на крају"),
    "collections.pathComplete": row3(
        "Pot je končana", "Cesta je dokončená", "Путања је завршена"),
    "collections.path": row3("Tvoja pot", "Tvoja cesta", "Твоја путања"),
    "collections.reward": row3(
        "Končna nagrada", "Záverečná odmena", "Коначна награда"),
    "subject.courses.count": row3(
        "%d tečajev", "%d kurzov", "%d курсева"),
    "subject.completed.singular": row3(
        "%d končan", "%d dokončený", "%d завршен"),
    "subject.completed.plural": row3(
        "%d končanih", "%d dokončených", "%d завршених"),
    "subject.level": row3("RAVEN %d", "ÚROVEŇ %d", "НИВО %d"),
    "subject.progress.stats": row3(
        "%d XP · %d/%d tečajev", "%d XP · %d/%d kurzov", "%d XP · %d/%d курсева"),
    "subject.next": row3("Naslednje", "Ďalej", "Следеће"),
    "subject.filter.empty": row3(
        "Tukaj še ni tečajev.", "Zatiaľ tu nie sú žiadne kurzy.",
        "Овде још нема курсева."),
    "library.filter.all": row3("Vse", "Všetko", "Све"),
    "library.filter.todo": row3("Za narediti", "Na urobenie", "За урадити"),
    "library.filter.inProgress": row3("V teku", "Prebieha", "У току"),
    "library.filter.done": row3("Končani", "Hotové", "Завршено"),
    "library.filter.favorites": row3("Priljubljeni", "Obľúbené", "Омиљено"),
    "library.status.done": row3("KONČANO", "HOTOVO", "ЗАВРШЕНО"),
    "library.status.inProgress": row3("V TEKU", "PREBIEHA", "У ТОКУ"),
})

# --- favorites, celebrations, common chrome, welcome rotator --------------
# The rotating words complete "… partner to master …", so Slovenian and Serbian
# take the genitive and Slovak the accusative; they are written to fit that
# frame, not as standalone nouns.
STRINGS3.update({
    "favorites.badge.count": row3(
        "%d TEČAJEV", "%d KURZOV", "%d КУРСЕВА"),
    "favorites.empty.title": row3(
        "Ni priljubljenih", "Žiadne obľúbené", "Нема омиљених"),
    "favorites.empty.subtitle": row3(
        "Tapni srce pri tečaju\nin našel ga boš tukaj.",
        "Klepni na srdce pri kurze\na nájdeš ho tu.",
        "Додирни срце на курсу\nи наћи ћеш га овде."),
    "course.funFact": row3("SI VEDEL?", "VEDEL SI?", "ЈЕСИ ЛИ ЗНАО?"),
    "paywall.error.unavailable": row3(
        "Ponudbe ni mogoče naložiti", "Ponuku sa nepodarilo načítať",
        "Није могуће учитати понуду"),
    "paywall.error.retry": row3("Poskusi znova", "Skús znova", "Покушај поново"),
    "cards.successRate": row3(
        "pravilnih odgovorov", "správnych odpovedí", "тачних одговора"),
    "cards.globalXP": row3("+%d XP skupaj", "+%d XP celkom", "+%d XP укупно"),
    "course.keyTakeaway": row3("ZAPOMNI SI", "ZAPAMÄTAJ SI", "ЗАПАМТИ"),
    "celebration.collectionAdvanced": row3(
        "Napredek v zbirki!", "Zbierka o krok ďalej!", "Напредак у збирци!"),
    "celebration.coursesCompleted": row3(
        "končanih tečajev", "dokončených kurzov", "завршених курсева"),
    "celebration.collectionComplete": row3(
        "Zbirka je končana!", "Zbierka je hotová!", "Збирка је завршена!"),
    "common.continue": row3("Naprej", "Pokračovať", "Настави"),
    "common.next": row3("Naslednje", "Ďalej", "Даље"),
    "common.letsGo": row3("Gremo!", "Ideme na to!", "Идемо!"),
    "common.letsGoShort": row3("Gremo", "Ideme na to", "Идемо"),
    "common.close": row3("Zapri", "Zavrieť", "Затвори"),
    "common.processing": row3("Trenutek…", "Moment…", "Тренутак…"),
    "common.startLearning": row3(
        "Začni se učiti", "Začni sa učiť", "Почни да учиш"),
    "common.backHome": row3(
        "Nazaj na domov", "Späť na začiatok", "Назад на почетну"),
    "common.retryQuiz": row3(
        "Ponovi kviz", "Skúsiť kvíz znova", "Понови квиз"),
    "common.seeMoreArrow": row3(
        "Prikaži več →", "Zobraziť viac →", "Прикажи више →"),
    "common.streak.day": row3("DAN", "DEŇ", "ДАН"),
    "common.streak.days": row3("DNI", "DNI", "ДАНА"),
    "common.levelShort": row3("RAV. %d", "ÚR. %d", "НИВО %d"),
    "common.increaseGoal": row3("Zvišaj cilj", "Zvýšiť cieľ", "Повећај циљ"),
    "common.decreaseGoal": row3("Znižaj cilj", "Znížiť cieľ", "Смањи циљ"),
    "common.miniQuiz": row3("Mini kviz", "Mini kvíz", "Мини квиз"),
    "common.xpEarned": row3("+%d XP", "+%d XP", "+%d XP"),
    "common.xpBeforeNext": row3(
        "· %d do rav. %d", "· %d do úr. %d", "· %d до нивоа %d"),
    "onboarding.welcome.title": row3(
        "Sophia je tvoj partner pri obvladovanju",
        "Sophia ti pomôže zvládnuť",
        "Sophia је твој партнер за савладавање"),
    "onboarding.welcome.rotating.histoire": row3(
        "zgodovine", "dejiny", "историје"),
    "onboarding.welcome.rotating.sciences": row3(
        "znanosti", "vedu", "науке"),
    "onboarding.welcome.rotating.litterature": row3(
        "književnosti", "literatúru", "књижевности"),
    "onboarding.welcome.rotating.art": row3(
        "umetnosti", "umenie", "уметности"),
    "onboarding.welcome.rotating.mythologie": row3(
        "mitologije", "mytológiu", "митологије"),
    "onboarding.welcome.rotating.comprendreLeMonde": row3(
        "današnjega sveta", "dnešný svet", "данашњег света"),
})

# --- onboarding v1: phone time, wasted time, goals, interests -------------
STRINGS3.update({
    "onboarding.phone.title": row3(
        "Koliko časa\npreživiš na telefonu?",
        "Koľko času\ntráviš na telefóne?",
        "Колико времена\nпроводиш на телефону?"),
    "onboarding.phone.subtitle": row3(
        "V povprečju, vsak dan.", "V priemere, každý deň.",
        "У просеку, сваког дана."),
    "onboarding.phone.intensity.light": row3("Malo", "Málo", "Мало"),
    "onboarding.phone.intensity.moderate": row3(
        "Zmerno", "Stredne", "Умерено"),
    "onboarding.phone.intensity.high": row3("Veliko", "Veľa", "Много"),
    "onboarding.phone.intensity.intense": row3(
        "Zelo veliko", "Veľmi veľa", "Веома много"),
    "onboarding.phone.lessThan1h": row3(
        "Manj kot 1 h", "Menej než 1 h", "Мање од 1 ч"),
    "onboarding.phone.1to2h": row3("1–2 h", "1–2 h", "1–2 ч"),
    "onboarding.phone.2to4h": row3("2–4 h", "2–4 h", "2–4 ч"),
    "onboarding.phone.moreThan4h": row3(
        "Več kot 4 h", "Viac než 4 h", "Више од 4 ч"),
    "onboarding.phone.hours.1": row3("1 ura", "1 hodina", "1 сат"),
    "onboarding.phone.hours.2": row3("2 uri", "2 hodiny", "2 сата"),
    "onboarding.phone.hours.3": row3("3 ure", "3 hodiny", "3 сата"),
    "onboarding.phone.hours.5": row3("5 ur", "5 hodín", "5 сати"),
    "onboarding.wasted.intro": row3(
        "%@ na dan na telefonu — to je",
        "%@ denne na telefóne — to je",
        "%@ дневно на телефону — то је"),
    "onboarding.wasted.hoursLost": row3(
        "izgubljenih ur na leto.", "stratených hodín za rok.",
        "изгубљених сати годишње."),
    "onboarding.wasted.daysComplete": row3(
        "To je %@ brez prekinitve.", "To je %@ bez prestávky.",
        "То је %@ без прекида."),
    "onboarding.wasted.transform": row3(
        "S Sophio ta čas postane znanje.",
        "So Sophiou sa ten čas zmení na vedomosti.",
        "Уз Sophia то време постаје знање."),
    "onboarding.wasted.days.7": row3("7 dni", "7 dní", "7 дана"),
    "onboarding.wasted.days.23": row3("23 dni", "23 dní", "23 дана"),
    "onboarding.wasted.days.45": row3("45 dni", "45 dní", "45 дана"),
    "onboarding.wasted.days.91": row3("91 dni", "91 dní", "91 дан"),
    "onboarding.objectives.title": row3(
        "Tvoj cilj\ns Sophio?", "Tvoj cieľ\nso Sophiou?", "Твој циљ\nуз Sophia?"),
    "onboarding.objectives.subtitle": row3(
        "Izberi enega ali več ciljev.", "Vyber jeden alebo viac cieľov.",
        "Изабери један или више циљева."),
    "onboarding.objective.curious": row3(
        "Biti bolj radoveden", "Byť zvedavejší", "Бити радозналији"),
    "onboarding.objective.learnNew": row3(
        "Učiti se nove stvari", "Učiť sa nové veci", "Учити нове ствари"),
    "onboarding.objective.impress": row3(
        "Navdušiti ljudi okoli sebe", "Ohromiť ľudí okolo seba",
        "Импресионирати људе око себе"),
    "onboarding.objective.social": row3(
        "Se počutiti sproščeno med ljudmi", "Cítiť sa istejšie medzi ľuďmi",
        "Сигурније се сналазити у друштву"),
    "onboarding.objective.reduceScroll": row3(
        "Manj drsati po zaslonu", "Menej scrollovať", "Мање скроловати"),
    "onboarding.interests.title": row3(
        "Katere teme\nte zanimajo?", "Aké témy\nťa zaujímajú?",
        "Које теме\nте занимају?"),
    "onboarding.interests.subtitle": row3(
        "Izberi vsaj eno temo.", "Vyber aspoň jednu tému.",
        "Изабери бар једну тему."),
    "onboarding.dailyGoal.title": row3(
        "Vsak dan se želiš naučiti…", "Každý deň sa chceš naučiť…",
        "Сваког дана желиш да одрадиш…"),
    "onboarding.dailyGoal.subtitle": row3(
        "Cilj lahko spremeniš pozneje.", "Cieľ si môžeš neskôr zmeniť.",
        "Циљ можеш променити касније."),
    "onboarding.dailyGoal.perDay": row3(
        "%@ na dan!", "%@ za deň!", "%@ дневно!"),
    "onboarding.dailyGoal.singular": row3("lekcija", "lekcia", "лекција"),
    "onboarding.dailyGoal.plural": row3("lekcije", "lekcie", "лекције"),
})

# --- onboarding v1: loading, program card, projection, showcase -----------
STRINGS3.update({
    "onboarding.loading.title": row3(
        "Pripravljamo tvojo pot", "Pripravujeme tvoju cestu",
        "Припремамо твој пут"),
    "onboarding.loading.subtitle": row3(
        "Le nekaj sekund, obljubimo.", "Len pár sekúnd, sľubujeme.",
        "Само пар секунди, обећавамо."),
    "onboarding.loading.step1": row3(
        "Analiziramo tvoje odgovore", "Analyzujeme tvoje odpovede",
        "Анализирамо твоје одговоре"),
    "onboarding.loading.step2": row3(
        "Izbiramo tvoje 3 predmete", "Vyberáme tvoje 3 predmety",
        "Бирамо твоја 3 предмета"),
    "onboarding.loading.step3": row3(
        "Pripravljamo tvojo pot", "Pripravujeme tvoju cestu",
        "Припремамо твој пут"),
    "onboarding.program.badge": row3(
        "Osebni program", "Osobný program", "Лични програм"),
    "onboarding.program.title": row3(
        "Tukaj je tvoj program", "Tu je tvoj program", "Ево твог програма"),
    "onboarding.program.profileLabel": row3(
        "TVOJ PROFIL", "TVOJ PROFIL", "ТВОЈ ПРОФИЛ"),
    "onboarding.program.nickname.default": row3(
        "Neutrudno radoveden", "Neúnavne zvedavý", "Неуморно радознао"),
    "onboarding.program.nickname.histoire": row3(
        "Navdušenec nad zgodovino", "Nadšenec do dejín", "Заљубљеник у историју"),
    "onboarding.program.nickname.sciences": row3(
        "Raziskovalec znanosti", "Vedecký prieskumník", "Истраживач науке"),
    "onboarding.program.nickname.litterature": row3(
        "Ljubitelj književnosti", "Milovník literatúry", "Љубитељ књижевности"),
    "onboarding.program.nickname.art": row3(
        "Navdušenec nad umetnostjo", "Nadšenec do umenia",
        "Заљубљеник у уметност"),
    "onboarding.program.nickname.mythologie": row3(
        "Raziskovalec mitologije", "Zvedavý na mytológiu", "Истраживач митологије"),
    "onboarding.program.nickname.comprendreLeMonde": row3(
        "Opazovalec sveta", "Pozorovateľ sveta", "Посматрач света"),
    "onboarding.program.dailyGoal": row3("%d %@", "%d %@", "%d %@"),
    "onboarding.program.dailyGoalCaption": row3(
        "Dnevni cilj", "Denný cieľ", "Дневни циљ"),
    "onboarding.program.hoursSaved": row3("%d h", "%d h", "%d ч"),
    "onboarding.program.hoursUnit": row3("h/leto", "h/rok", "ч/год."),
    "onboarding.program.hoursSavedCaption": row3(
        "prihranjenega časa", "ušetreného času", "уштеђеног времена"),
    "onboarding.program.topPick": row3(
        "Naš favorit", "Náš favorit", "Наш фаворит"),
    "onboarding.program.coursesTitle": row3(
        "Tečaji, ki ti najbolj ustrezajo",
        "Kurzy, ktoré ti sadnú najviac",
        "Курсеви који ти највише одговарају"),
    "onboarding.projection.line1": row3(
        "Majhna navada,", "Malý zvyk,", "Мала навика —"),
    "onboarding.projection.line2": row3(
        "ogromni rezultati.", "obrovské výsledky.", "огроман резултат."),
    "onboarding.projection.its": row3("To je", "To je", "То је"),
    "onboarding.projection.newThings": row3(
        "novih stvari, ki jih boš znal",
        "nových vecí, ktoré budeš vedieť",
        "нових ствари које ћеш знати"),
    "onboarding.projection.inOneYear": row3(
        "že čez leto dni.", "už o rok.", "већ за годину дана."),
    "onboarding.showcase.courses.title": row3(
        "Odkrij kratke\nin jasne tečaje",
        "Objav krátke,\nzrozumiteľné kurzy",
        "Откриј кратке\nи јасне курсеве"),
    "onboarding.showcase.courses.swipe": row3(
        "PODRSAJ ZA ODKRIVANJE", "POTIAHNI A OBJAVUJ", "ПРЕВУЦИ ЗА ОТКРИВАЊЕ"),
    "onboarding.showcase.courses.lessons": row3(
        "%d lekcij", "%d lekcií", "%d лекција"),
    "onboarding.showcase.courses.quizCount": row3(
        "%d kvizov", "%d kvízov", "%d квизова"),
    "onboarding.showcase.quiz.title": row3(
        "Napreduj\nob kvizih", "Zlepši sa\ns kvízmi", "Напредуј\nуз квизове"),
    "onboarding.showcase.quiz.question": row3(
        "Kaj ne more uiti iz črne luknje?",
        "Čo nemôže uniknúť z čiernej diery?",
        "Шта не може да побегне из црне рупе?"),
    "onboarding.showcase.quiz.option.0": row3("Zvok", "Zvuk", "Звук"),
    "onboarding.showcase.quiz.option.1": row3("Svetloba", "Svetlo", "Светлост"),
    "onboarding.showcase.quiz.option.2": row3("Toplota", "Teplo", "Топлота"),
    "onboarding.showcase.quiz.option.3": row3("Čas", "Čas", "Време"),
    "onboarding.showcase.collections.title": row3(
        "Sledi tematskim\npotem", "Sleduj tematické\ncesty",
        "Прати тематске\nпутање"),
})

# --- onboarding v1: XP showcase, growth graph, final, trial timeline ------
STRINGS3.update({
    "onboarding.showcase.xp.title": row3(
        "Rasti po ravneh\nin se povzpni na lestvici\nnajbolj razgledanih",
        "Rasti v úrovniach\na vyšvihni sa medzi\nnajrozhľadenejších",
        "Расти кроз нивое\nи пењи се на листи\nнајобразованијих"),
    "onboarding.showcase.xp.level": row3("RAVEN", "ÚROVEŇ", "НИВО"),
    "onboarding.graph.title": row3(
        "Tako raste\ntvoje znanje", "Takto rastie\ntvoje vedomie",
        "Овако расте\nтвоје знање"),
    "onboarding.graph.subtitle": row3(
        "S Sophio in brez nje", "So Sophiou a bez nej", "Уз Sophia и без ње"),
    "onboarding.graph.culture": row3("ZNANJE", "VEDOMOSTI", "ЗНАЊЕ"),
    "onboarding.graph.withSophia": row3(
        "S Sophio", "So Sophiou", "Уз Sophia"),
    "onboarding.graph.withoutSophia": row3(
        "Brez Sophie", "Bez Sophie", "Без Sophia"),
    "onboarding.graph.today": row3("Danes", "Dnes", "Данас"),
    "onboarding.graph.oneYear": row3("1 leto", "1 rok", "1 година"),
    "onboarding.graph.tagline": row3(
        "S Sophio tvoje znanje raste\neksponentno.",
        "So Sophiou tvoje vedomosti rastú\nexponenciálne.",
        "Уз Sophia твоје знање расте\nекспоненцијално."),
    "onboarding.final.title": row3(
        "Profil je pripravljen!", "Profil je pripravený!", "Профил је спреман!"),
    "onboarding.final.subtitle": row3(
        "Dobrodošel v Sophii.\nZačni se učiti takoj.",
        "Vitaj v Sophii.\nZačni sa učiť hneď teraz.",
        "Добро дошао у Sophia.\nКрени да учиш одмах."),
    "onboarding.final.subjects": row3(
        "TVOJI PREDMETI", "TVOJE PREDMETY", "ТВОЈИ ПРЕДМЕТИ"),
    "onboarding.trial.badge": row3(
        "Uvodna ponudba", "Uvítacia ponuka", "Уводна понуда"),
    "onboarding.trial.title": row3(
        "Prve 3 dni\nimaš brezplačno", "Prvé 3 dni\nmáš zadarmo",
        "Прва 3 дана\nсу бесплатна"),
    "onboarding.trial.unlimitedCourses": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Неограничени курсеви"),
    "onboarding.trial.allQuizzes": row3(
        "Vsi kvizi", "Všetky kvízy", "Сви квизови"),
    "onboarding.trial.noSurprise": row3(
        "Brez presenečenj", "Žiadne prekvapenia", "Без изненађења"),
    "onboarding.trial.notifyTitle": row3(
        "Sporočili ti bomo\n1 dan pred koncem\nbrezplačnega obdobja",
        "Dáme ti vedieť\n1 deň pred koncom\nskúšobného obdobia",
        "Јавићемо ти\n1 дан пре краја\nбесплатног периода"),
    "onboarding.trial.cancelAnytime": row3(
        "Odpoveš kadar koli, brez stroškov.",
        "Zruš kedykoľvek, zadarmo.",
        "Откажи кад год желиш, без наплате."),
    "onboarding.trial.day1": row3("DAN 1", "DEŇ 1", "ДАН 1"),
    "onboarding.trial.day2": row3("DAN 2", "DEŇ 2", "ДАН 2"),
    "onboarding.trial.day3": row3("DAN 3", "DEŇ 3", "ДАН 3"),
    "onboarding.trial.fullAccess": row3(
        "Poln dostop", "Plný prístup", "Потпун приступ"),
    "onboarding.trial.notificationSent": row3(
        "Obvestilo poslano", "Oznámenie odoslané", "Обавештење послато"),
    "onboarding.trial.trialEnds": row3(
        "Konec preizkusa", "Koniec skúšobného obdobia", "Крај пробног периода"),
    "onboarding.premiumGift.badge": row3(
        "Darilo zate", "Darček pre teba", "Поклон за тебе"),
    "onboarding.premiumGift.title": row3(
        "Podarimo ti\nSophia Premium", "Dávame ti\nSophia Premium",
        "Поклањамо ти\nSophia Premium"),
    "onboarding.premiumTrial.badge": row3(
        "Brezplačni preizkus", "Bezplatná skúška", "Бесплатна проба"),
    "onboarding.premiumTrial.title": row3(
        "Tvoj brezplačni preizkus\nv 3 korakih",
        "Tvoja bezplatná skúška\nv 3 krokoch",
        "Твоја бесплатна проба\nу 3 корака"),
    "onboarding.premiumTrial.step1.label": row3("ZDAJ", "TERAZ", "САДА"),
    "onboarding.premiumTrial.step1.title": row3(
        "Premium je aktiviran", "Premium je aktivovaný", "Premium је активиран"),
    "onboarding.premiumTrial.step2.label": row3("DAN 1", "DEŇ 1", "ДАН 1"),
    "onboarding.premiumTrial.step2.title": row3(
        "Opomnik pred koncem", "Pripomienka pred koncom", "Подсетник пред крај"),
    "onboarding.premiumTrial.step3.label": row3("DAN 2", "DEŇ 2", "ДАН 2"),
    "onboarding.premiumTrial.step3.title": row3(
        "Obdržiš ali odpoveš", "Necháš si to, alebo zrušíš",
        "Задржиш или откажеш"),
    "onboarding.premiumTrial.cancelAnytime": row3(
        "Brez obveznosti", "Žiadny záväzok", "Без обавеза"),
    "onboarding.premiumTrial.cta": row3(
        "Zaženi preizkus", "Spustiť skúšku", "Покрени пробу"),
})

# --- paywall: headlines, benefits, comparison table, plans ----------------
# `*.highlight` values MUST stay exact substrings of their headline, so the
# headlines are worded around the highlighted word rather than the reverse.
STRINGS3.update({
    "paywall.cancelAnytime": row3(
        "Odpoveš kadar koli, brez stroškov.",
        "Zruš kedykoľvek, zadarmo.",
        "Откажи кад год желиш, без наплате."),
    "paywall.header": row3(
        "Postani\nnajzanimivejša oseba\nv prostoru.",
        "Staň sa\nnajzaujímavejšou osobou\nv miestnosti.",
        "Постани\nнајзанимљивија\nособа у просторији."),
    "paywall.header.highlight": row3(
        "najzanimivejša", "najzaujímavejšou", "најзанимљивија"),
    "paywall.weaponHeadline": row3(
        "Sophia, tvoje tajno\norožje za:",
        "Sophia, tvoja tajná\nzbraň na:",
        "Sophia, твоје тајно\nоружје за:"),
    "paywall.weaponHeadline.highlight": row3("tajno", "tajná", "тајно"),
    "paywall.benefit.conversations": row3(
        "💬 Boljši pogovori", "💬 Lepšie rozhovory", "💬 Бољи разговори"),
    "paywall.benefit.curiosity": row3(
        "💡 Več radovednosti", "💡 Viac zvedavosti", "💡 Више радозналости"),
    "paywall.benefit.confidence": row3(
        "🔥 Več samozavesti", "🔥 Viac sebavedomia", "🔥 Више самопоуздања"),
    "paywall.benefit.screenTime": row3(
        "📱 Koristnejši čas pred zaslonom",
        "📱 Čas pri telefóne, ktorý za to stojí",
        "📱 Корисније време пред екраном"),
    "paywall.premiumHeadline": row3(
        "Odkleni Premium za 3 dni\nBREZPLAČNO",
        "Odomkni Premium na 3 dni\nZADARMO",
        "Откључај Premium на 3 дана\nБЕСПЛАТНО"),
    "paywall.premiumHeadline.highlight": row3(
        "BREZPLAČNO", "ZADARMO", "БЕСПЛАТНО"),
    "paywall.freeSubjects": row3(
        "Tvoji 3 brezplačni predmeti", "Tvoje 3 predmety zadarmo",
        "Твоја 3 бесплатна предмета"),
    "paywall.lockedSubjects": row3(
        "3 zaklenjeni predmeti", "3 zamknuté predmety", "3 закључана предмета"),
    "paywall.lockedSubjectsWithPremium": row3(
        "3 predmete odkleneš s Premium",
        "3 predmety odomkneš s Premium",
        "3 предмета откључаваш уз Premium"),
    "paywall.teaserTitle": row3(
        "Pokukaj, kaj te čaka", "Ochutnávka toho, čo ťa čaká",
        "Завири шта те чека"),
    "paywall.teaserSubtitle": row3(
        "Na stotine tečajev Premium čaka, da jih odkleneš",
        "Stovky prémiových kurzov čaká na odomknutie",
        "Стотине premium курсева чека откључавање"),
    "paywall.featureColumn": row3("Funkcije", "Funkcie", "Могућности"),
    "paywall.freeColumn": row3("Brezplačno", "Zadarmo", "Бесплатно"),
    "paywall.premiumColumn": row3("Premium", "Premium", "Premium"),
    "paywall.feature.3subjects": row3(
        "3 predmeti", "3 predmety", "3 предмета"),
    "paywall.feature.allSubjects": row3(
        "Vsi predmeti", "Všetky predmety", "Сви предмети"),
    "paywall.feature.unlimitedCourses": row3(
        "Neomejeni tečaji", "Neobmedzené kurzy", "Курсеви без лимита"),
    "paywall.feature.miniQuiz": row3("Mini kvizi", "Mini kvízy", "Мини квизови"),
    "paywall.feature.fullLibrary": row3(
        "Cela knjižnica", "Celá knižnica", "Цела библиотека"),
    "paywall.plan.yearly": row3("Letno", "Ročne", "Годишње"),
    "paywall.plan.monthly": row3("Mesečno", "Mesačne", "Месечно"),
    "paywall.plan.yearlySubtitle": row3(
        "Zaračunano enkrat letno", "Účtované raz ročne",
        "Наплата једном годишње"),
    "paywall.plan.monthlySubtitle": row3(
        "Brez obveznosti", "Žiadny záväzok", "Без обавеза"),
    "paywall.plan.perYear": row3("/ leto", "/ rok", "/ год."),
    "paywall.plan.perMonth": row3("/ mes.", "/ mes.", "/ мес."),
    "paywall.plan.discount": row3("-58%", "-58%", "-58%"),
    "paywall.plan.fallback.yearlyPrice": row3("$34.99", "$34.99", "$34.99"),
    "paywall.plan.fallback.monthlyPrice": row3("$8.99", "$8.99", "$8.99"),
    "paywall.plan.fallback.yearlyMonthly": row3(
        "2,92 $ / mesec", "2,92 $ / mesiac", "2,92 $ / мес."),
    "paywall.trialBadge": row3(
        "3 dni brezplačno", "3 dni zadarmo", "3 дана бесплатно"),
    "paywall.restoreRow": row3(
        "Obnovi · Pogoji · Zasebnost",
        "Obnoviť · Podmienky · Súkromie",
        "Врати · Услови · Приватност"),
    "paywall.restore": row3("Obnovi", "Obnoviť", "Врати"),
    "paywall.quiz.title": row3(
        "Odkleni kviz", "Odomkni kvíz", "Откључај квиз"),
    "paywall.quiz.subtitle": row3(
        "Preveri se in utrdi, kar si se pravkar naučil, s kvizom tega tečaja.",
        "Otestuj sa a upevni si, čo si sa práve naučil, kvízom tohto kurzu.",
        "Провери се и учврсти оно што си управо научио квизом овог курса."),
})

# --- paywall: FAQ, daily-course gate, reviews, CTAs -----------------------
STRINGS3.update({
    "paywall.quiz.faq.q1": row3(
        "Je naročnino lahko preprosto odpovem?",
        "Dá sa predplatné ľahko zrušiť?",
        "Да ли је претплату лако отказати?"),
    "paywall.quiz.faq.a1": row3(
        "Da. Pojdi v App Store → svoj račun → Naročnine → Sophia → Prekliči. Opravljeno v nekaj tapih.",
        "Áno. Choď do App Store → svoj účet → Predplatné → Sophia → Zrušiť. Hotovo na pár ťuknutí.",
        "Да. Иди у App Store → свој налог → Претплате → Sophia → Откажи. Готово у пар додира."),
    "paywall.quiz.faq.q2": row3(
        "Ali Sophia Pro odpre Sophia Ponavljanje?",
        "Patrí k Sophia Pro aj Sophia Opakovanie?",
        "Да ли Sophia Pro откључава Sophia Понављање?"),
    "paywall.quiz.faq.a2": row3(
        "Da. Sophia Pro odklene tudi Sophia Ponavljanje: aktivni priklic vrne vprašanja ob pravem času, da naučeno ostane.",
        "Áno. Sophia Pro odomkne aj Sophia Opakovanie: aktívne vybavovanie vracia otázky v pravý čas, aby ti učivo zostalo.",
        "Да. Sophia Pro откључава и Sophia Понављање: активно присећање враћа питања у правом тренутку да научено остане."),
    "paywall.quiz.faq.q3": row3(
        "Lahko naročnino odpovem kadar koli?",
        "Môžem predplatné zrušiť kedykoľvek?",
        "Могу ли да откажем претплату кад год желим?"),
    "paywall.quiz.faq.a3": row3(
        "Da — pred koncem brezplačnega obdobja in kadar koli pozneje. Brezplačno obdobje je tu zato, da spoznaš aplikacijo in vse, kar ponuja.",
        "Áno — pred koncom bezplatného obdobia aj kedykoľvek potom. Bezplatné obdobie je tu na to, aby si spoznal aplikáciu a všetko, čo ponúka.",
        "Да — пре краја бесплатног периода и било када после. Бесплатни период ту је да упознаш апликацију и све што нуди."),
    "paywall.quiz.faq.q3.noTrial": row3(
        "Se vežem za določeno obdobje?",
        "Zaväzujem sa na nejaké obdobie?",
        "Везујем ли се на неки период?"),
    "paywall.quiz.faq.a3.noTrial": row3(
        "Ne. Brez obveznosti: odpoveš kadar koli v App Storu in dostop obdržiš do konca že plačanega obdobja.",
        "Nie. Žiadny záväzok: zruš kedykoľvek v App Store a prístup si udržíš do konca už zaplateného obdobia.",
        "Не. Без обавеза: откажи кад год желиш у App Store-у и задржаваш приступ до краја већ плаћеног периода."),
    "paywall.course.title": row3(
        "Današnji brezplačni tečaj si že prebral",
        "Dnešný kurz zadarmo už máš prečítaný",
        "Већ си прочитао данашњи бесплатни курс"),
    "paywall.course.subtitle": row3(
        "Današnji brezplačni tečaj si porabil. Vrni se jutri ali odkleni vse takoj.",
        "Dnešný bezplatný kurz už máš za sebou. Vráť sa zajtra, alebo odomkni všetko hneď.",
        "Искористио си данашњи бесплатни курс. Врати се сутра или откључај све одмах."),
    "paywall.course.subtitle.named": row3(
        "Današnji brezplačni tečaj si porabil. Odkleni »%@« in vse tečaje takoj ali se vrni jutri.",
        "Dnešný bezplatný kurz už máš za sebou. Odomkni „%@“ a všetky kurzy hneď, alebo sa vráť zajtra.",
        "Искористио си данашњи бесплатни курс. Откључај „%@“ и све курсеве одмах или се врати сутра."),
    "paywall.course.comeBack": row3(
        "Naslednji brezplačni tečaj čez", "Ďalší bezplatný kurz o",
        "Следећи бесплатни курс за"),
    "paywall.course.stat.value": row3("6", "6", "6"),
    "paywall.course.stat.label": row3(
        "tečajev / dan", "kurzov / deň", "курсева / дан"),
    "paywall.course.stat.caption": row3(
        "v povprečju preberejo člani Sophia Premium",
        "v priemere prečítajú členovia Sophia Premium",
        "у просеку прочитају чланови Sophia Premium"),
    "paywall.rating": row3("na App Storu", "na App Store", "на App Store-у"),
    "paywall.reviews.r1.quote": row3(
        "Tečaj pogoltnem takoj, ko imam 5 minut. Še nikoli se nisem toliko naučil.",
        "Zhltnem kurz vždy, keď mám 5 minút. Nikdy som sa toľko nenaučil.",
        "Прогутам курс чим имам 5 минута. Никад нисам толико научио."),
    "paywall.reviews.r1.author": row3(
        "Camille, 22 let", "Camille, 22 rokov", "Камиј, 22 године"),
    "paywall.reviews.r2.quote": row3(
        "Naročnina se mi je povrnila v enem tednu. Preberem več tečajev na dan.",
        "Predplatné sa mi vrátilo za týždeň. Prečítam niekoľko kurzov denne.",
        "Претплата ми се исплатила за недељу дана. Читам више курсева дневно."),
    "paywall.reviews.r2.author": row3(
        "Thomas, 29 let", "Thomas, 29 rokov", "Тома, 29 година"),
    "paywall.reviews.r3.quote": row3(
        "Vsak teden se počutim bolj razgledanega. Težko se ustavim pri enem samem tečaju.",
        "Každý týždeň sa cítim rozhľadenejší. Ťažko sa zastaviť pri jedinom kurze.",
        "Сваке недеље се осећам образованије. Тешко је стати на једном курсу."),
    "paywall.reviews.r3.author": row3(
        "Inès, 25 let", "Inès, 25 rokov", "Инес, 25 година"),
    "paywall.benefit.unlimited": row3(
        "Neomejeni tečaji, vsak dan", "Neobmedzené kurzy, každý deň",
        "Курсеви без лимита, сваког дана"),
    "paywall.benefit.quiz": row3(
        "Vsi kvizi, da ti ostane", "Všetky kvízy, nech ti to zostane",
        "Сви квизови за боље памћење"),
    "paywall.benefit.allSubjects": row3(
        "Vse teme, brez oglasov", "Všetky témy, bez reklám",
        "Све теме, без реклама"),
    "paywall.cta.unlockFree": row3(
        "Odkleni brezplačno", "Odomknúť zadarmo", "Откључај бесплатно"),
    "paywall.cta.subscribe": row3(
        "Naroči se zdaj", "Predplatiť si teraz", "Претплати се сада"),
    "paywall.cta.activateTrial": row3(
        "Aktiviraj brezplačni preizkus", "Aktivovať bezplatnú skúšku",
        "Активирај бесплатну пробу"),
    "paywall.price.trialThenYearly": row3(
        "3 dni brezplačno, nato %@ / leto (%@)",
        "3 dni zadarmo, potom %@ / rok (%@)",
        "3 дана бесплатно, затим %@ / год. (%@)"),
    "paywall.price.yearlyNoTrial": row3(
        "%@ / leto (%@) · Odpoveš kadar koli",
        "%@ / rok (%@) · Zrušíš kedykoľvek",
        "%@ / год. (%@) · Откажеш кад год желиш"),
})

# --- paywall: practice pitch, quiz demo ------------------------------------
STRINGS3.update({
    "paywall.training.title": row3(
        "Naj naučeno ostane za vedno", "Nech ti naučené zostane navždy",
        "Нека научено остане заувек"),
    "paywall.training.subtitle": row3(
        "Ponavljanje ti vrne vprašanja iz kvizov v popolnem trenutku — tik preden jih možgani pozabijo.",
        "Opakovanie ti vráti otázky z kvízov v dokonalej chvíli — tesne predtým, než ich mozog pustí.",
        "Понављање враћа питања из квизова у савршеном тренутку — тачно пре него што их мозак заборави."),
    "paywall.training.stat1.value": row3("+200 %", "+200 %", "+200 %"),
    "paywall.training.stat1.label": row3(
        "boljše pomnjenje z razmaknjenim ponavljanjem kot z golim ponovnim branjem",
        "lepšie zapamätanie s rozloženým opakovaním než s obyčajným opätovným čítaním",
        "боље памћење уз размакнуто понављање него уз пуко поновно читање"),
    "paywall.training.stat2.value": row3("90 %", "90 %", "90 %"),
    "paywall.training.stat2.label": row3(
        "naučenega pozabimo v enem tednu… brez ponavljanja",
        "z toho, čo sa naučíme, zabudneme do týždňa… bez opakovania",
        "наученог заборави се за недељу дана… без понављања"),
    "paywall.training.how.title": row3(
        "KAKO DELUJE", "AKO TO FUNGUJE", "КАКО ФУНКЦИОНИШЕ"),
    "paywall.training.how.step1": row3(
        "Dokončaj tečaj in njegov kviz", "Dokonči kurz a jeho kvíz",
        "Заврши курс и његов квиз"),
    "paywall.training.how.step2": row3(
        "Njegova vprašanja gredo v tvoje Ponavljanje",
        "Jeho otázky sa pridajú do tvojho Opakovania",
        "Његова питања улазе у твоје Понављање"),
    "paywall.training.how.step3": row3(
        "Ponavljaj ob pravem trenutku in nikoli več ne pozabiš",
        "Opakuj v tú správnu chvíľu, aby si už nikdy nezabudol",
        "Понављај у правом тренутку и више никад не заборавиш"),
    "paywall.training.footnote": row3(
        "Razmaknjeno ponavljanje je najbolje dokazana metoda, da znanje postane trajno.",
        "Rozložené opakovanie je najlepšie dokázaný spôsob, ako urobiť vedomosti trvalými.",
        "Размакнуто понављање најбоље је доказан начин да знање постане трајно."),
    "paywall.quiz.rating": row3(
        "na App Storu", "na App Store", "на App Store-у"),
    "paywall.quiz.demo.title": row3(
        "Preveri se po vsakem tečaju", "Otestuj sa po každom kurze",
        "Провери се после сваког курса"),
    "paywall.quiz.demo.badge.mcq": row3(
        "Izbor odgovora", "Výber odpovede", "Избор одговора"),
    "paywall.quiz.demo.badge.trueFalse": row3(
        "Prav / narobe", "Pravda / nepravda", "Тачно / нетачно"),
    "paywall.quiz.demo.badge.slider": row3("Ocena", "Odhad", "Процена"),
    "paywall.quiz.demo.badge.chrono": row3(
        "Časovnica", "Časová os", "Хронологија"),
    "paywall.quiz.demo.mcq.q": row3(
        "Kdo je naslikal Zvezdno noč?", "Kto namaľoval Hviezdnu noc?",
        "Ко је насликао Звездану ноћ?"),
    "paywall.quiz.demo.mcq.o1": row3("Van Gogh", "Van Gogh", "Ван Гог"),
    "paywall.quiz.demo.mcq.o2": row3("Monet", "Monet", "Моне"),
    "paywall.quiz.demo.mcq.o3": row3("Picasso", "Picasso", "Пикасо"),
    "paywall.quiz.demo.tf.q": row3(
        "Kitajski zid je viden z Lune.",
        "Veľký čínsky múr je vidno z Mesiaca.",
        "Кинески зид се види са Месеца."),
    "paywall.quiz.demo.tf.true": row3("Prav", "Pravda", "Тачно"),
    "paywall.quiz.demo.tf.false": row3("Narobe", "Nepravda", "Нетачно"),
    "paywall.quiz.demo.slider.q": row3(
        "Katerega leta se je začela francoska revolucija?",
        "V ktorom roku sa začala Francúzska revolúcia?",
        "Које године је почела Француска револуција?"),
    "paywall.quiz.demo.chrono.q": row3(
        "Razvrsti obdobja po času", "Zoraď obdobia chronologicky",
        "Поређај раздобља хронолошки"),
    "paywall.quiz.demo.chrono.i1": row3("Antika", "Starovek", "Антика"),
    "paywall.quiz.demo.chrono.i2": row3(
        "Srednji vek", "Stredovek", "Средњи век"),
    "paywall.quiz.demo.chrono.i3": row3(
        "Renesansa", "Renesancia", "Ренесанса"),
    "paywall.quiz.reviews.title": row3(
        "Napredujejo s Sophio", "Učia sa so Sophiou", "Напредују уз Sophia"),
    "paywall.quiz.review1.quote": row3(
        "Ob kvizih sem si zapomnil veliko več kot samo z branjem. 5 minut in ostane.",
        "Vďaka kvízom som si zapamätal oveľa viac než len čítaním. 5 minút a drží to.",
        "Уз квизове сам запамтио много више него само читањем. 5 минута и остаје."),
    "paywall.quiz.review1.author": row3(
        "Camille, 22 let", "Camille, 22 rokov", "Камиј, 22 године"),
    "paywall.quiz.review2.quote": row3(
        "Končno aplikacija, v kateri si res zapomnim, kar se naučim. Kvizi so zasvojljivi.",
        "Konečne aplikácia, kde si naozaj pamätám, čo sa naučím. Kvízy sú návykové.",
        "Коначно апликација у којој стварно памтим оно што учим. Квизови су заразни."),
})

# --- paywall: flash offer, trial timeline, review carousel ----------------
STRINGS3.update({
    "paywall.quiz.review2.author": row3(
        "Thomas, 29 let", "Thomas, 29 rokov", "Тома, 29 година"),
    "paywall.quiz.review3.quote": row3(
        "Vsak teden se počutim bolj razgledanega. Kvizi vse utrdijo.",
        "Každý týždeň sa cítim rozhľadenejší. Kvízy všetko ukotvia.",
        "Сваке недеље се осећам образованије. Квизови све учврсте."),
    "paywall.quiz.review3.author": row3(
        "Inès, 25 let", "Inès, 25 rokov", "Инес, 25 година"),
    "paywall.discount.endsIn": row3("Konča se čez", "Končí o", "Завршава се за"),
    "paywall.discount.title": row3(
        "Bliskovita ponudba, samo danes", "Bleskový výpredaj, iba dnes",
        "Муњевита понуда, само данас"),
    "paywall.discount.subtitle": row3(
        "Vse življenje znanja s Premium, po najnižji ceni doslej.",
        "Celý život vedomostí s Premium, za najnižšiu cenu, akú sme kedy dali.",
        "Цео живот знања уз Premium, по најнижој цени коју смо икад дали."),
    "paywall.discount.perYear": row3(
        "na leto, brez obveznosti", "ročne, bez záväzku", "годишње, без обавеза"),
    "paywall.discount.cta": row3(
        "Vzamem ponudbo", "Beriem to hneď", "Узимам понуду"),
    "paywall.discount.noTrial": row3(
        "Brez brezplačnega preizkusa · Odpoveš kadar koli",
        "Bez skúšobného obdobia · Zrušíš kedykoľvek",
        "Без пробног периода · Откажеш кад год желиш"),
    "paywall.discount.fallbackPrice": row3("$19.99", "$19.99", "$19.99"),
    "paywall.terms": row3("Pogoji", "Podmienky", "Услови"),
    "paywall.privacy": row3("Zasebnost", "Súkromie", "Приватност"),
    "paywall.trialSheet.title": row3(
        "Začni brezplačni\npreizkus za 3 dni",
        "Začni bezplatnú\nskúšku na 3 dni",
        "Покрени бесплатну\nпробу од 3 дана"),
    "paywall.trialSheet.start": row3(
        "Začni brezplačni preizkus", "Spustiť bezplatnú skúšku",
        "Покрени бесплатну пробу"),
    "paywall.trial.today": row3("Danes", "Dnes", "Данас"),
    "paywall.trial.noPayment": row3(
        "Brez plačila", "Žiadna platba", "Без плаћања"),
    "paywall.trial.todayDetail": row3(
        "Dostop do vseh funkcij Premium.",
        "Prístup ku všetkým funkciám Premium.",
        "Приступ свим Premium могућностима."),
    "paywall.trial.in2days": row3("Čez 2 dni", "O 2 dni", "За 2 дана"),
    "paywall.trial.reminder": row3(
        "Sporočimo ti", "Dáme ti vedieť", "Јавићемо ти"),
    "paywall.trial.reminderDetail": row3(
        "Obvestilo 1 dan pred koncem preizkusa.",
        "Oznámenie 1 deň pred koncom skúšky.",
        "Обавештење 1 дан пре краја пробе."),
    "paywall.trial.in3days": row3("Čez 3 dni", "O 3 dni", "За 3 дана"),
    "paywall.trial.starts": row3(
        "Tvoja naročnina se začne", "Tvoje predplatné sa začína",
        "Почиње твоја претплата"),
    "paywall.trial.startsDetail": row3(
        "Če ne želiš nadaljevati, odpovej prej.",
        "Ak nechceš pokračovať, zruš to vopred.",
        "Откажи раније ако не желиш да наставиш."),
    "paywall.review1.quote": row3(
        "Odlično na poti. Vsak dan se naučim nekaj brez truda.",
        "Ideálne cestou. Každý deň sa niečo naučím bez námahy.",
        "Савршено у превозу. Сваког дана научим нешто без напора."),
    "paywall.review1.author": row3(
        "Marie, 28 let", "Marie, 28 rokov", "Мари, 28 година"),
    "paywall.review2.quote": row3(
        "Končno aplikacija, ki drsanje po zaslonu spremeni v znanje.",
        "Konečne aplikácia, ktorá scrollovanie mení na vedomosti.",
        "Коначно апликација која скроловање претвара у знање."),
    "paywall.review2.author": row3(
        "Thomas, 34 let", "Thomas, 34 rokov", "Тома, 34 године"),
    "paywall.review3.quote": row3(
        "Tečaji so kratki, zabavni in res si jih zapomnim.",
        "Kurzy sú krátke, zábavné a naozaj si ich pamätám.",
        "Курсеви су кратки, забавни и стварно их памтим."),
    "paywall.review3.author": row3(
        "Inès, 22 let", "Inès, 22 rokov", "Инес, 22 године"),
    "paywall.review4.quote": row3(
        "Prijatelji me sprašujejo, od kod mi vse te zanimivosti.",
        "Kamaráti sa ma pýtajú, odkiaľ mám všetky tie historky.",
        "Пријатељи ме питају одакле ми све те занимљивости."),
    "paywall.review4.author": row3(
        "Lucas, 31 let", "Lucas, 31 rokov", "Лукас, 31 година"),
    "paywall.review5.quote": row3(
        "Osebni uvod me je prepričal že v prvi minuti.",
        "Osobný úvod ma presvedčil hneď v prvej minúte.",
        "Лични увод ме је убедио у првом минуту."),
    "paywall.review5.author": row3(
        "Sarah, 26 let", "Sarah, 26 rokov", "Сара, 26 година"),
})

# --- one-time offer, profile ----------------------------------------------
STRINGS3.update({
    "offer.unique": row3(
        "Tvoja enkratna ponudba", "Tvoja jednorazová ponuka",
        "Твоја јединствена понуда"),
    "offer.discount": row3(
        "-70 % ZA VEDNO", "-70 % NAVŽDY", "-70 % ЗАУВЕК"),
    "offer.perMonth": row3("/mes.", "/mes.", "/мес."),
    "offer.billed": row3("zaračunano", "účtované", "наплаћено"),
    "offer.expiresIn": row3("Poteče čez", "Platnosť vyprší o", "Истиче за"),
    "offer.unlock": row3(
        "Odkleni mojih -70 %", "Odomknúť mojich -70 %", "Откључај мојих -70 %"),
    "offer.restore": row3(
        "Obnovi nakupe", "Obnoviť nákupy", "Врати куповине"),
    "offer.feature1": row3(
        "240 tečajev splošne razgledanosti", "240 kurzov všeobecného prehľadu",
        "240 курсева опште културе"),
    "offer.feature2": row3(
        "Neomejeni interaktivni kvizi", "Neobmedzené interaktívne kvízy",
        "Неограничени интерактивни квизови"),
    "offer.feature3": row3(
        "Nova vsebina vsak teden", "Nový obsah každý týždeň",
        "Нови садржај сваке недеље"),
    "profile.title": row3("Profil", "Profil", "Профил"),
    "profile.streak.start": row3(
        "Preberi tečaj in začni!", "Prečítaj si kurz a rozbehni to!",
        "Прочитај курс и крени!"),
    "profile.streak.beginning": row3(
        "Začel si — kar tako naprej!", "Začal si — pokračuj!",
        "Кренуо си — само настави!"),
    "profile.streak.good": row3(
        "Lepa rednost 👏", "Pekná pravidelnosť 👏", "Одлична редовност 👏"),
    "profile.streak.great": row3("Goriš 🔥", "Horíš 🔥", "Гори ти 🔥"),
    "profile.favorites": row3(
        "Moje priljubljene", "Moje obľúbené", "Моји фаворити"),
    "profile.favorites.count": row3(
        "%d shranjenih tečajev", "%d uložených kurzov", "%d сачуваних курсева"),
    "profile.quiz.recent": row3(
        "MOJI ZADNJI KVIZI", "MOJE POSLEDNÉ KVÍZY", "МОЈИ НЕДАВНИ КВИЗОВИ"),
    "profile.quiz.locked": row3(
        "Kvizi so zaklenjeni", "Kvízy sú zamknuté", "Квизови су закључани"),
    "profile.quiz.lockedSubtitle": row3(
        "Na voljo z brezplačnim preizkusom — 3 dni zastonj",
        "Dostupné s bezplatnou skúškou — 3 dni zadarmo",
        "Доступни уз бесплатну пробу — 3 дана гратис"),
    "profile.quiz.unlock": row3(
        "Odkleni moje kvize", "Odomknúť moje kvízy", "Откључај моје квизове"),
    "profile.quiz.emptyTitle": row3(
        "Kvizov še ni", "Zatiaľ žiadne kvízy", "Још нема квизова"),
    "profile.quiz.emptySubtitle": row3(
        "Dokončaj tečaj in opravi svoj prvi kviz.",
        "Dokonči kurz a daj si prvý kvíz.",
        "Заврши курс да одрадиш свој први квиз."),
    "profile.progress.bySubject": row3(
        "NAPREDEK PO TEMAH", "POKROK PODĽA TÉM", "НАПРЕДАК ПО ТЕМАМА"),
    "profile.stats.coursesDone": row3(
        "Končani tečaji", "Dokončené kurzy", "Завршени курсеви"),
    "profile.mastery.title": row3(
        "TVOJ ZEMLJEVID ZNANJA", "TVOJA MAPA VEDOMOSTÍ", "ТВОЈА МАПА ЗНАЊА"),
    "profile.mastery.details": row3(
        "Prikaži podrobnosti po predmetih", "Zobraziť detaily podľa predmetu",
        "Прикажи детаље по предметима"),
    "profile.mastery.hide": row3(
        "Skrij podrobnosti", "Skryť detaily", "Сакриј детаље"),
    "profile.unlock.trial": row3(
        "Odkleni z brezplačnim preizkusom", "Odomkni bezplatnou skúškou",
        "Откључај уз бесплатну пробу"),
    "profile.quiz.retry": row3("Ponovi", "Znova", "Понови"),
    "profile.quiz.all": row3(
        "Vsi moji kvizi", "Všetky moje kvízy", "Сви моји квизови"),
    "profile.quiz.none": row3(
        "Trenutno ni kvizov.", "Zatiaľ žiadne kvízy.", "Тренутно нема квизова."),
    "profile.progress.max": row3(
        "%d XP · najvišja raven", "%d XP · max. úroveň", "%d XP · макс. ниво"),
    "profile.progress.toNext": row3(
        "%d XP · %d do rav. %d", "%d XP · %d do úr. %d", "%d XP · %d до нивоа %d"),
})

# --- friends leaderboard ---------------------------------------------------
STRINGS3.update({
    "friends.title": row3(
        "LESTVICA PRIJATELJEV", "REBRÍČEK PRIATEĽOV", "ЛИСТА ПРИЈАТЕЉА"),
    "friends.you": row3("Ti", "Ty", "Ти"),
    "friends.add.short": row3("Dodaj", "Pridať", "Додај"),
    "friends.add.title": row3(
        "Dodaj prijatelja", "Pridať priateľa", "Додај пријатеља"),
    "friends.add.subtitle": row3(
        "Vpiši @ svojega prijatelja, da ga dodaš na svojo lestvico.",
        "Zadaj @ svojho kamaráta a pridaj ho do svojho rebríčka.",
        "Упиши @ свог пријатеља да га додаш на своју листу."),
    "friends.add.requestSubtitle": row3(
        "Vpiši @ svojega prijatelja: prejel bo prošnjo, ki jo lahko sprejme.",
        "Zadaj @ svojho kamaráta: príde mu žiadosť na potvrdenie.",
        "Упиши @ свог пријатеља: добиће захтев који може да прихвати."),
    "friends.request.send": row3(
        "Pošlji prošnjo", "Odoslať žiadosť", "Пошаљи захтев"),
    "friends.request.sent": row3(
        "Prošnja poslana!", "Žiadosť odoslaná!", "Захтев послат!"),
    "friends.request.autoAccepted": row3(
        "Zdaj sta prijatelja!", "Teraz ste priatelia!", "Сада сте пријатељи!"),
    "friends.requests.title": row3(
        "PREJETE PROŠNJE", "PRIJATÉ ŽIADOSTI", "ПРИМЉЕНИ ЗАХТЕВИ"),
    "friends.requests.accept": row3("Sprejmi", "Prijať", "Прихвати"),
    "friends.requests.decline": row3("Zavrni", "Odmietnuť", "Одбиј"),
    "friends.error.alreadyFriends": row3(
        "Že sta prijatelja.", "Už ste priatelia.", "Већ сте пријатељи."),
    "friends.error.requestAlreadySent": row3(
        "Prošnja je že poslana.", "Žiadosť je už odoslaná.",
        "Захтев је већ послат."),
    "friends.error.requestNotFound": row3(
        "Ta prošnja ni več na voljo.", "Táto žiadosť už nie je dostupná.",
        "Овај захтев више није доступан."),
    "friends.add.action": row3("Dodaj", "Pridať", "Додај"),
    "friends.add.success": row3(
        "Prijatelj dodan!", "Priateľ pridaný!", "Пријатељ додат!"),
    "friends.handle.placeholder": row3(
        "uporabniško ime", "používateľské meno", "корисничко име"),
    "friends.handle.edit.title": row3(
        "Spremeni svoj @", "Uprav svoje @", "Промени свој @"),
    "friends.handle.edit.subtitle": row3(
        "Po @ te prijatelji najdejo.", "Vďaka @ ťa kamaráti nájdu.",
        "По @ те пријатељи могу пронаћи."),
    "friends.handle.save": row3("Shrani", "Uložiť", "Сачувај"),
    "friends.handle.rules": row3(
        "3–20 znakov, samo črke in številke, začne se s črko.",
        "3–20 znakov, iba písmená a číslice, musí začínať písmenom.",
        "3–20 знакова, само слова и бројеви, почиње словом."),
    "friends.period.week": row3("7 dni", "7 dní", "7 дана"),
    "friends.period.all": row3("Skupaj", "Celkovo", "Укупно"),
    "friends.empty.title": row3(
        "Še ni prijateljev", "Zatiaľ žiadni priatelia", "Још нема пријатеља"),
    "friends.empty.body": row3(
        "Dodaj prijatelje prek @ in primerjajta XP.",
        "Pridaj si kamarátov cez ich @ a porovnávajte XP.",
        "Додај пријатеље преко @ да упоредите XP."),
    "friends.signedOut.title": row3(
        "Prijavi se za prijatelje", "Prihlás sa a pridaj priateľov",
        "Пријави се за пријатеље"),
    "friends.signedOut.body": row3(
        "Ustvari račun, da dobiš @ in dodajaš prijatelje.",
        "Vytvor si účet, získaj @ a pridávaj kamarátov.",
        "Направи налог да добијеш @ и додајеш пријатеље."),
    "friends.remove": row3(
        "Odstrani prijatelja", "Odobrať priateľa", "Уклони пријатеља"),
    "friends.remove.title": row3(
        "Odstraniš tega prijatelja?", "Odobrať tohto priateľa?",
        "Уклонити овог пријатеља?"),
    "friends.remove.message": row3(
        "Pozneje ga lahko spet dodaš prek @.",
        "Neskôr si ho môžeš znova pridať cez jeho @.",
        "Касније га можеш поново додати преко @."),
    "friends.remove.confirm": row3("Odstrani", "Odstrániť", "Уклони"),
    "friends.stats.streak": row3("Dni zapored", "Dní v rade", "Дана заредом"),
    "friends.stats.quizzes": row3(
        "Končani kvizi", "Hotové kvízy", "Завршени квизови"),
})

# --- quiz feedback, course end, prepaywall, global ranks ------------------
# `globalRank.xpBefore` inserts a rank NAME after a preposition governing the
# genitive in all three, so the frame reads "do ranga %@" / "до ранга %@" and
# the name keeps its nominative dictionary form. Same reason
# `course.streak.message` puts the subject in apposition after "tema"/"тема".
STRINGS3.update({
    "friends.error.generic": row3(
        "Prišlo je do napake. Poskusi znova.",
        "Niečo sa pokazilo. Skús to znova.",
        "Дошло је до грешке. Покушај поново."),
    "friends.error.notSignedIn": row3(
        "Prijavi se za nadaljevanje.", "Prihlás sa, aby si mohol pokračovať.",
        "Пријави се да наставиш."),
    "friends.error.invalidHandle": row3(
        "Ta @ ni veljaven.", "Toto @ je neplatné.", "Овај @ није важећи."),
    "friends.error.handleTaken": row3(
        "Ta @ je že zaseden.", "Toto @ je už obsadené.", "Овај @ је већ заузет."),
    "friends.error.userNotFound": row3(
        "Nobenega uporabnika s tem @.", "Žiadny používateľ s týmto @.",
        "Нема корисника с тим @."),
    "friends.error.cannotAddSelf": row3(
        "Sebe ne moreš dodati.", "Sám seba pridať nemôžeš.",
        "Не можеш додати самог себе."),
    "friends.error.notFriends": row3(
        "Nista prijatelja.", "Nie ste priatelia.", "Нисте пријатељи."),
    "quiz.feedback.correct": row3("Pravilno!", "Správne!", "Тачно!"),
    "quiz.feedback.excellent": row3("Odlično!", "Skvelé!", "Одлично!"),
    "quiz.feedback.amazing": row3("Neverjetno!", "Úžasné!", "Невероватно!"),
    "quiz.feedback.wrong": row3(
        "Ne čisto...", "Nie celkom...", "Не баш..."),
    "quiz.completed": row3(
        "Bravo, kviz je končan!", "Výborne, kvíz je hotový!",
        "Браво, квиз је готов!"),
    "quiz.correctAnswers": row3(
        "pravilnih odgovorov", "správnych odpovedí", "тачних одговора"),
    "quiz.xpProgress": row3("Napredek XP", "Pokrok v XP", "XP напредак"),
    "quiz.levelUp": row3("Nova raven!", "Nová úroveň!", "Нови ниво!"),
    "quiz.breakdown.correct": row3(
        "Pravilni odgovori", "Správne odpovede", "Тачни одговори"),
    "quiz.breakdown.completed": row3(
        "Kviz končan", "Kvíz dokončený", "Квиз завршен"),
    "quiz.xpProgress.max": row3(
        "%d XP · najvišja raven", "%d XP · max. úroveň", "%d XP · макс. ниво"),
    "quiz.xpProgress.toNext": row3(
        "%d XP do rav. %d", "%d XP do úr. %d", "%d XP до нивоа %d"),
    "quiz.pointsEarned": row3(
        "osvojenih točk", "získaných bodov", "освојених поена"),
    "quiz.feedback.close": row3("Skoraj!", "Skoro!", "Скоро!"),
    "quiz.feedback.far": row3("Blizu", "Blízko", "Близу"),
    "quiz.trueFalse.true": row3("Prav", "Pravda", "Тачно"),
    "quiz.trueFalse.false": row3("Narobe", "Nepravda", "Нетачно"),
    "quiz.chronological.instruction": row3(
        "Razvrsti dogodke po času (tapni ali povleci).",
        "Zoraď udalosti chronologicky (ťukni alebo potiahni).",
        "Поређај догађаје хронолошки (додирни или превуци)."),
    "quiz.chronological.remaining": row3(
        "Preostali odgovori", "Zostávajúce odpovede", "Преостали одговори"),
    "quiz.chronological.emptySlot": row3(
        "Prazno mesto", "Prázdne miesto", "Празно место"),
    "quiz.chronological.validate": row3(
        "Potrdi vrstni red", "Potvrdiť poradie", "Потврди редослед"),
    "quiz.chronological.correctOrder": row3(
        "Pravilni vrstni red", "Správne poradie", "Тачан редослед"),
    "quiz.slider.validate": row3("Potrdi", "Potvrdiť", "Потврди"),
    "quiz.slider.yourGuess": row3(
        "Tvoj odgovor", "Tvoja odpoveď", "Твој одговор"),
    "quiz.slider.correctAnswer": row3(
        "Pravilni odgovor", "Správna odpoveď", "Тачан одговор"),
    "course.completed": row3(
        "Tečaj je končan!", "Kurz je dokončený!", "Курс је завршен!"),
    "course.dailyFreeDone": row3(
        "Končal si današnji brezplačni tečaj",
        "Dokončil si dnešný bezplatný kurz",
        "Завршио си данашњи бесплатни курс"),
    "course.unlock.free": row3(
        "Odkleni brezplačno", "Odomknúť zadarmo", "Откључај бесплатно"),
    "course.quiz.access": row3(
        "Odpri kviz", "Otvoriť kvíz", "Отвори квиз"),
    "course.unlock.cta": row3(
        "Odkleni tečaj", "Odomknúť kurz", "Откључај курс"),
    "course.streak.day": row3("Dan zapored", "Deň v rade", "Дан заредом"),
    "course.streak.days": row3("Dni zapored", "Dní v rade", "Дана заредом"),
    "course.streak.message": row3(
        "Res napreduješ — tema »%@« ti ne more več nič!",
        "Naozaj napreduješ — téma „%@“ ti už nič nespraví!",
        "Стварно напредујеш — тема „%@“ ти више не може ништа!"),
    "course.streak.onTrack": row3(
        "Niz se že začenja!", "Séria je na spadnutie!", "Низ је на помолу!"),
    "prepaywall.quiz.title": row3(
        "Odkleni kvize\nbrezplačno", "Odomkni kvízy\nzadarmo",
        "Откључај квизове\nбесплатно"),
    "prepaywall.quiz.subtitle": row3(
        "Preveri svoje znanje in\nnapreduj vsak dan",
        "Over si vedomosti a\nposúvaj sa každý deň",
        "Провери знање и\nнапредуј сваког дана"),
    "prepaywall.course.subtitle": row3(
        "Uči se naprej in\nodkrivaj nove teme",
        "Uč sa ďalej a\nobjavuj nové témy",
        "Настави да учиш и\nоткривај нове теме"),
    "prepaywall.course.access": row3(
        "Odpri tečaj", "Otvoriť kurz", "Отвори курс"),
    "levelUp.title": row3("Nova raven!", "Nová úroveň!", "Нови ниво!"),
    "globalRank.curieux": row3("Radovednež", "Zvedavec", "Радозналац"),
    "globalRank.erudit": row3("Razgledanec", "Znalec", "Ерудита"),
    "globalRank.savant": row3("Učenjak", "Učenec", "Зналац"),
    "globalRank.maitre": row3("Mojster", "Majster", "Мајстор"),
    "globalRank.legende": row3("Legenda", "Legenda", "Легенда"),
    "globalRank.title": row3(
        "Globalni rang", "Globálna hodnosť", "Глобални ранг"),
    "globalRank.badge": row3(
        "GLOBALNI RANG", "GLOBÁLNA HODNOSŤ", "ГЛОБАЛНИ РАНГ"),
    "globalRank.maxLevel": row3(
        "Najvišja raven", "Najvyššia úroveň", "Највиши ниво"),
    "globalRank.xpBefore": row3(
        "%d XP do ranga %@", "%d XP do hodnosti %@", "%d XP до ранга %@"),
    "globalRank.newRank": row3("Nov rang!", "Nová hodnosť!", "Нови ранг!"),
    "globalRank.reachedLevel": row3(
        "Pravkar si dosegel raven %d", "Práve si dosiahol úroveň %d",
        "Управо си достигао ниво %d"),
    "paywall.unavailable.title": row3(
        "Ponudba ni na voljo", "Ponuka nie je dostupná", "Понуда није доступна"),
    "paywall.unavailable.message": row3(
        "Te ponudbe trenutno ni mogoče naložiti.",
        "Túto ponuku sa teraz nedá načítať.",
        "Тренутно није могуће учитати ову понуду."),
    "course.finish": row3(
        "Končaj tečaj", "Dokončiť kurz", "Заврши курс"),
    "course.funFact.hint": row3(
        "Tapni za razkritje", "Ťukni a odhaľ", "Додирни да откријеш"),
    "onboardingV2.pw.pro": row3("PRO", "PRO", "PRO"),
    "quiz.combo": row3("Kombo x%d", "Kombo x%d", "Комбо x%d"),
})
