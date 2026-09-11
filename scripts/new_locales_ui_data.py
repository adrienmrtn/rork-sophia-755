"""Hand-written UI strings for the four locales added after the 15-language set.

Voice follows the French source: informal, short, no bureaucratic register.
Per-locale decisions, kept consistent across all 824 keys:

  da  Danish — "du". kursus/kurser, quiz, niveau, "dage i træk" for a streak.
      Practice section = "Repetition".
  nb  Norwegian Bokmål — "du". kurs, quiz, nivå, "dager på rad".
      Practice section = "Repetisjon".
  ru  Russian — informal "ты" throughout, matching the French tutoiement and
      the young audience. курс, тест (not "квиз": a knowledge check is a тест
      in Russian), уровень, серия. Practice section = "Повторение".
  hr  Croatian — "ti". tečaj, kviz, razina, niz. Practice = "Ponavljanje".

Names in testimonials keep their Latin spelling everywhere except Russian,
where they are transliterated because the surrounding text is Cyrillic.
"""

from __future__ import annotations

LANGS = ["da", "nb", "ru", "hr"]


def row(da: str, nb: str, ru: str, hr: str) -> dict[str, str]:
    return {"da": da, "nb": nb, "ru": ru, "hr": hr}


STRINGS: dict[str, dict[str, str]] = {}

# --- tabs + training ------------------------------------------------------
STRINGS.update({
    "tab.home": row("Hjem", "Hjem", "Главная", "Početna"),
    "tab.library": row("Bibliotek", "Bibliotek", "Библиотека", "Knjižnica"),
    "tab.collections": row("Samlinger", "Samlinger", "Подборки", "Zbirke"),
    "tab.profile": row("Profil", "Profil", "Профиль", "Profil"),
    "tab.training": row("Repetition", "Repetisjon", "Повторение", "Ponavljanje"),
    "training.title": row("Repetition", "Repetisjon", "Повторение", "Ponavljanje"),
    "training.readyTitle": row(
        "Tid til at repetere", "Tid for å repetere", "Пора повторить",
        "Vrijeme je za ponavljanje"),
    "training.dueCount": row(
        "%d spørgsmål at repetere i dag", "%d spørsmål å repetere i dag",
        "%d вопросов на повторение сегодня", "%d pitanja za ponoviti danas"),
    "training.emptyTitle": row(
        "Alt er klaret!", "Alt er unnagjort!", "Всё пройдено!", "Sve je odrađeno!"),
    "training.emptyMessage": row(
        "Kom tilbage i morgen og repeter videre.",
        "Kom tilbake i morgen og repeter videre.",
        "Возвращайся завтра, чтобы продолжить повторение.",
        "Vrati se sutra i nastavi s ponavljanjem."),
    "training.locked.title": row(
        "Lås Repetition op", "Lås opp Repetisjon", "Открой Повторение",
        "Otključaj Ponavljanje"),
    "training.locked.message": row(
        "Tag quizzen til et kursus, så havner spørgsmålene her — og du repeterer dem præcis når det tæller.",
        "Ta quizen til et kurs, så havner spørsmålene her — og du repeterer dem akkurat når det teller.",
        "Пройди тест курса — его вопросы попадут сюда, и ты повторишь их ровно тогда, когда нужно.",
        "Riješi kviz nekog tečaja i njegova pitanja stižu ovdje — ponovit ćeš ih točno kad treba."),
    "training.locked.tagline": row(
        "Husk det du lærer — for alvor.", "Husk det du lærer — på ordentlig.",
        "Запоминай то, что учишь, надолго.", "Zapamti ono što učiš, zaista."),
    "training.unlock": row(
        "Lås Repetition op", "Lås opp Repetisjon", "Открыть Повторение",
        "Otključaj Ponavljanje"),
    "training.discover": row("Opdag", "Oppdag", "Открой", "Otkrij"),
    "training.how.title": row(
        "SÅDAN VIRKER DET", "SLIK FUNGERER DET", "КАК ЭТО РАБОТАЕТ", "KAKO TO RADI"),
    "training.how.step1": row(
        "Tag et kursus og dets quiz", "Ta et kurs og quizen til det",
        "Пройди курс и его тест", "Odradi tečaj i njegov kviz"),
    "training.how.step2": row(
        "Spørgsmålene havner i Repetition", "Spørsmålene havner i Repetisjon",
        "Его вопросы попадают в Повторение", "Njegova pitanja idu u Ponavljanje"),
    "training.how.step3": row(
        "Repeter dem på det rigtige tidspunkt, så du ikke glemmer dem",
        "Repeter dem til rett tid, så du ikke glemmer dem",
        "Повторяй их в нужный момент, чтобы не забыть",
        "Ponovi ih u pravom trenutku da ih ne zaboraviš"),
    "training.emptyCta": row(
        "Find et kursus", "Finn et kurs", "Найти курс", "Otkrij tečaj"),
    "training.ob.welcome.line": row(
        "Det her er Repetition.", "Dette er Repetisjon.", "Это раздел Повторение.",
        "Ovo je Ponavljanje."),
    "training.ob.recall.title": row(
        "Vi spørger dig, så det du lærte faktisk bliver siddende.",
        "Vi spør deg, så det du lærte faktisk sitter.",
        "Мы задаём вопросы, чтобы выученное действительно осталось.",
        "Postavljamo ti pitanja da naučeno doista ostane."),
    "training.ob.recall.legend.sophia": row(
        "Med Sophia", "Med Sophia", "С Sophia", "Uz Sophiju"),
    "training.ob.recall.legend.reread": row(
        "Almindelig genlæsning", "Vanlig gjennomlesing", "Простое перечитывание",
        "Obično ponovno čitanje"),
    "training.ob.recall.stat.prefix": row(
        "Efter en uge husker faste brugere af Sophia Repetition",
        "Etter en uke husker faste brukere av Sophia Repetisjon",
        "Через неделю постоянные пользователи Sophia Повторения помнят",
        "Nakon tjedan dana redoviti korisnici Sophia Ponavljanja pamte"),
    "training.ob.recall.stat.highlight": row(
        "2,2× mere", "2,2× mer", "в 2,2× больше", "2,2× više"),
    "training.ob.recall.stat.suffix": row(
        "af kursusstoffet end en, der ikke bruger det.",
        "av kursstoffet enn en som ikke bruker det.",
        "материала своих курсов, чем те, кто им не пользуется.",
        "gradiva svojih tečajeva nego onaj tko ga ne koristi."),
    "training.ob.recall.cta": row(
        "Sådan virker det", "Slik fungerer det", "Как это работает", "Kako to radi"),
    "training.ob.algo.title": row(
        "En algoritme tester dig hele tiden", "En algoritme tester deg hele tiden",
        "Алгоритм проверяет тебя постоянно", "Algoritam te ispituje neprekidno"),
    "training.ob.algo.body": row(
        "Vi henter quizzer, du allerede har taget, frem igen — præcis i tide. De ligger alle sammen her.",
        "Vi henter fram quizer du allerede har tatt — akkurat i tide. Alle ligger her.",
        "Мы возвращаем тесты, которые ты уже проходил, ровно вовремя. Все они собраны здесь.",
        "Vraćamo ti kvizove koje si već riješio, točno na vrijeme. Svi su ovdje."),
    "training.ob.algo.highlight.value": row(
        "5 min/dag", "5 min/dag", "5 мин/день", "5 min/dan"),
    "training.ob.algo.highlight.label": row(
        "til en hukommelse, der holder for alvor.",
        "for en hukommelse som varer.",
        "для памяти, которая действительно держится.",
        "za pamćenje koje stvarno traje."),
    "training.ob.cta.last": row("Fortsæt", "Fortsett", "Дальше", "Nastavi"),
    "training.start": row("Start", "Start", "Начать", "Počni"),
    "training.finish": row("Afslut", "Avslutt", "Завершить", "Završi"),
    "training.backToTraining": row("Tilbage", "Tilbake", "Назад", "Natrag"),
    "training.sessionComplete.title": row(
        "Runden er slut", "Økten er ferdig", "Повторение завершено", "Kraj runde"),
    "training.sessionComplete.summary": row(
        "%d rigtige ud af %d", "%d riktige av %d", "%d правильных из %d",
        "%d točnih od %d"),
})

# --- library + language picker -------------------------------------------
STRINGS.update({
    "library.title": row("Bibliotek", "Bibliotek", "Библиотека", "Knjižnica"),
    "library.tab.courses": row("Kurser", "Kurs", "Курсы", "Tečajevi"),
    "library.tab.collections": row("Samlinger", "Samlinger", "Подборки", "Zbirke"),
    "library.search.placeholder": row(
        "Søg efter et kursus...", "Søk etter et kurs...", "Найти курс...",
        "Pretraži tečaj..."),
    "language.section": row("Sprog", "Språk", "Язык", "Jezik"),
    "language.french": row("Français", "Français", "Français", "Français"),
    "language.english": row("English", "English", "English", "English"),
    "language.spanish": row("Español", "Español", "Español", "Español"),
    "language.german": row("Deutsch", "Deutsch", "Deutsch", "Deutsch"),
    "language.portuguese": row("Português", "Português", "Português", "Português"),
    "language.italian": row("Italiano", "Italiano", "Italiano", "Italiano"),
    "language.turkish": row("Türkçe", "Türkçe", "Türkçe", "Türkçe"),
    "language.polish": row("Polski", "Polski", "Polski", "Polski"),
    "language.romanian": row("Română", "Română", "Română", "Română"),
    "language.dutch": row("Nederlands", "Nederlands", "Nederlands", "Nederlands"),
    "language.greek": row("Ελληνικά", "Ελληνικά", "Ελληνικά", "Ελληνικά"),
    "language.swedish": row("Svenska", "Svenska", "Svenska", "Svenska"),
    "language.hungarian": row("Magyar", "Magyar", "Magyar", "Magyar"),
    "language.bulgarian": row("Български", "Български", "Български", "Български"),
    "language.czech": row("Čeština", "Čeština", "Čeština", "Čeština"),
})

# --- intro / auth / account / sync ---------------------------------------
STRINGS.update({
    "onboarding.intro.title": row(
        "Bliv klogere\npå 10 minutter\nom dagen",
        "Bli smartere\npå 10 minutter\nom dagen",
        "Стань умнее\nза 10 минут\nв день",
        "Postani pametniji\nu 10 minuta\ndnevno"),
    "onboarding.intro.cta": row("Kom i gang", "Kom i gang", "Начать", "Kreni"),
    "onboarding.language.title": row(
        "Vælg dit sprog", "Velg språket ditt", "Выбери язык", "Odaberi jezik"),
    "onboarding.language.subtitle": row(
        "Du kan ændre det senere.", "Du kan endre det senere.",
        "Его можно поменять позже.", "Možeš ga promijeniti kasnije."),
    "discount.sideTab.label": row("TILBUD", "TILBUD", "АКЦИЯ", "PONUDA"),
    "auth.error.token": row(
        "Login mislykkedes. Prøv igen.", "Innloggingen mislyktes. Prøv igjen.",
        "Не удалось войти. Попробуй ещё раз.", "Prijava nije uspjela. Pokušaj ponovno."),
    "auth.error.generic": row(
        "Noget gik galt. Prøv igen.", "Noe gikk galt. Prøv igjen.",
        "Что-то пошло не так. Попробуй ещё раз.", "Nešto je pošlo po zlu. Pokušaj ponovno."),
    "auth.continueWithApple": row(
        "Fortsæt med Apple", "Fortsett med Apple", "Продолжить с Apple",
        "Nastavi s Appleom"),
    "auth.continueWithGoogle": row(
        "Fortsæt med Google", "Fortsett med Google", "Продолжить с Google",
        "Nastavi s Googleom"),
    "auth.onboarding.title": row(
        "Opret din konto\nog kom i gang",
        "Opprett kontoen din\nog kom i gang",
        "Создай аккаунт,\nчтобы начать",
        "Otvori račun\ni kreni"),
    "auth.onboarding.subtitle": row(
        "Log ind, så din fremgang gemmes og følger med på alle dine enheder.",
        "Logg inn, så lagres fremgangen din og følger med på alle enhetene dine.",
        "Войди, чтобы сохранить прогресс и открывать его на всех своих устройствах.",
        "Prijavi se da spremiš napredak i imaš ga na svim uređajima."),
    "auth.legal.prefix": row(
        "Ved at fortsætte accepterer du vores",
        "Ved å fortsette godtar du våre",
        "Продолжая, ты принимаешь наши",
        "Nastavkom prihvaćaš naše"),
    "account.title": row("Konto", "Konto", "Аккаунт", "Račun"),
    "account.signedIn.title": row(
        "Min konto", "Kontoen min", "Мой аккаунт", "Moj račun"),
    "account.manage.subtitle": row(
        "Administrer din konto", "Administrer kontoen din", "Управляй аккаунтом",
        "Upravljaj računom"),
    "account.create.title": row(
        "Opret en konto", "Opprett en konto", "Создать аккаунт", "Otvori račun"),
    "account.create.subtitle": row(
        "Gem din fremgang i skyen", "Lagre fremgangen din i skyen",
        "Сохрани прогресс в облаке", "Spremi napredak u oblak"),
    "account.signedOut.headline": row(
        "Gem din fremgang", "Lagre fremgangen din", "Сохрани свой прогресс",
        "Spremi svoj napredak"),
    "account.signedOut.body": row(
        "Opret en konto, så din fremgang gemmes og følger med på alle dine enheder. Det er valgfrit.",
        "Opprett en konto, så lagres fremgangen din og følger med på alle enhetene dine. Det er valgfritt.",
        "Создай аккаунт, чтобы сохранить прогресс и открывать его на всех устройствах. Это необязательно.",
        "Otvori račun da spremiš napredak i imaš ga na svim uređajima. Nije obavezno."),
    "account.email": row("E-mail", "E-post", "Эл. почта", "E-mail"),
    "account.provider": row(
        "Logget ind med", "Logget inn med", "Вход выполнен через", "Prijavljen preko"),
    "account.signOut.action": row("Log ud", "Logg ut", "Выйти", "Odjava"),
    "account.signOut.title": row("Log ud?", "Logge ut?", "Выйти?", "Odjaviti se?"),
    "account.signOut.message": row(
        "Din fremgang bliver gemt på denne enhed.",
        "Fremgangen din blir værende på denne enheten.",
        "Твой прогресс останется сохранён на этом устройстве.",
        "Tvoj napredak ostaje spremljen na ovom uređaju."),
    "account.signOut.confirm": row("Log ud", "Logg ut", "Выйти", "Odjava"),
    "account.delete.action": row(
        "Slet min konto", "Slett kontoen min", "Удалить аккаунт", "Obriši moj račun"),
    "account.delete.title": row(
        "Slet kontoen?", "Slette kontoen?", "Удалить аккаунт?", "Obrisati račun?"),
    "account.delete.message": row(
        "Det kan ikke fortrydes. Din konto og de tilhørende data bliver slettet.",
        "Dette kan ikke angres. Kontoen din og tilhørende data blir slettet.",
        "Это необратимо. Аккаунт и связанные с ним данные будут удалены.",
        "Ovo je nepovratno. Tvoj račun i povezani podaci bit će obrisani."),
    "account.delete.confirm": row("Slet", "Slett", "Удалить", "Obriši"),
    "account.delete.error": row(
        "Sletningen mislykkedes. Prøv igen.", "Slettingen mislyktes. Prøv igjen.",
        "Не удалось удалить. Попробуй ещё раз.", "Brisanje nije uspjelo. Pokušaj ponovno."),
    "sync.conflict.title": row(
        "Vi fandt to fremgange", "Vi fant to fremganger", "Найдено два прогресса",
        "Pronađena su dva napretka"),
    "sync.conflict.body": row(
        "Vælg hvilken fremgang du beholder. Den anden bliver erstattet.",
        "Velg hvilken fremgang du beholder. Den andre blir erstattet.",
        "Выбери, какой прогресс оставить. Второй будет заменён.",
        "Odaberi koji napredak zadržavaš. Drugi će biti zamijenjen."),
    "sync.conflict.local": row(
        "Denne enhed", "Denne enheten", "Это устройство", "Ovaj uređaj"),
    "sync.conflict.remote": row(
        "Din konto", "Kontoen din", "Твой аккаунт", "Tvoj račun"),
    "sync.conflict.summary": row(
        "%d kurser · niveau %d · %d dage i træk",
        "%d kurs · nivå %d · %d dager på rad",
        "%d курсов · уровень %d · серия %d дн.",
        "%d tečajeva · razina %d · %d dana zaredom"),
})

# --- onboarding V2: questions, screen time, testimonials ------------------
STRINGS.update({
    "onboardingV2.questions.q1": row(
        "Hvorfor er himlen blå?", "Hvorfor er himmelen blå?",
        "Почему небо голубое?", "Zašto je nebo plavo?"),
    "onboardingV2.questions.q2": row(
        "Hvordan vandt Napoleon ved Ulm?", "Hvordan vant Napoleon ved Ulm?",
        "Как Наполеон победил под Ульмом?", "Kako je Napoleon pobijedio kod Ulma?"),
    "onboardingV2.questions.q3": row(
        "Hvad er et sort hul?", "Hva er et svart hull?",
        "Что такое чёрная дыра?", "Što je crna rupa?"),
    "onboardingV2.questions.q4": row(
        "Hvad er impressionisme?", "Hva er impresjonisme?",
        "Что такое импрессионизм?", "Što je impresionizam?"),
    "onboardingV2.questions.q5": row(
        "Hvordan fungerer statsgæld?", "Hvordan fungerer statsgjeld?",
        "Как работает государственный долг?", "Kako funkcionira javni dug?"),
    "onboardingV2.questions.q6": row(
        "Hvorfor falder Månen ikke ned?", "Hvorfor faller ikke Månen ned?",
        "Почему Луна не падает?", "Zašto Mjesec ne pada?"),
    "onboardingV2.questions.q7": row(
        "Hvem var Kleopatra i virkeligheden?", "Hvem var Kleopatra egentlig?",
        "Кем на самом деле была Клеопатра?", "Tko je zapravo bila Kleopatra?"),
    "onboardingV2.questions.q8": row(
        "Hvordan blev universet til?", "Hvordan ble universet til?",
        "Как родилась Вселенная?", "Kako je nastao svemir?"),
    "onboardingV2.questions.q9": row(
        "Hvorfor drømmer vi om natten?", "Hvorfor drømmer vi om natten?",
        "Почему мы видим сны?", "Zašto sanjamo noću?"),
    "onboardingV2.questions.q10": row(
        "Hvad er Einsteins relativitetsteori?", "Hva er Einsteins relativitetsteori?",
        "Что такое теория относительности Эйнштейна?",
        "Što je Einsteinova teorija relativnosti?"),
    "onboardingV2.screenTime.title": row(
        "Tag din tid tilbage", "Ta tiden din tilbake", "Верни своё время",
        "Vrati svoje vrijeme"),
    "onboardingV2.screenTime.caption": row(
        "Vores brugere bruger nu i gennemsnit kun 39 minutter om dagen på telefonen.",
        "Brukerne våre bruker nå i snitt bare 39 minutter om dagen på telefonen.",
        "В среднем наши пользователи теперь проводят в телефоне всего 39 минут в день.",
        "Naši korisnici sada u prosjeku provedu samo 39 minuta dnevno na mobitelu."),
    "onboardingV2.screenTime.minutes": row("%d min", "%d min", "%d мин", "%d min"),
    "onboardingV2.phoneTime.title": row(
        "Hvor lang tid bruger du på telefonen hver dag?",
        "Hvor lang tid bruker du på telefonen hver dag?",
        "Сколько времени ты проводишь в телефоне каждый день?",
        "Koliko vremena dnevno provodiš na mobitelu?"),
    "onboardingV2.yearsGrid.title": row(
        "Her er dit liv i år", "Her er livet ditt i år", "Вот твоя жизнь в годах",
        "Evo tvog života u godinama"),
    "onboardingV2.yearsGrid.caption": row(
        "Det er %d hele år, du mister på telefonen i løbet af livet.",
        "Det er %d hele år du mister på telefonen i løpet av livet.",
        "Это %d полных лет, которые ты теряешь в телефоне за всю жизнь.",
        "To je %d punih godina koje izgubiš na mobitelu tijekom života."),
    "onboardingV2.transform.text": row(
        "Med Sophia bliver den tid til viden",
        "Med Sophia blir den tiden til kunnskap",
        "С Sophia преврати это время в знания",
        "Uz Sophiju to vrijeme pretvori u znanje"),
    "onboardingV2.transform.words": row(
        "viden, kunst, filosofi, videnskab, historie, litteratur",
        "kunnskap, kunst, filosofi, vitenskap, historie, litteratur",
        "знания, искусство, философия, наука, история, литература",
        "znanje, umjetnost, filozofija, znanost, povijest, književnost"),
    "onboardingV2.transform.tapHint": row(
        "Tryk for at fortsætte", "Trykk for å fortsette", "Нажми, чтобы продолжить",
        "Dodirni za nastavak"),
    "onboardingV2.exams.title": row(
        "De forbedrede deres karakterer", "De forbedret karakterene sine",
        "Они подтянули оценки", "Popravili su svoje ocjene"),
    "onboardingV2.exams.quote1": row(
        "»Takket være Sophia steg mit snit i historie med 3 point i dette kvartal.«",
        "«Takket være Sophia gikk snittet mitt i historie opp 3 poeng dette halvåret.»",
        "«Благодаря Sophia мой средний балл по истории вырос на 3 пункта за четверть.»",
        "„Zahvaljujući Sophiji, prosjek iz povijesti mi je ovaj polugodište porastao za 3 boda.”"),
    "onboardingV2.exams.author1": row(
        "Thomas, studerende", "Thomas, student", "Тома, студент", "Thomas, student"),
    "onboardingV2.exams.quote2": row(
        "»Jeg repeterer 10 minutter om dagen, og mine karakterer er røget i vejret.«",
        "«Jeg repeterer 10 minutter om dagen, og karakterene mine har skutt i været.»",
        "«Повторяю по 10 минут в день — и оценки реально пошли вверх.»",
        "„Ponavljam 10 minuta dnevno i ocjene su mi stvarno skočile.”"),
    "onboardingV2.exams.author2": row(
        "Inès, 3.g", "Inès, siste året", "Инес, выпускной класс", "Inès, maturantica"),
    "onboardingV2.exams.quote3": row(
        "»Quizzerne hjalp mig med at huske det vigtigste før eksamen.«",
        "«Quizene hjalp meg å huske det viktigste før eksamen.»",
        "«Тесты помогли мне запомнить главное перед экзаменами.»",
        "„Kvizovi su mi pomogli zapamtiti bitno prije ispita.”"),
    "onboardingV2.exams.author3": row(
        "Camille, universitet", "Camille, universitetet", "Камий, университет",
        "Camille, fakultet"),
    "onboardingV2.exams.quote4": row(
        "»Perfekt til at repetere undervejs. Mine lærere kunne se forskellen.«",
        "«Perfekt til å repetere på farten. Lærerne mine så forskjellen.»",
        "«Идеально повторять по дороге. Учителя заметили разницу.»",
        "„Savršeno za ponavljanje u pokretu. Profesori su primijetili razliku.”"),
    "onboardingV2.exams.author4": row(
        "Yanis, gymnasiet", "Yanis, videregående", "Янис, старшая школа",
        "Yanis, srednja škola"),
    "onboardingV2.rightPlace.title": row(
        "Du er det rigtige sted", "Du er på rett sted", "Ты в нужном месте",
        "Na pravom si mjestu"),
    "onboardingV2.rightPlace.ofUsers": row(
        "af brugerne", "av brukerne", "пользователей", "korisnika"),
    "onboardingV2.rightPlace.caption": row(
        "…med det mål rykker mærkbart med Sophia.",
        "…med det målet rykker merkbart med Sophia.",
        "…с этой целью заметно продвигаются с Sophia.",
        "…s tim ciljem stvarno napreduju uz Sophiju."),
    "onboardingV2.swipe.title": row(
        "Kurser valgt til dig", "Kurs valgt ut til deg", "Курсы, выбранные для тебя",
        "Tečajevi odabrani za tebe"),
    "onboardingV2.swipe.subtitle": row(
        "Swipe til højre på det, der interesserer dig.",
        "Sveip til høyre på det som interesserer deg.",
        "Свайпни вправо то, что тебе интересно.",
        "Povuci udesno ono što te zanima."),
    "onboardingV2.swipe.like": row("Synes godt om", "Liker", "Нравится", "Sviđa mi se"),
    "onboardingV2.swipe.nope": row("Nej", "Nei", "Нет", "Ne"),
    "onboardingV2.swipe.noted": row("Noteret!", "Notert!", "Записали!", "Zabilježeno!"),
    "onboardingV2.phone.title": row(
        "Hvor meget tid bruger du på telefonen?",
        "Hvor mye tid bruker du på telefonen?",
        "Сколько времени ты проводишь в телефоне?",
        "Koliko vremena provodiš na mobitelu?"),
    "onboardingV2.phone.perDay": row("om dagen", "om dagen", "в день", "dnevno"),
    "onboardingV2.weeks.title": row(
        "Det er %d uger om året", "Det er %d uker i året", "Это %d недель в год",
        "To je %d tjedana godišnje"),
    "onboardingV2.weeks.subtitle": row(
        "Her er dit år. Med rødt: tiden på skærmen.",
        "Her er året ditt. I rødt: tiden på skjermen.",
        "Вот твой год. Красным — время на экране.",
        "Evo tvoje godine. Crveno: vrijeme na ekranu."),
    "onboardingV2.weeks.caption": row(
        "Forestil dig, hvad du kunne lære på en brøkdel af den tid.",
        "Tenk hva du kunne lært på en brøkdel av den tiden.",
        "Представь, чему ты мог бы научиться за малую часть этого времени.",
        "Zamisli što bi naučio s djelićem tog vremena."),
    "onboardingV2.review.title": row(
        "Det siger vores brugere", "Dette sier brukerne våre",
        "Вот что говорят наши пользователи", "Evo što misle naši korisnici"),
    "onboardingV2.review.appStore": row(
        "i App Store", "i App Store", "в App Store", "na App Storeu"),
    "onboardingV2.review.quote": row(
        "»Før brugte jeg 7 timer om dagen på telefonen. Nu kun 40 minutter med Sophia, og jeg føler mig klogere for hver uge.«",
        "«Før brukte jeg 7 timer om dagen på telefonen. Nå bare 40 minutter med Sophia, og jeg føler meg smartere for hver uke.»",
        "«Раньше я сидел в телефоне по 7 часов в день. Теперь 40 минут с Sophia — и каждую неделю чувствую себя умнее.»",
        "„Prije sam po 7 sati dnevno bio na mobitelu. Sad samo 40 minuta uz Sophiju i svaki tjedan se osjećam pametnije.”"),
    "onboardingV2.review.author": row("Léa, 24", "Léa, 24", "Леа, 24", "Léa, 24"),
    "onboardingV2.review.t1.quote": row(
        "Siden jeg scroller mindre og bruger Sophia, føler jeg, at jeg husker langt mere.",
        "Etter at jeg scroller mindre og bruker Sophia, føler jeg at jeg husker mye mer.",
        "С тех пор как я меньше листаю ленту и пользуюсь Sophia, я запоминаю куда больше.",
        "Otkad manje skrolam i koristim Sophiju, osjećam da pamtim puno više."),
    "onboardingV2.review.t1.author": row(
        "Camille, 22", "Camille, 22", "Камий, 22", "Camille, 22"),
    "onboardingV2.review.t2.quote": row(
        "10 minutter i metroen om morgenen, og om aftenen har jeg noget at fortælle. Helt ærligt: jeg er hooked.",
        "10 minutter på T-banen om morgenen, og om kvelden har jeg noe å fortelle. Helt ærlig: jeg er hekta.",
        "10 минут в метро утром — и вечером есть что рассказать. Честно, затянуло.",
        "10 minuta u tramvaju ujutro i navečer imam o čemu pričati. Iskreno, uvuklo me."),
    "onboardingV2.review.t2.author": row(
        "Yanis, 27", "Yanis, 27", "Янис, 27", "Yanis, 27"),
    "onboardingV2.review.t3.quote": row(
        "Jeg har altid hadet at »terpe«, men her sætter det sig helt af sig selv. Min hukommelse overrasker mig.",
        "Jeg har alltid hatet å «pugge», men her sitter det helt av seg selv. Hukommelsen min overrasker meg.",
        "Я всегда ненавидела «зубрёжку», а тут всё запоминается само. Память меня удивляет.",
        "Uvijek sam mrzila „bubanje”, a ovdje sve sjedne samo od sebe. Pamćenje me iznenađuje."),
    "onboardingV2.review.t3.author": row(
        "Inès, 19", "Inès, 19", "Инес, 19", "Inès, 19"),
    "onboardingV2.review.t4.quote": row(
        "Jeg bytter den endeløse scrolling ud med et kursus. På en måned lagde folk omkring mig mærke til forskellen.",
        "Jeg bytter den endeløse scrollingen med et kurs. På en måned merket folk rundt meg forskjellen.",
        "Бесконечную ленту я меняю на курс. За месяц близкие заметили разницу.",
        "Beskonačno skrolanje mijenjam za tečaj. U mjesec dana ljudi oko mene primijetili su razliku."),
    "onboardingV2.review.t4.author": row(
        "Thomas, 31", "Thomas, 31", "Тома, 31", "Thomas, 31"),
    "onboardingV2.review.t5.quote": row(
        "Endelig en app, hvor jeg føler, at jeg rykker i stedet for at spilde tiden. Jeg åbner den hver dag.",
        "Endelig en app der jeg føler at jeg kommer videre i stedet for å kaste bort tid. Jeg åpner den hver dag.",
        "Наконец-то приложение, с которым я чувствую, что двигаюсь вперёд, а не трачу время. Открываю каждый день.",
        "Konačno aplikacija uz koju osjećam da napredujem, a ne gubim vrijeme. Otvaram je svaki dan."),
    "onboardingV2.review.t5.author": row(
        "Sarah, 26", "Sarah, 26", "Сара, 26", "Sarah, 26"),
    "onboardingV2.review.t6.quote": row(
        "Quizzer med mellemrum er ren magi: jeg husker ting fra uger tilbage helt uden at anstrenge mig.",
        "Quizer med mellomrom er ren magi: jeg husker ting fra uker tilbake uten å anstrenge meg.",
        "Тесты с интервалами — это магия: помню то, что учил недели назад, без усилий.",
        "Kvizovi u razmacima su čista magija: pamtim stvari od prije nekoliko tjedana bez muke."),
    "onboardingV2.review.t6.author": row(
        "Malik, 23", "Malik, 23", "Малик, 23", "Malik, 23"),
})

# --- onboarding V2: profile, loading, trial, notifications, first paywall --
STRINGS.update({
    "onboardingV2.personalize.text": row(
        "Lad os tilpasse dit indhold", "La oss tilpasse innholdet ditt",
        "Настроим контент под тебя", "Prilagodimo tvoj sadržaj"),
    "onboardingV2.personalize.tapHint": row(
        "Tryk for at fortsætte", "Trykk for å fortsette", "Нажми, чтобы продолжить",
        "Dodirni za nastavak"),
    "onboardingV2.profile.eyebrow": row(
        "Her er din profil", "Her er profilen din", "Вот твой профиль",
        "Evo tvog profila"),
    "onboardingV2.profile.objectiveTitle": row(
        "Dit mål", "Målet ditt", "Твоя цель", "Tvoj cilj"),
    "onboardingV2.profile.coursesTitle": row(
        "Kurserne, der venter på dig", "Kursene som venter på deg",
        "Курсы, которые тебя ждут", "Tečajevi koji te čekaju"),
    "onboardingV2.profile.cta": row("Så kører vi", "Da kjører vi", "Поехали", "Idemo"),
    "onboardingV2.profile.nickname.cultivate": row(
        "Det nysgerrige sind", "Det nysgjerrige sinnet", "Любознательный ум",
        "Radoznali um"),
    "onboardingV2.profile.nickname.reduceScreen": row(
        "Tidsherren", "Tidsherren", "Хозяин времени", "Gospodar vremena"),
    "onboardingV2.profile.nickname.exams": row(
        "Strategen", "Strategen", "Стратег", "Strateg"),
    "onboardingV2.profile.nickname.impress": row(
        "Den strålende", "Den strålende", "Яркий", "Blistavi"),
    "onboardingV2.profile.nickname.curiosity": row(
        "Opdagelsesrejsende", "Oppdageren", "Исследователь", "Istraživač"),
    "onboardingV2.profile.tagline.cultivate": row(
        "Du vil forstå verden — lidt mere hver dag.",
        "Du vil forstå verden — litt mer hver dag.",
        "Ты хочешь понимать мир — чуть лучше каждый день.",
        "Želiš razumjeti svijet, svaki dan malo više."),
    "onboardingV2.profile.tagline.reduceScreen": row(
        "Du tager kontrollen over din tid og din opmærksomhed tilbage.",
        "Du tar tilbake kontrollen over tiden og oppmerksomheten din.",
        "Ты возвращаешь себе контроль над временем и вниманием.",
        "Vraćaš kontrolu nad svojim vremenom i pažnjom."),
    "onboardingV2.profile.tagline.exams": row(
        "Du lærer med metode og er klar, når det gælder.",
        "Du lærer med metode og er klar når det gjelder.",
        "Ты учишься системно и готов, когда это важно.",
        "Učiš s metodom i spreman si kad je važno."),
    "onboardingV2.profile.tagline.impress": row(
        "Snart er det dig, der har de bedste historier.",
        "Snart er det du som har de beste historiene.",
        "Скоро лучшие истории будут у тебя.",
        "Uskoro ćeš ti imati najbolje priče."),
    "onboardingV2.profile.tagline.curiosity": row(
        "Din nysgerrighed kender ingen grænser — lad os nære den.",
        "Nysgjerrigheten din kjenner ingen grenser — la oss mate den.",
        "Твоему любопытству нет предела — давай его подкормим.",
        "Tvoja radoznalost nema granica — nahranimo je."),
    "onboardingV2.loading.title": row(
        "Vi gør din profil klar", "Vi gjør profilen din klar",
        "Готовим твой профиль", "Pripremamo tvoj profil"),
    "onboardingV2.loading.step1": row(
        "Analyse af dit mål", "Analyse av målet ditt", "Анализ твоей цели",
        "Analiza tvog cilja"),
    "onboardingV2.loading.step2": row(
        "Udvælgelse af dine kurser", "Utvalg av kursene dine", "Подбор твоих курсов",
        "Odabir tvojih tečajeva"),
    "onboardingV2.loading.step3": row(
        "Opbygning af dit program", "Bygger programmet ditt", "Создание твоей программы",
        "Izrada tvog programa"),
    "onboardingV2.loading.cta": row(
        "Se min profil", "Se profilen min", "Показать профиль", "Prikaži moj profil"),
    "onboardingV2.loading.reviews": row(
        "Over 1.000 anmeldelser", "Over 1 000 anmeldelser", "Более 1 000 отзывов",
        "Više od 1.000 recenzija"),
    "onboardingV2.login.title": row(
        "Opret din konto", "Opprett kontoen din", "Создай аккаунт", "Otvori svoj račun"),
    "onboardingV2.login.subtitle": row(
        "Så din fremgang gemmes og følger med på alle dine enheder.",
        "Så fremgangen din lagres og følger med på alle enhetene dine.",
        "Чтобы сохранить прогресс и открывать его на всех устройствах.",
        "Da spremiš napredak i imaš ga na svim uređajima."),
    "onboardingV2.trial.title": row(
        "Sådan virker din gratis prøveperiode",
        "Slik fungerer den gratis prøveperioden din",
        "Как работает бесплатный пробный период",
        "Kako radi tvoje besplatno probno razdoblje"),
    "onboardingV2.trial.cta": row("Jeg er klar", "Jeg er klar", "Я готов", "Spreman sam"),
    "onboardingV2.trial.step0.title": row(
        "Konto oprettet", "Konto opprettet", "Аккаунт создан", "Račun je otvoren"),
    "onboardingV2.trial.step0.detail": row(
        "Din profil er oprettet.", "Profilen din er opprettet.",
        "Твой профиль создан.", "Tvoj profil je stvoren."),
    "onboardingV2.trial.step1.title": row(
        "I dag: prøv Sophia Pro", "I dag: prøv Sophia Pro", "Сегодня: попробуй Sophia Pro",
        "Danas: isprobaj Sophia Pro"),
    "onboardingV2.trial.step1.detail": row(
        "Lær noget nyt på 5 minutter om dagen.",
        "Lær noe nytt på 5 minutter om dagen.",
        "Узнавай что-то новое за 5 минут в день.",
        "Nauči nešto novo u 5 minuta dnevno."),
    "onboardingV2.trial.step2.title": row(
        "Dag 2: påmindelse", "Dag 2: påminnelse", "День 2: напоминание",
        "2. dan: podsjetnik"),
    "onboardingV2.trial.step2.detail": row(
        "Vi giver besked med en notifikation. Kan opsiges på 15 sekunder.",
        "Vi sier fra med et varsel. Kan sies opp på 15 sekunder.",
        "Напомним уведомлением. Отменить можно за 15 секунд.",
        "Javit ćemo ti obavijesti. Otkažeš u 15 sekundi."),
    "onboardingV2.trial.step3.title": row(
        "Dag 3: prøveperioden slutter", "Dag 3: prøveperioden er slutt",
        "День 3: пробный период заканчивается", "3. dan: probno razdoblje istječe"),
    "onboardingV2.trial.step3.detail": row(
        "Dit abonnement starter den %@.", "Abonnementet ditt starter %@.",
        "Твоя подписка начнётся %@.", "Tvoja pretplata počinje %@."),
    "onboardingV2.reminder.title": row(
        "Du får en påmindelse 1 dag før din prøveperiode slutter.",
        "Du får en påminnelse 1 dag før prøveperioden er slutt.",
        "Мы напомним за 1 день до конца пробного периода.",
        "Dobit ćeš podsjetnik 1 dan prije kraja probnog razdoblja."),
    "onboardingV2.reminder.cta": row(
        "Prøv gratis", "Prøv gratis", "Попробовать бесплатно", "Isprobaj besplatno"),
    "onboardingV2.notifications.title": row(
        "Hold dig opdateret", "Hold deg oppdatert", "Будь в курсе", "Ostani u tijeku"),
    "onboardingV2.notifications.subtitle": row(
        "Et diskret puf, når et kursus virkelig er din tid værd. Aldrig andet.",
        "Et diskret dytt når et kurs virkelig er tiden din verdt. Aldri noe annet.",
        "Тихое напоминание, когда курс действительно стоит твоего времени. И больше ничего.",
        "Diskretan podsjetnik kad tečaj stvarno vrijedi tvog vremena. Ništa drugo."),
    "onboardingV2.notifications.bullet1": row(
        "Et kursus valgt til din profil", "Et kurs valgt ut til profilen din",
        "Курс, подобранный под твой профиль", "Tečaj odabran za tvoj profil"),
    "onboardingV2.notifications.bullet2": row(
        "På det rigtige tidspunkt, aldrig i stimer",
        "Til rett tid, aldri i bulk",
        "В нужный момент и никогда пачками",
        "U pravom trenutku, nikad u nizu"),
    "onboardingV2.notifications.bullet3": row(
        "Slås fra med ét tryk", "Slås av med ett trykk", "Отключается одним касанием",
        "Isključuje se jednim dodirom"),
    "onboardingV2.notifications.cta": row(
        "Slå notifikationer til", "Slå på varsler", "Включить уведомления",
        "Uključi obavijesti"),
    "onboardingV2.notifications.skip": row(
        "Senere", "Senere", "Позже", "Kasnije"),
    "notification.courseNudge.title": row(
        "Værd at se i dag", "Verdt et blikk i dag", "Стоит взглянуть сегодня",
        "Vrijedi pogledati danas"),
    "notification.courseNudge.body": row(
        "Opdag »%@« — fem minutter er nok.",
        "Oppdag «%@» — fem minutter holder.",
        "Открой «%@» — хватит пяти минут.",
        "Otkrij „%@” — dovoljno je pet minuta."),
    "notification.courseNudge.bodyFallback": row(
        "Et nyt kursus venter — fem minutter er nok.",
        "Et nytt kurs venter — fem minutter holder.",
        "Тебя ждёт новый курс — хватит пяти минут.",
        "Čeka te novi tečaj — dovoljno je pet minuta."),
    "trial.endingSoon.banner": row(
        "Om 1 dag mister du adgangen til Sophia Premium.",
        "Om 1 dag mister du tilgangen til Sophia Premium.",
        "Через 1 день ты потеряешь доступ к Sophia Premium.",
        "Za 1 dan gubiš pristup Sophia Premiumu."),
    "onboardingV2.pw.tryFree": row(
        "Prøv 3 dage gratis,", "Prøv 3 dager gratis,", "Попробуй 3 дня бесплатно,",
        "Isprobaj 3 dana besplatno,"),
    "onboardingV2.pw.thenPrice": row(
        "derefter %@ (faktureres årligt med %@).",
        "deretter %@ (faktureres årlig med %@).",
        "затем %@ (списание раз в год, %@).",
        "zatim %@ (naplata jednom godišnje, %@)."),
    "onboardingV2.pw.priceNoTrial": row(
        "Premium til %@ (faktureres årligt med %@).",
        "Premium til %@ (faktureres årlig med %@).",
        "Premium за %@ (списание раз в год, %@).",
        "Premium za %@ (naplata jednom godišnje, %@)."),
    "onboardingV2.pw.viewAllPlans": row(
        "Se alle abonnementer", "Se alle abonnementer", "Все тарифы", "Svi paketi"),
    "onboardingV2.pw.twoTaps": row(
        "To tryk for at starte, nemt at opsige.",
        "To trykk for å starte, enkelt å si opp.",
        "Два касания, чтобы начать, и отмена в пару секунд.",
        "Dva dodira za početak, otkazivanje je jednostavno."),
    "onboardingV2.pw.startTrial": row(
        "Start mine 3 gratis dage", "Start de 3 gratis dagene",
        "Начать 3 бесплатных дня", "Pokreni 3 besplatna dana"),
    "onboardingV2.pw.subscribe": row(
        "Abonnér nu", "Abonner nå", "Оформить подписку", "Pretplati se"),
    "onboardingV2.pw.compare.title": row(
        "Pro-abonnenter lærer mere, hurtigere",
        "Pro-abonnenter lærer mer, raskere",
        "Подписчики Pro учат больше и быстрее",
        "Pro pretplatnici uče više i brže"),
    "onboardingV2.pw.free": row("Gratis", "Gratis", "Бесплатно", "Besplatno"),
    "onboardingV2.pw.yearly": row("Årligt", "Årlig", "Год", "Godišnje"),
    "onboardingV2.pw.monthly": row("Månedligt", "Månedlig", "Месяц", "Mjesečno"),
    "onboardingV2.pw.monthlyBilling": row(
        "faktureres hver måned", "faktureres hver måned", "списание каждый месяц",
        "naplata svaki mjesec"),
    "onboardingV2.pw.trialBadge": row(
        "3 dage gratis", "3 dager gratis", "3 дня бесплатно", "3 dana besplatno"),
    "onboardingV2.pw.save": row("Spar %@", "Spar %@", "Экономия %@", "Ušteda %@"),
    "onboardingV2.pw.feature.allSubjects": row(
        "Alle emner", "Alle emner", "Все темы", "Sve teme"),
    "onboardingV2.pw.feature.unlimited": row(
        "Ubegrænsede kurser", "Ubegrensede kurs", "Безлимитные курсы",
        "Neograničeni tečajevi"),
    "onboardingV2.pw.feature.quiz": row(
        "Quiz og repetition", "Quiz og repetisjon", "Тесты и повторение",
        "Kvizovi i ponavljanje"),
    "onboardingV2.pw.feature.favorites": row(
        "Ubegrænsede favoritter", "Ubegrensede favoritter", "Безлимитное избранное",
        "Neograničeni favoriti"),
    "onboardingV2.pw.feature.noAds": row(
        "Ingen reklamer", "Ingen annonser", "Без рекламы", "Bez reklama"),
    "onboardingV2.pw.feature.weekly": row(
        "Nyt indhold hver uge", "Nytt innhold hver uke", "Новый контент каждую неделю",
        "Novi sadržaj svaki tjedan"),
})

# --- onboarding V2: welcome, language, objectives -------------------------
STRINGS.update({
    "onboardingV2.welcome.title": row(
        "Velkommen til Sophia", "Velkommen til Sophia", "Добро пожаловать в Sophia",
        "Dobro došao u Sophiju"),
    "onboardingV2.welcome.subtitle": row(
        "Bliv lidt klogere hver dag.", "Bli litt smartere hver dag.",
        "Становись чуть умнее каждый день.", "Postani malo pametniji svaki dan."),
    "onboardingV2.welcome.cta": row("Kom i gang", "Kom i gang", "Начать", "Kreni"),
    "onboardingV2.language.title": row(
        "Vælg dit sprog", "Velg språket ditt", "Выбери язык", "Odaberi jezik"),
    "onboardingV2.language.subtitle": row(
        "Swipe for at se alle sprog. Du kan ændre det senere.",
        "Sveip for å se alle språk. Du kan endre det senere.",
        "Листай, чтобы увидеть все языки. Поменять можно позже.",
        "Povuci da vidiš sve jezike. Možeš ga promijeniti kasnije."),
    "onboardingV2.language.scrollHint": row(
        "Swipe for at se flere sprog", "Sveip for å se flere språk",
        "Листай, чтобы увидеть больше языков", "Povuci za još jezika"),
    "onboardingV2.objective.title": row(
        "Hvad er dine mål?", "Hva er målene dine?", "Какие у тебя цели?",
        "Koji su tvoji ciljevi?"),
    "onboardingV2.objective.subtitle": row(
        "Du kan vælge flere.", "Du kan velge flere.", "Можно выбрать несколько.",
        "Možeš odabrati više njih."),
    "onboardingV2.objective.cultivate": row(
        "Lære noget nyt hver dag", "Lære noe nytt hver dag", "Узнавать новое каждый день",
        "Svaki dan naučiti nešto"),
    "onboardingV2.objective.reduceScreen": row(
        "Skære ned på skærmtiden", "Kutte ned på skjermtiden",
        "Сократить время в телефоне", "Smanjiti vrijeme pred ekranom"),
    "onboardingV2.objective.exams": row(
        "Klare studier og eksamener", "Klare studier og eksamener",
        "Хорошо учиться и сдавать экзамены", "Uspjeti u studiju i na ispitima"),
    "onboardingV2.objective.impress": row(
        "Glimre i en samtale", "Glimre i en samtale", "Блистать в разговоре",
        "Zablistati u razgovoru"),
    "onboardingV2.objective.curiosity": row(
        "Lære af ren nysgerrighed", "Lære av ren nysgjerrighet",
        "Учиться из любопытства", "Učiti iz radoznalosti"),
    "onboardingV2.objectiveIntro.title": row(
        "Sophia hjælper dig med at nå alle dine mål",
        "Sophia hjelper deg å nå alle målene dine",
        "Sophia поможет тебе достичь всех целей",
        "Sophia ti pomaže ostvariti sve ciljeve"),
    "onboardingV2.tapToContinue": row(
        "Tryk hvor som helst for at fortsætte",
        "Trykk hvor som helst for å fortsette",
        "Нажми в любом месте, чтобы продолжить",
        "Dodirni bilo gdje za nastavak"),
    "onboardingV2.questions.title": row(
        "Med Sophia kan du svare på de her spørgsmål:",
        "Med Sophia kan du svare på disse spørsmålene:",
        "С Sophia ты сможешь ответить на эти вопросы:",
        "Uz Sophiju ćeš znati odgovoriti na ova pitanja:"),
})

# --- settings -------------------------------------------------------------
STRINGS.update({
    "settings.title": row("Indstillinger", "Innstillinger", "Настройки", "Postavke"),
    "settings.section.progress": row("Fremgang", "Fremgang", "Прогресс", "Napredak"),
    "settings.section.premium": row("Premium", "Premium", "Premium", "Premium"),
    "settings.section.data": row("Data", "Data", "Данные", "Podaci"),
    "settings.section.help": row("Hjælp", "Hjelp", "Помощь", "Pomoć"),
    "settings.section.legal": row("Juridisk", "Juridisk", "Правовая информация", "Pravno"),
    "settings.section.about": row("Om appen", "Om appen", "О приложении", "O aplikaciji"),
    "settings.section.developer": row(
        "Udvikler", "Utvikler", "Разработчик", "Razvojni način"),
    "settings.section.appearance": row("Udseende", "Utseende", "Оформление", "Izgled"),
    "settings.appearance.light": row("Lys", "Lys", "Светлая", "Svijetlo"),
    "settings.appearance.dark": row("Nat", "Natt", "Ночная", "Noćno"),
    "settings.appearance.automatic": row(
        "Automatisk", "Automatisk", "Автоматически", "Automatski"),
    "settings.appearance.hint": row(
        "Automatisk følger telefonens indstilling.",
        "Automatisk følger innstillingen på telefonen.",
        "Автоматически — как в настройках телефона.",
        "Automatski prati postavku telefona."),
    "settings.courses.completed": row(
        "%d kurser gennemført", "%d kurs fullført", "%d курсов пройдено",
        "%d tečajeva završeno"),
    "settings.courses.available": row(
        "ud af %d mulige", "av %d tilgjengelige", "из %d доступных",
        "od %d dostupnih"),
    "settings.streak.title": row(
        "%d dage i træk", "%d dager på rad", "%d дней подряд", "%d dana zaredom"),
    "settings.streak.subtitle": row(
        "Bliv ved!", "Fortsett sånn!", "Так держать!", "Samo tako nastavi!"),
    "settings.premium.title": row(
        "Skift til Premium", "Bytt til Premium", "Перейти на Premium",
        "Prijeđi na Premium"),
    "settings.premium.subtitle": row(
        "Ubegrænsede kurser og quizzer", "Ubegrensede kurs og quizer",
        "Безлимитные курсы и тесты", "Neograničeni tečajevi i kvizovi"),
    "settings.reset.title": row(
        "Nulstil fremgang", "Nullstill fremgang", "Сбросить прогресс",
        "Poništi napredak"),
    "settings.feedback.title": row(
        "Send feedback", "Send tilbakemelding", "Отправить отзыв",
        "Pošalji povratnu informaciju"),
    "settings.feedback.subtitle": row(
        "Fejl, idé eller forslag til indhold",
        "Feil, idé eller forslag til innhold",
        "Ошибка, идея или предложение по контенту",
        "Greška, ideja ili prijedlog sadržaja"),
    "settings.ambassador.banner.badge": row(
        "Gratis Premium", "Gratis Premium", "Premium бесплатно", "Premium besplatno"),
    "settings.ambassador.banner.title": row(
        "Bliv ambassadør", "Bli ambassadør", "Стань амбассадором", "Postani ambasador"),
    "settings.ambassador.banner.subtitle": row(
        "Tjen penge på at poste Sophia på TikTok",
        "Tjen penger på å poste Sophia på TikTok",
        "Зарабатывай, публикуя Sophia в TikTok",
        "Zaradi objavljujući Sophiju na TikToku"),
    "settings.terms.title": row(
        "Betingelser", "Vilkår", "Условия использования", "Uvjeti korištenja"),
    "settings.privacy.title": row(
        "Privatlivspolitik", "Personvernerklæring", "Политика конфиденциальности",
        "Pravila privatnosti"),
    "settings.restore.title": row(
        "Gendan køb", "Gjenopprett kjøp", "Восстановить покупки", "Vrati kupnje"),
    "settings.about.version": row("Version", "Versjon", "Версия", "Verzija"),
    "settings.about.courses": row(
        "Tilgængelige kurser", "Tilgjengelige kurs", "Доступные курсы",
        "Dostupni tečajevi"),
    "settings.debug.resetOnboarding": row(
        "Kør onboarding forfra", "Kjør onboarding på nytt", "Пройти онбординг заново",
        "Ponovi onboarding"),
    "settings.debug.resetDaily": row(
        "Nulstil dagens kursus", "Nullstill dagens kurs", "Сбросить курс дня",
        "Poništi dnevni tečaj"),
    "settings.debug.daily.done": row(
        "Klaret i dag", "Gjort i dag", "Сегодня пройден", "Odrađeno danas"),
    "settings.debug.daily.pending": row(
        "Ikke klaret endnu", "Ikke gjort ennå", "Ещё не пройден", "Još nije odrađeno"),
    "settings.footer": row(
        "Lavet med ♥ — Sophia", "Laget med ♥ — Sophia", "Сделано с ♥ — Sophia",
        "Napravljeno s ♥ — Sophia"),
    "settings.reset.alert.title": row(
        "Nulstille?", "Nullstille?", "Сбросить?", "Poništiti?"),
    "settings.reset.alert.cancel": row("Annuller", "Avbryt", "Отмена", "Odustani"),
    "settings.reset.alert.confirm": row(
        "Nulstil", "Nullstill", "Сбросить", "Poništi"),
    "settings.reset.alert.message": row(
        "Hele din fremgang bliver slettet. Det kan ikke fortrydes.",
        "Hele fremgangen din blir slettet. Det kan ikke angres.",
        "Весь твой прогресс будет удалён. Это необратимо.",
        "Cijeli tvoj napredak bit će izbrisan. To se ne može poništiti."),
    "settings.onboarding.alert.title": row(
        "Køre onboarding forfra?", "Kjøre onboarding på nytt?",
        "Пройти онбординг заново?", "Ponoviti onboarding?"),
    "settings.onboarding.alert.confirm": row(
        "Kør igen", "Kjør på nytt", "Заново", "Ponovi"),
    "settings.onboarding.alert.message": row(
        "Onboarding starter forfra (kun DEBUG).",
        "Onboarding starter på nytt (kun DEBUG).",
        "Онбординг начнётся с начала (только DEBUG).",
        "Onboarding kreće ispočetka (samo DEBUG)."),
})

# --- feedback + ambassador + legal ---------------------------------------
STRINGS.update({
    "feedback.title": row(
        "Din feedback", "Tilbakemeldingen din", "Твой отзыв", "Tvoja povratna informacija"),
    "feedback.subtitle": row(
        "Vi læser alt. Fortæl os, hvad du kan lide, hvad der driller, eller hvad der mangler.",
        "Vi leser alt. Si fra om hva du liker, hva som skurrer, eller hva som mangler.",
        "Мы читаем всё. Расскажи, что нравится, что не работает и чего не хватает.",
        "Čitamo sve. Reci nam što ti se sviđa, što ne radi ili što nedostaje."),
    "feedback.category.label": row("Kategori", "Kategori", "Категория", "Kategorija"),
    "feedback.category.bug": row("Fejl", "Feil", "Ошибка", "Greška"),
    "feedback.category.idea": row("Idé", "Idé", "Идея", "Ideja"),
    "feedback.category.content": row("Indhold", "Innhold", "Контент", "Sadržaj"),
    "feedback.category.other": row("Andet", "Annet", "Другое", "Ostalo"),
    "feedback.message.label": row("Besked", "Melding", "Сообщение", "Poruka"),
    "feedback.message.placeholder": row(
        "Beskriv det med et par sætninger…", "Beskriv det med et par setninger…",
        "Опиши в паре предложений…", "Opiši u par rečenica…"),
    "feedback.email.label": row(
        "E-mail (valgfri)", "E-post (valgfritt)", "Эл. почта (необязательно)",
        "E-mail (neobavezno)"),
    "feedback.email.placeholder": row(
        "Så vi kan svare dig", "Så vi kan svare deg", "Чтобы мы могли ответить",
        "Da ti možemo odgovoriti"),
    "feedback.technicalNote": row(
        "Appversion, sprog og enhedsmodel vedhæftes automatisk, så vi kan hjælpe.",
        "Appversjon, språk og enhetsmodell legges ved automatisk, så vi kan hjelpe.",
        "Версия приложения, язык и модель устройства прикрепляются автоматически — так нам проще помочь.",
        "Verzija aplikacije, jezik i model uređaja prilažu se automatski kako bismo ti lakše pomogli."),
    "feedback.submit": row("Send", "Send", "Отправить", "Pošalji"),
    "feedback.error.generic": row(
        "Kunne ikke sendes lige nu. Prøv igen senere.",
        "Kunne ikke sendes akkurat nå. Prøv igjen senere.",
        "Сейчас не отправилось. Попробуй позже.",
        "Trenutno se ne može poslati. Pokušaj kasnije."),
    "feedback.success.title": row("Tak!", "Takk!", "Спасибо!", "Hvala!"),
    "feedback.success.body": row(
        "Din besked er sendt. Vi læser den grundigt.",
        "Meldingen din er sendt. Vi leser den grundig.",
        "Твоё сообщение отправлено. Мы внимательно его прочитаем.",
        "Tvoja poruka je poslana. Pažljivo ćemo je pročitati."),
    "feedback.success.close": row("Luk", "Lukk", "Закрыть", "Zatvori"),
    "ambassador.title": row("Ambassadør", "Ambassadør", "Амбассадор", "Ambasador"),
    "ambassador.step.program": row("Programmet", "Programmet", "Программа", "Program"),
    "ambassador.step.apply": row("Ansøgning", "Søknad", "Заявка", "Prijava"),
    "ambassador.program.heading": row(
        "Bliv Sophia-ambassadør", "Bli Sophia-ambassadør", "Стань амбассадором Sophia",
        "Postani Sophia ambasador"),
    "ambassador.how.title": row(
        "Sådan virker det", "Slik fungerer det", "Как это работает", "Kako to radi"),
    "ambassador.how.step1": row(
        "Du ansøger her på 1 minut.", "Du søker her på 1 minutt.",
        "Ты подаёшь заявку прямо здесь за 1 минуту.",
        "Prijaviš se ovdje u 1 minuti."),
    "ambassador.how.step2": row(
        "Vi leverer indhold, eksempler og coaching.",
        "Vi leverer innhold, eksempler og coaching.",
        "Мы даём контент, примеры и поддержку.",
        "Mi dajemo sadržaj, primjere i coaching."),
    "ambassador.how.step3": row(
        "Du poster på TikTok og får betaling.",
        "Du poster på TikTok og får betalt.",
        "Ты публикуешь в TikTok и получаешь оплату.",
        "Ti objavljuješ na TikToku i dobivaš plaćeno."),
    "ambassador.roles.title": row(
        "To måder at være med på", "To måter å være med på",
        "Два способа участвовать", "Dva načina sudjelovanja"),
    "ambassador.stat.income": row("Indtægt", "Inntekt", "Доход", "Zarada"),
    "ambassador.stat.time": row("Tid", "Tid", "Время", "Vrijeme"),
    "ambassador.discover.cta": row(
        "Jeg ansøger", "Jeg søker", "Хочу участвовать", "Prijavljujem se"),
    "ambassador.intro": row(
        "Vær med i Sophias ambassadørprogram: du poster indhold på TikTok. Vi leverer opslagene, eksemplerne og coachingen. Du udgiver og får betaling.",
        "Bli med i Sophias ambassadørprogram: du poster innhold på TikTok. Vi leverer innleggene, eksemplene og coachingen. Du publiserer og får betalt.",
        "Присоединяйся к программе амбассадоров Sophia: ты публикуешь контент в TikTok. Мы даём посты, примеры и поддержку. Ты публикуешь и получаешь оплату.",
        "Uključi se u Sophia ambasadorski program: objavljuješ sadržaj na TikToku. Mi dajemo objave, primjere i coaching. Ti objavljuješ i dobivaš plaćeno."),
    "ambassador.cta48h": row(
        "Vi vender tilbage inden for 48 timer. Vær med i netværket!",
        "Vi svarer innen 48 timer. Bli med i nettverket!",
        "Ответим в течение 48 часов. Присоединяйся к сети!",
        "Javimo se u roku od 48 sati. Pridruži se mreži!"),
    "ambassador.bonus": row(
        "Bonus: gratis Sophia Premium i hele programmet",
        "Bonus: gratis Sophia Premium gjennom hele programmet",
        "Бонус: бесплатный Sophia Premium на время программы",
        "Bonus: besplatni Sophia Premium tijekom programa"),
    "ambassador.role.slideshow.title": row(
        "Slideshow-skaber", "Slideshow-skaper", "Автор слайдшоу", "Autor slideshowa"),
    "ambassador.role.slideshow.income": row(
        "30-100 € / md.", "30-100 € / mnd", "30-100 € / мес.", "30-100 € / mj."),
    "ambassador.role.slideshow.time": row(
        "1-2 t / md.", "1-2 t / mnd", "1-2 ч / мес.", "1-2 h / mj."),
    "ambassador.role.slideshow.body": row(
        "Vi leverer færdige TikTok-slideshows. Du udgiver dem, vi bakker dig op.",
        "Vi leverer ferdige TikTok-slideshow. Du publiserer dem, vi støtter deg.",
        "Мы даём готовые слайдшоу для TikTok. Ты публикуешь, мы поддерживаем.",
        "Mi dajemo gotove TikTok slideshowe. Ti ih objavljuješ, mi te podržavamo."),
    "ambassador.role.ugc.title": row(
        "UGC-skaber", "UGC-skaper", "UGC-автор", "UGC autor"),
    "ambassador.role.ugc.income": row(
        "50-1000 € / md.", "50-1000 € / mnd", "50-1000 € / мес.", "50-1000 € / mj."),
    "ambassador.role.ugc.time": row(
        "2-10 t / md.", "2-10 t / mnd", "2-10 ч / мес.", "2-10 h / mj."),
    "ambassador.role.ugc.body": row(
        "Du laver TikTok-opslag. Indtægten følger visningerne. Vi giver dig UGC-eksempler og coaching.",
        "Du lager TikTok-innlegg. Inntekten følger visningene. Vi gir deg UGC-eksempler og coaching.",
        "Ты снимаешь посты для TikTok. Доход зависит от просмотров. Мы даём примеры UGC и поддержку.",
        "Ti radiš TikTok objave. Zarada ovisi o pregledima. Dajemo ti UGC primjere i coaching."),
    "ambassador.conditions.title": row("Krav", "Krav", "Требования", "Uvjeti"),
    "ambassador.conditions.countries": row(
        "Bo i Frankrig, Canada, Belgien eller Schweiz",
        "Bo i Frankrike, Canada, Belgia eller Sveits",
        "Жить во Франции, Канаде, Бельгии или Швейцарии",
        "Živjeti u Francuskoj, Kanadi, Belgiji ili Švicarskoj"),
    "ambassador.conditions.age": row(
        "Være 16 år eller derover", "Være 16 år eller eldre", "Быть от 16 лет",
        "Imati 16 ili više godina"),
    "ambassador.form.title": row("Ansøgning", "Søknad", "Заявка", "Prijava"),
    "ambassador.form.roles.label": row(
        "Du ansøger som", "Du søker som", "Ты подаёшь заявку на", "Prijavljuješ se za"),
    "ambassador.form.role.slideshow": row(
        "Slideshow-skaber", "Slideshow-skaper", "Автор слайдшоу", "Autor slideshowa"),
    "ambassador.form.role.ugc": row(
        "UGC-skaber", "UGC-skaper", "UGC-автор", "UGC autor"),
    "ambassador.form.email.label": row("E-mail", "E-post", "Эл. почта", "E-mail"),
    "ambassador.form.email.placeholder": row(
        "dig@email.com", "deg@email.com", "ты@email.com", "ti@email.com"),
    "ambassador.form.age.label": row("Alder", "Alder", "Возраст", "Dob"),
    "ambassador.form.age.placeholder": row(
        "f.eks. 22", "f.eks. 22", "напр. 22", "npr. 22"),
    "ambassador.form.presentation.label": row(
        "Kort præsentation", "Kort presentasjon", "Коротко о себе", "Kratko o sebi"),
    "ambassador.form.presentation.placeholder": row(
        "Hvad kan du lide at lave? Almen viden, indholdsproduktion…",
        "Hva liker du å gjøre? Allmennkunnskap, innholdsproduksjon…",
        "Чем тебе нравится заниматься? Общие знания, создание контента…",
        "Što voliš raditi? Opća kultura, stvaranje sadržaja…"),
    "ambassador.form.presentation.hint": row(
        "%d/%d tegn min.", "%d/%d tegn min.", "%d/%d символов мин.",
        "%d/%d znakova min."),
    "ambassador.form.country.confirm": row(
        "Jeg bekræfter, at jeg bor i Frankrig, Canada, Belgien eller Schweiz",
        "Jeg bekrefter at jeg bor i Frankrike, Canada, Belgia eller Sveits",
        "Подтверждаю, что живу во Франции, Канаде, Бельгии или Швейцарии",
        "Potvrđujem da živim u Francuskoj, Kanadi, Belgiji ili Švicarskoj"),
    "ambassador.form.submit": row(
        "Send min ansøgning", "Send søknaden min", "Отправить заявку",
        "Pošalji prijavu"),
    "ambassador.form.hint": row(
        "Udfyld hele formularen (præsentation: mindst 10 tegn) for at kunne sende.",
        "Fyll ut hele skjemaet (presentasjon: minst 10 tegn) for å kunne sende.",
        "Заполни всю форму (о себе: минимум 10 символов), чтобы отправить.",
        "Ispuni cijeli obrazac (o sebi: najmanje 10 znakova) da bi mogao poslati."),
    "ambassador.form.error.generic": row(
        "Kunne ikke sendes lige nu. Prøv igen senere.",
        "Kunne ikke sendes akkurat nå. Prøv igjen senere.",
        "Сейчас не отправилось. Попробуй позже.",
        "Trenutno se ne može poslati. Pokušaj kasnije."),
    "ambassador.form.error.age": row(
        "Du skal være 16 år eller derover.", "Du må være 16 år eller eldre.",
        "Тебе должно быть 16 или больше.", "Moraš imati 16 ili više godina."),
    "ambassador.success.title": row(
        "Ansøgning sendt!", "Søknad sendt!", "Заявка отправлена!", "Prijava poslana!"),
    "ambassador.success.body": row(
        "Tak. Vi læser din ansøgning grundigt.",
        "Takk. Vi leser søknaden din grundig.",
        "Спасибо. Мы внимательно прочитаем твою заявку.",
        "Hvala. Pažljivo ćemo pročitati tvoju prijavu."),
    "ambassador.success.close": row("Luk", "Lukk", "Закрыть", "Zatvori"),
    "legal.terms.title": row("Betingelser", "Vilkår", "Условия", "Uvjeti"),
    "legal.privacy.title": row(
        "Privatliv", "Personvern", "Конфиденциальность", "Privatnost"),
})

# --- subjects + home + explain -------------------------------------------
STRINGS.update({
    "subject.histoire": row("Historie", "Historie", "История", "Povijest"),
    "subject.sciences": row("Videnskab", "Vitenskap", "Наука", "Znanost"),
    "subject.litterature": row("Litteratur", "Litteratur", "Литература", "Književnost"),
    "subject.art": row("Kunst", "Kunst", "Искусство", "Umjetnost"),
    "subject.mythologie": row("Mytologi", "Mytologi", "Мифология", "Mitologija"),
    "subject.comprendreLeMonde": row(
        "Forstå verden i dag", "Forstå verden i dag", "Понять современный мир",
        "Razumjeti današnji svijet"),
    "subject.histoire.short": row("Historie", "Historie", "История", "Povijest"),
    "subject.sciences.short": row("Videnskab", "Vitenskap", "Наука", "Znanost"),
    "subject.litterature.short": row(
        "Litteratur", "Litteratur", "Литература", "Književnost"),
    "subject.art.short": row("Kunst", "Kunst", "Искусство", "Umjetnost"),
    "subject.mythologie.short": row("Mytologi", "Mytologi", "Мифология", "Mitologija"),
    "subject.comprendreLeMonde.short": row(
        "Verden i dag", "Verden i dag", "Современный мир", "Današnji svijet"),
    "home.skip": row("Spring over", "Hopp over", "Пропустить", "Preskoči"),
    "home.swipe.title": row(
        "Swipe for at skifte kursus", "Sveip for å bytte kurs",
        "Листай, чтобы сменить курс", "Povuci za promjenu tečaja"),
    "home.swipe.subtitle": row(
        "Swipe til venstre eller højre for det næste",
        "Sveip til venstre eller høyre for det neste",
        "Листай влево или вправо к следующему",
        "Povuci lijevo ili desno za sljedeći"),
    "home.swipe.left": row("Swipe ←", "Sveip ←", "Листай ←", "Povuci ←"),
    "home.swipe.right": row("→ Swipe", "→ Sveip", "→ Листай", "→ Povuci"),
    "course.reads": row("%@ læsninger", "%@ lesninger", "%@ прочтений", "%@ čitanja"),
    "explain.tapToClose": row(
        "Tryk for at fortsætte", "Trykk for å fortsette", "Нажми, чтобы продолжить",
        "Dodirni za nastavak"),
    "explain.home.title": row(
        "Lodret swipe", "Loddrett sveip", "Вертикальный свайп",
        "Okomito povlačenje"),
    "explain.home.body": row(
        "Swipe op for det næste kursus, ned for at gå tilbage til det forrige.",
        "Sveip opp for neste kurs, ned for å gå tilbake til det forrige.",
        "Листай вверх — следующий курс, вниз — предыдущий.",
        "Povuci gore za sljedeći tečaj, dolje za prethodni."),
    "explain.course.title": row(
        "Tryk på ordene", "Trykk på ordene", "Нажимай на слова", "Dodirni riječi"),
    "explain.course.body": row(
        "Fremhævede ord gemmer på en forklaring: tryk på dem for at forstå det hele.",
        "Uthevede ord skjuler en forklaring: trykk på dem for å forstå alt.",
        "За выделенными словами прячется определение: нажми, чтобы понять всё.",
        "Istaknuti pojmovi kriju definiciju: dodirni ih da sve razumiješ."),
    "explain.course.termBody": row(
        "Ligesom »%@« gemmer understregede ord på en forklaring. Tryk for at se den.",
        "Som «%@» skjuler understrekede ord en forklaring. Trykk for å se den.",
        "Как и «%@», подчёркнутые слова скрывают определение. Нажми, чтобы увидеть.",
        "Kao i „%@”, podcrtane riječi kriju definiciju. Dodirni da je vidiš."),
    "explain.collections.title": row(
        "Samlingerne", "Samlingene", "Подборки", "Zbirke"),
    "explain.collections.body": row(
        "Hver samling samler kurser om samme tema, så du rykker skridt for skridt.",
        "Hver samling samler kurs om samme tema, så du rykker steg for steg.",
        "Каждая подборка собирает курсы на одну тему, чтобы ты шёл шаг за шагом.",
        "Svaka zbirka okuplja tečajeve iste teme da napreduješ korak po korak."),
    "explain.training.title": row(
        "Repetition", "Repetisjon", "Повторение", "Ponavljanje"),
    "explain.training.body": row(
        "Repeter spørgsmål, du allerede har set, på det rigtige tidspunkt, så de sætter sig.",
        "Repeter spørsmål du allerede har sett, til rett tid, så de sitter.",
        "Повторяй уже знакомые вопросы в нужный момент, чтобы они закрепились.",
        "Ponavljaj već viđena pitanja u pravom trenutku da ti ostanu."),
})

# --- home, library chrome, collections, counters -------------------------
# Russian has no safe generic plural after a bare numeral ("1 курсов" is
# wrong), so standalone count badges use the idiomatic "label: value" form and
# only x/y stat strips keep the genitive-plural shortcut.
STRINGS.update({
    "home.bravo": row("Bravo!", "Bravo!", "Браво!", "Bravo!"),
    "home.allCompleted": row(
        "Du har taget alle tilgængelige kurser.",
        "Du har tatt alle tilgjengelige kurs.",
        "Ты прошёл все доступные курсы.",
        "Prošao si sve dostupne tečajeve."),
    "discount.gift.title": row(
        "En overraskelse til dig!", "En overraskelse til deg!", "Сюрприз для тебя!",
        "Iznenađenje za tebe!"),
    "discount.gift.tapToOpen": row(
        "Tryk for at åbne den", "Trykk for å åpne den", "Нажми, чтобы открыть",
        "Dodirni da otvoriš"),
    "discount.gift.keepTapping": row(
        "Bliv ved med at trykke!", "Fortsett å trykke!", "Жми ещё!",
        "Nastavi dodirivati!"),
    "discount.gift.almost": row("Næsten!", "Nesten!", "Почти!", "Skoro!"),
    "home.locked": row("Låst", "Låst", "Закрыто", "Zaključano"),
    "home.start": row("Start", "Start", "Начать", "Počni"),
    "library.empty.title": row(
        "Ingen resultater", "Ingen treff", "Ничего не найдено", "Nema rezultata"),
    "library.empty.subtitle": row(
        "Prøv et andet søgeord.", "Prøv et annet søkeord.", "Попробуй другое слово.",
        "Probaj drugu ključnu riječ."),
    "library.seeMore": row("Se mere", "Se mer", "Показать ещё", "Prikaži više"),
    "library.section.featured": row(
        "Fremhævet", "Fremhevet", "Рекомендуем", "Izdvojeno"),
    "library.featured.badge": row(
        "Fremhævet", "Fremhevet", "Рекомендуем", "Izdvojeno"),
    "collections.featured": row(
        "Fremhævet", "Fremhevet", "Рекомендуем", "Izdvojeno"),
    "library.section.continue": row(
        "Fortsæt med at lære", "Fortsett å lære", "Продолжай учиться",
        "Nastavi učiti"),
    "library.section.recommended": row(
        "Anbefalet til dig", "Anbefalt til deg", "Рекомендовано тебе",
        "Preporučeno za tebe"),
    "library.unlock": row("Lås op", "Lås opp", "Открыть", "Otključaj"),
    "library.lockedBadge": row("LÅST", "LÅST", "ЗАКРЫТО", "ZAKLJUČANO"),
    "collections.title": row("SAMLINGER", "SAMLINGER", "ПОДБОРКИ", "ZBIRKE"),
    "collections.subtitle": row(
        "Guidede forløb, der binder idéerne sammen.",
        "Guidede løyper som binder ideene sammen.",
        "Ведомые маршруты, которые связывают идеи.",
        "Vođene putanje koje povezuju ideje."),
    "collections.complete": row(
        "Samling gennemført", "Samling fullført", "Подборка пройдена",
        "Zbirka završena"),
    "collections.progress": row(
        "%d / %d kurser gennemført", "%d / %d kurs fullført",
        "Пройдено: %d / %d", "Završeno: %d / %d"),
    "collections.badge.complete": row(
        "GENNEMFØRT", "FULLFØRT", "ЗАВЕРШЕНО", "ZAVRŠENO"),
    "collections.badge.path": row("FORLØB", "LØYPE", "МАРШРУТ", "PUTANJA"),
    "collections.xpAtEnd": row(
        "+%d XP til sidst", "+%d XP til slutt", "+%d XP в конце", "+%d XP na kraju"),
    "collections.pathComplete": row(
        "Forløb gennemført", "Løypa er fullført", "Маршрут пройден",
        "Putanja završena"),
    "collections.path": row(
        "Dit forløb", "Løypa di", "Твой маршрут", "Tvoja putanja"),
    "collections.reward": row(
        "Endelig belønning", "Endelig belønning", "Финальная награда",
        "Konačna nagrada"),
    "subject.courses.count": row(
        "%d kurser", "%d kurs", "Курсов: %d", "%d tečajeva"),
    "subject.completed.singular": row(
        "%d gennemført", "%d fullført", "Пройдено: %d", "Završeno: %d"),
    "subject.completed.plural": row(
        "%d gennemført", "%d fullført", "Пройдено: %d", "Završeno: %d"),
    "subject.level": row("NIVEAU %d", "NIVÅ %d", "УРОВЕНЬ %d", "RAZINA %d"),
    "subject.progress.stats": row(
        "%d XP · %d/%d kurser", "%d XP · %d/%d kurs", "%d XP · %d/%d курсов",
        "%d XP · %d/%d tečajeva"),
    "subject.next": row("Næste", "Neste", "Далее", "Sljedeće"),
    "subject.filter.empty": row(
        "Ingen kurser her endnu.", "Ingen kurs her ennå.", "Здесь пока нет курсов.",
        "Ovdje još nema tečajeva."),
    "library.filter.all": row("Alle", "Alle", "Все", "Sve"),
    "library.filter.todo": row("Mangler", "Gjenstår", "Предстоит", "Za odraditi"),
    "library.filter.inProgress": row("I gang", "I gang", "В процессе", "U tijeku"),
    "library.filter.done": row("Gennemført", "Fullført", "Пройдено", "Završeno"),
    "library.filter.favorites": row(
        "Favoritter", "Favoritter", "Избранное", "Favoriti"),
    "library.status.done": row("GENNEMFØRT", "FULLFØRT", "ПРОЙДЕНО", "ZAVRŠENO"),
    "library.status.inProgress": row("I GANG", "I GANG", "В ПРОЦЕССЕ", "U TIJEKU"),
    "favorites.badge.count": row(
        "%d KURSER", "%d KURS", "КУРСОВ: %d", "%d TEČAJEVA"),
    "favorites.empty.title": row(
        "Ingen favoritter", "Ingen favoritter", "Нет избранного", "Nema favorita"),
    "favorites.empty.subtitle": row(
        "Tryk på hjertet ved et kursus,\nså finder du det her.",
        "Trykk på hjertet ved et kurs,\nså finner du det her.",
        "Нажми на сердечко у курса,\nи найдёшь его здесь.",
        "Dodirni srce na tečaju\ni naći ćeš ga ovdje."),
    "course.funFact": row(
        "VIDSTE DU DET?", "VISSTE DU DET?", "А ТЫ ЗНАЛ?", "JESI LI ZNAO?"),
    "paywall.error.unavailable": row(
        "Tilbuddet kunne ikke hentes", "Tilbudet kunne ikke lastes",
        "Не удалось загрузить предложение", "Ponudu nije moguće učitati"),
    "paywall.error.retry": row("Prøv igen", "Prøv igjen", "Ещё раз", "Pokušaj opet"),
    "cards.successRate": row(
        "korrekte svar", "riktige svar", "верных ответов", "točnih odgovora"),
    "cards.globalXP": row(
        "+%d XP i alt", "+%d XP totalt", "+%d XP всего", "+%d XP ukupno"),
    "course.keyTakeaway": row(
        "HUSK DET HER", "HUSK DETTE", "ЗАПОМНИ", "ZAPAMTI"),
    "celebration.collectionAdvanced": row(
        "Videre i samlingen!", "Videre i samlingen!", "Продвинулся в подборке!",
        "Napredak u zbirci!"),
    "celebration.coursesCompleted": row(
        "kurser gennemført", "kurs fullført", "курсов пройдено", "završenih tečajeva"),
    "celebration.collectionComplete": row(
        "Samlingen er gennemført!", "Samlingen er fullført!", "Подборка пройдена!",
        "Zbirka je završena!"),
})

# --- common chrome --------------------------------------------------------
STRINGS.update({
    "common.continue": row("Fortsæt", "Fortsett", "Дальше", "Nastavi"),
    "common.next": row("Næste", "Neste", "Далее", "Dalje"),
    "common.letsGo": row("Så kører vi!", "Da kjører vi!", "Поехали!", "Idemo!"),
    "common.letsGoShort": row("Så kører vi", "Da kjører vi", "Поехали", "Idemo"),
    "common.close": row("Luk", "Lukk", "Закрыть", "Zatvori"),
    "common.processing": row("Et øjeblik…", "Et øyeblikk…", "Секунду…", "Trenutak…"),
    "common.startLearning": row(
        "Begynd at lære", "Begynn å lære", "Начать учиться", "Počni učiti"),
    "common.backHome": row(
        "Tilbage til start", "Tilbake til start", "На главную", "Natrag na početnu"),
    "common.retryQuiz": row(
        "Tag quizzen igen", "Ta quizen på nytt", "Пройти тест снова",
        "Ponovi kviz"),
    "common.seeMoreArrow": row("Se mere →", "Se mer →", "Показать ещё →", "Više →"),
    "common.streak.day": row("DAG", "DAG", "ДЕНЬ", "DAN"),
    "common.streak.days": row("DAGE", "DAGER", "ДНИ", "DANA"),
    "common.levelShort": row("NIV. %d", "NIVÅ %d", "УР. %d", "RAZ. %d"),
    "common.increaseGoal": row(
        "Hæv målet", "Hev målet", "Увеличить цель", "Povećaj cilj"),
    "common.decreaseGoal": row(
        "Sænk målet", "Senk målet", "Уменьшить цель", "Smanji cilj"),
    "common.miniQuiz": row("Mini-quiz", "Mini-quiz", "Мини-тест", "Mini kviz"),
    "common.xpEarned": row("+%d XP", "+%d XP", "+%d XP", "+%d XP"),
    "common.xpBeforeNext": row(
        "· %d til niv. %d", "· %d til nivå %d", "· %d до ур. %d",
        "· %d do raz. %d"),
})

# --- onboarding v1: welcome, phone time, wasted time, goals ----------------
# The rotating words complete "Sophia is your partner to master …", so Russian
# needs the accusative and Croatian the genitive: the fragments are written to
# fit that frame, not as standalone nouns.
STRINGS.update({
    "onboarding.welcome.title": row(
        "Sophia er din partner til at mestre",
        "Sophia er partneren din for å mestre",
        "Sophia — твой напарник, чтобы освоить",
        "Sophia je tvoj partner za svladavanje"),
    "onboarding.welcome.rotating.histoire": row(
        "historie", "historie", "историю", "povijesti"),
    "onboarding.welcome.rotating.sciences": row(
        "naturvidenskab", "naturvitenskap", "науку", "znanosti"),
    "onboarding.welcome.rotating.litterature": row(
        "litteratur", "litteratur", "литературу", "književnosti"),
    "onboarding.welcome.rotating.art": row(
        "kunst", "kunst", "искусство", "umjetnosti"),
    "onboarding.welcome.rotating.mythologie": row(
        "mytologi", "mytologi", "мифологию", "mitologije"),
    "onboarding.welcome.rotating.comprendreLeMonde": row(
        "verden i dag", "verden i dag", "современный мир", "današnjeg svijeta"),
    "onboarding.phone.title": row(
        "Hvor lang tid\nbruger du på telefonen?",
        "Hvor lang tid\nbruker du på telefonen?",
        "Сколько времени\nты проводишь в телефоне?",
        "Koliko vremena\nprovodiš na mobitelu?"),
    "onboarding.phone.subtitle": row(
        "I gennemsnit, hver dag.", "I gjennomsnitt, hver dag.",
        "В среднем за день.", "U prosjeku, svaki dan."),
    "onboarding.phone.intensity.light": row("Lidt", "Lite", "Мало", "Malo"),
    "onboarding.phone.intensity.moderate": row(
        "Moderat", "Moderat", "Средне", "Umjereno"),
    "onboarding.phone.intensity.high": row("Meget", "Mye", "Много", "Puno"),
    "onboarding.phone.intensity.intense": row(
        "Ekstremt", "Ekstremt", "Очень много", "Jako puno"),
    "onboarding.phone.lessThan1h": row(
        "Under 1 time", "Under 1 time", "Меньше 1 часа", "Manje od 1 h"),
    "onboarding.phone.1to2h": row("1–2 timer", "1–2 timer", "1–2 часа", "1 – 2 h"),
    "onboarding.phone.2to4h": row("2–4 timer", "2–4 timer", "2–4 часа", "2 – 4 h"),
    "onboarding.phone.moreThan4h": row(
        "Over 4 timer", "Over 4 timer", "Больше 4 часов", "Više od 4 h"),
    "onboarding.phone.hours.1": row("1 time", "1 time", "1 час", "1 sat"),
    "onboarding.phone.hours.2": row("2 timer", "2 timer", "2 часа", "2 sata"),
    "onboarding.phone.hours.3": row("3 timer", "3 timer", "3 часа", "3 sata"),
    "onboarding.phone.hours.5": row("5 timer", "5 timer", "5 часов", "5 sati"),
    "onboarding.wasted.intro": row(
        "%@ om dagen på telefonen, det er",
        "%@ om dagen på telefonen, det er",
        "%@ в день в телефоне — это",
        "%@ dnevno na mobitelu — to je"),
    "onboarding.wasted.hoursLost": row(
        "spildte timer om året.", "bortkastede timer i året.",
        "потерянных часов в год.", "izgubljenih sati godišnje."),
    "onboarding.wasted.daysComplete": row(
        "Det er %@ i ét stræk.", "Det er %@ i strekk.",
        "Это %@ без перерыва.", "To je %@ bez prestanka."),
    "onboarding.wasted.transform": row(
        "Med Sophia bliver den tid til viden.",
        "Med Sophia blir den tiden til kunnskap.",
        "С Sophia это время превращается в знания.",
        "Uz Sophiju to vrijeme postaje znanje."),
    "onboarding.wasted.days.7": row("7 dage", "7 dager", "7 дней", "7 dana"),
    "onboarding.wasted.days.23": row("23 dage", "23 dager", "23 дня", "23 dana"),
    "onboarding.wasted.days.45": row("45 dage", "45 dager", "45 дней", "45 dana"),
    "onboarding.wasted.days.91": row("91 dage", "91 dager", "91 день", "91 dan"),
    "onboarding.objectives.title": row(
        "Dit mål\nmed Sophia?", "Målet ditt\nmed Sophia?", "Твоя цель\nс Sophia?",
        "Tvoj cilj\nuz Sophiju?"),
    "onboarding.objectives.subtitle": row(
        "Vælg et eller flere mål.", "Velg ett eller flere mål.",
        "Выбери одну или несколько целей.", "Odaberi jedan ili više ciljeva."),
    "onboarding.objective.curious": row(
        "Være mere nysgerrig", "Bli mer nysgjerrig", "Стать любознательнее",
        "Biti znatiželjniji"),
    "onboarding.objective.learnNew": row(
        "Lære nye ting", "Lære nye ting", "Узнавать новое", "Učiti nove stvari"),
    "onboarding.objective.impress": row(
        "Imponere dem omkring dig", "Imponere folka rundt deg",
        "Впечатлять близких", "Impresionirati one oko sebe"),
    "onboarding.objective.social": row(
        "Være mere sikker i selskab", "Være tryggere i selskap",
        "Увереннее держаться в компании", "Sigurnije se snalaziti u društvu"),
    "onboarding.objective.reduceScroll": row(
        "Scrolle mindre", "Scrolle mindre", "Меньше залипать в ленте",
        "Manje skrolati"),
    "onboarding.interests.title": row(
        "Hvilke emner\ninteresserer dig?", "Hvilke emner\ninteresserer deg?",
        "Какие темы\nтебе интересны?", "Koje te teme\nzanimaju?"),
    "onboarding.interests.subtitle": row(
        "Vælg mindst ét emne.", "Velg minst ett emne.",
        "Выбери хотя бы одну тему.", "Odaberi barem jednu temu."),
    "onboarding.dailyGoal.title": row(
        "Hver dag vil du lære…", "Hver dag vil du lære…",
        "Каждый день ты хочешь пройти…", "Svaki dan želiš odraditi…"),
    "onboarding.dailyGoal.subtitle": row(
        "Du kan ændre målet senere.", "Du kan endre målet senere.",
        "Цель можно поменять позже.", "Cilj možeš promijeniti kasnije."),
    "onboarding.dailyGoal.perDay": row(
        "%@ om dagen!", "%@ om dagen!", "%@ в день!", "%@ dnevno!"),
    "onboarding.dailyGoal.singular": row(
        "lektion", "leksjon", "урок", "lekcija"),
    "onboarding.dailyGoal.plural": row(
        "lektioner", "leksjoner", "урока", "lekcije"),
    "onboarding.loading.title": row(
        "Vi gør din rejse klar", "Vi gjør løypa di klar", "Готовим твой маршрут",
        "Pripremamo tvoju putanju"),
    "onboarding.loading.subtitle": row(
        "Det tager kun et øjeblik.", "Det tar bare et øyeblikk.",
        "Пара секунд, обещаем.", "Samo nekoliko sekundi, obećavamo."),
})

# --- onboarding v1: loading steps, program, projection, showcase, graph ----
# Standalone count chips: Russian takes the "Noun: %d" form (always correct,
# and idiomatic in Russian UI), Croatian the genitive plural after the numeral,
# matching what the Polish/Czech tables already do.
STRINGS.update({
    "onboarding.loading.step1": row(
        "Analyserer dine svar", "Analyserer svarene dine", "Анализируем твои ответы",
        "Analiziramo tvoje odgovore"),
    "onboarding.loading.step2": row(
        "Vælger dine 3 emner", "Velger de 3 emnene dine", "Подбираем 3 предмета",
        "Biramo tvoja 3 predmeta"),
    "onboarding.loading.step3": row(
        "Gør din rejse klar", "Gjør løypa di klar", "Готовим твой маршрут",
        "Pripremamo tvoju putanju"),
    "onboarding.program.badge": row(
        "Personligt program", "Personlig plan", "Персональная программа",
        "Osobni program"),
    "onboarding.program.title": row(
        "Her er dit program", "Her er planen din", "Вот твоя программа",
        "Evo tvog programa"),
    "onboarding.program.profileLabel": row(
        "DIN PROFIL", "PROFILEN DIN", "ТВОЙ ПРОФИЛЬ", "TVOJ PROFIL"),
    "onboarding.program.nickname.default": row(
        "Utrættelig nysgerrig", "Utrettelig nysgjerrig", "Неутомимый искатель",
        "Neumorni znatiželjnik"),
    "onboarding.program.nickname.histoire": row(
        "Historieentusiast", "Historieentusiast", "Знаток истории",
        "Zaljubljenik u povijest"),
    "onboarding.program.nickname.sciences": row(
        "Videnskabsudforsker", "Vitenskapsutforsker", "Исследователь науки",
        "Istraživač znanosti"),
    "onboarding.program.nickname.litterature": row(
        "Litteraturelsker", "Litteraturelsker", "Ценитель литературы",
        "Zaljubljenik u književnost"),
    "onboarding.program.nickname.art": row(
        "Kunstentusiast", "Kunstentusiast", "Ценитель искусства",
        "Zaljubljenik u umjetnost"),
    "onboarding.program.nickname.mythologie": row(
        "Mytologiopdager", "Mytologioppdager", "Любитель мифов",
        "Istraživač mitologije"),
    "onboarding.program.nickname.comprendreLeMonde": row(
        "Verdensobservatør", "Verdensobservatør", "Наблюдатель за миром",
        "Promatrač svijeta"),
    "onboarding.program.dailyGoal": row("%d %@", "%d %@", "%d %@", "%d %@"),
    "onboarding.program.dailyGoalCaption": row(
        "Dagligt mål", "Dagsmål", "Цель на день", "Dnevni cilj"),
    "onboarding.program.hoursSaved": row("%d t", "%d t", "%d ч", "%d h"),
    "onboarding.program.hoursUnit": row("t/år", "t/år", "ч/год", "h/god."),
    "onboarding.program.hoursSavedCaption": row(
        "sparet tid", "spart tid", "сэкономлено", "ušteđenog vremena"),
    "onboarding.program.topPick": row(
        "Vores favorit", "Favoritten vår", "Наш фаворит", "Naš favorit"),
    "onboarding.program.coursesTitle": row(
        "Kurserne der passer bedst til dig",
        "Kursene som passer deg best",
        "Курсы, которые подойдут тебе больше всего",
        "Tečajevi koji ti najbolje odgovaraju"),
    "onboarding.projection.line1": row(
        "Lille vane,", "Liten vane,", "Маленькая привычка —", "Mala navika,"),
    "onboarding.projection.line2": row(
        "kæmpe resultater.", "enorme resultater.", "огромный результат.",
        "golemi rezultati."),
    "onboarding.projection.its": row("Det er", "Det er", "Это", "To je"),
    "onboarding.projection.newThings": row(
        "nye ting, du kommer til at vide",
        "nye ting du kommer til å kunne",
        "новых фактов, которые ты запомнишь",
        "novih stvari koje ćeš znati"),
    "onboarding.projection.inOneYear": row(
        "om et år.", "om ett år.", "уже через год.", "za godinu dana."),
    "onboarding.showcase.courses.title": row(
        "Opdag korte,\nklare kurser", "Oppdag korte,\nklare kurs",
        "Открывай короткие\nи понятные курсы", "Otkrij kratke\ni jasne tečajeve"),
    "onboarding.showcase.courses.swipe": row(
        "SWIPE FOR AT SE MERE", "SVEIP FOR Å SE MER", "ЛИСТАЙ, ЧТОБЫ УЗНАТЬ",
        "PREVUCI ZA OTKRIVANJE"),
    "onboarding.showcase.courses.lessons": row(
        "%d lektioner", "%d leksjoner", "Уроков: %d", "%d lekcija"),
    "onboarding.showcase.courses.quizCount": row(
        "%d quizzer", "%d quizer", "Тестов: %d", "%d kvizova"),
    "onboarding.showcase.quiz.title": row(
        "Bliv bedre\nmed quizzer", "Bli bedre\nmed quizer", "Прокачивайся\nна тестах",
        "Napreduj\nuz kvizove"),
    "onboarding.showcase.quiz.question": row(
        "Hvad kan ikke slippe ud af et sort hul?",
        "Hva kan ikke slippe ut av et svart hull?",
        "Что не может вырваться из чёрной дыры?",
        "Što ne može pobjeći iz crne rupe?"),
    "onboarding.showcase.quiz.option.0": row("Lyd", "Lyd", "Звук", "Zvuk"),
    "onboarding.showcase.quiz.option.1": row("Lys", "Lys", "Свет", "Svjetlost"),
    "onboarding.showcase.quiz.option.2": row("Varme", "Varme", "Тепло", "Toplina"),
    "onboarding.showcase.quiz.option.3": row("Tid", "Tid", "Время", "Vrijeme"),
    "onboarding.showcase.collections.title": row(
        "Følg tematiske\nforløb", "Følg tematiske\nløyper",
        "Проходи тематические\nмаршруты", "Prati tematske\nputanje"),
    "onboarding.showcase.xp.title": row(
        "Stig i niveau\nog klatr op blandt\nde mest vidende",
        "Stig i nivå\nog klatre opp blant\nde mest kunnskapsrike",
        "Повышай уровень\nи поднимайся в рейтинге\nсамых эрудированных",
        "Rasti u razinama\ni penji se na ljestvici\nnajobrazovanijih"),
    "onboarding.showcase.xp.level": row("NIVEAU", "NIVÅ", "УРОВЕНЬ", "RAZINA"),
    "onboarding.graph.title": row(
        "Sådan vokser\ndin viden", "Slik vokser\nkunnskapen din",
        "Как растут\nтвои знания", "Kako raste\ntvoje znanje"),
    "onboarding.graph.subtitle": row(
        "Med og uden Sophia", "Med og uten Sophia", "С Sophia и без",
        "Uz Sophiju i bez nje"),
    "onboarding.graph.culture": row("VIDEN", "KUNNSKAP", "ЗНАНИЯ", "ZNANJE"),
    "onboarding.graph.withSophia": row(
        "Med Sophia", "Med Sophia", "С Sophia", "Uz Sophiju"),
    "onboarding.graph.withoutSophia": row(
        "Uden Sophia", "Uten Sophia", "Без Sophia", "Bez Sophije"),
    "onboarding.graph.today": row("I dag", "I dag", "Сегодня", "Danas"),
    "onboarding.graph.oneYear": row("1 år", "1 år", "1 год", "1 godina"),
})

# --- onboarding v1: final, trial timeline, premium gift --------------------
STRINGS.update({
    "onboarding.graph.tagline": row(
        "Sophia får din viden til at vokse\neksponentielt.",
        "Sophia får kunnskapen din til å vokse\neksponentielt.",
        "С Sophia твои знания растут\nпо экспоненте.",
        "Uz Sophiju tvoje znanje raste\neksponencijalno."),
    "onboarding.final.title": row(
        "Profilen er klar!", "Profilen er klar!", "Профиль готов!",
        "Profil je spreman!"),
    "onboarding.final.subtitle": row(
        "Velkommen til Sophia.\nGå i gang med det samme.",
        "Velkommen til Sophia.\nSett i gang med en gang.",
        "Добро пожаловать в Sophia.\nНачинай учиться прямо сейчас.",
        "Dobro došao u Sophiju.\nKreni učiti odmah."),
    "onboarding.final.subjects": row(
        "DINE EMNER", "EMNENE DINE", "ТВОИ ПРЕДМЕТЫ", "TVOJI PREDMETI"),
    "onboarding.trial.badge": row(
        "Velkomsttilbud", "Velkomsttilbud", "Приветственный бонус",
        "Uvodna ponuda"),
    "onboarding.trial.title": row(
        "Dine første 3 dage\ner gratis", "De 3 første dagene\ner gratis",
        "Первые 3 дня\nбесплатно", "Prva 3 dana\nsu besplatna"),
    "onboarding.trial.unlimitedCourses": row(
        "Ubegrænsede kurser", "Ubegrensede kurs", "Курсы без ограничений",
        "Neograničeni tečajevi"),
    "onboarding.trial.allQuizzes": row(
        "Alle quizzer", "Alle quizer", "Все тесты", "Svi kvizovi"),
    "onboarding.trial.noSurprise": row(
        "Ingen overraskelser", "Ingen overraskelser", "Без сюрпризов",
        "Bez iznenađenja"),
    "onboarding.trial.notifyTitle": row(
        "Vi giver dig besked\n1 dag før din gratis\nprøveperiode slutter",
        "Vi sier fra\n1 dag før den gratis\nprøveperioden er over",
        "Мы напомним\nза 1 день до конца\nбесплатного периода",
        "Javit ćemo ti\n1 dan prije kraja\nbesplatnog razdoblja"),
    "onboarding.trial.cancelAnytime": row(
        "Afmeld når som helst, gratis.", "Avbryt når som helst, gratis.",
        "Отменить можно когда угодно, бесплатно.",
        "Otkaži kad god želiš, bez naplate."),
    "onboarding.trial.day1": row("DAG 1", "DAG 1", "ДЕНЬ 1", "DAN 1"),
    "onboarding.trial.day2": row("DAG 2", "DAG 2", "ДЕНЬ 2", "DAN 2"),
    "onboarding.trial.day3": row("DAG 3", "DAG 3", "ДЕНЬ 3", "DAN 3"),
    "onboarding.trial.fullAccess": row(
        "Fuld adgang", "Full tilgang", "Полный доступ", "Potpuni pristup"),
    "onboarding.trial.notificationSent": row(
        "Besked sendt", "Varsel sendt", "Напоминание отправлено",
        "Obavijest poslana"),
    "onboarding.trial.trialEnds": row(
        "Prøveperioden slutter", "Prøveperioden er over", "Конец пробного периода",
        "Kraj probnog razdoblja"),
    "onboarding.premiumGift.badge": row(
        "Gave til dig", "Gave til deg", "Подарок", "Poklon za tebe"),
    "onboarding.premiumGift.title": row(
        "Vi giver dig\nSophia Premium", "Vi gir deg\nSophia Premium",
        "Дарим тебе\nSophia Premium", "Poklanjamo ti\nSophia Premium"),
    "onboarding.premiumTrial.badge": row(
        "Gratis prøve", "Gratis prøve", "Бесплатный период", "Besplatna proba"),
    "onboarding.premiumTrial.title": row(
        "Din gratis prøve\ni 3 trin", "Den gratis prøven\ni 3 trinn",
        "Твой бесплатный период\nв 3 шага", "Tvoja besplatna proba\nu 3 koraka"),
    "onboarding.premiumTrial.step1.label": row("NU", "NÅ", "СЕЙЧАС", "SADA"),
    "onboarding.premiumTrial.step1.title": row(
        "Premium er aktiveret", "Premium er aktivert", "Premium активирован",
        "Premium je aktiviran"),
    "onboarding.premiumTrial.step2.label": row(
        "DAG 1", "DAG 1", "ДЕНЬ 1", "DAN 1"),
    "onboarding.premiumTrial.step2.title": row(
        "Påmindelse inden slut", "Påminnelse før slutt", "Напоминание перед концом",
        "Podsjetnik prije kraja"),
    "onboarding.premiumTrial.step3.label": row(
        "DAG 2", "DAG 2", "ДЕНЬ 2", "DAN 2"),
    "onboarding.premiumTrial.step3.title": row(
        "Du beholder eller afmelder", "Du beholder eller avbryter",
        "Оставляешь или отменяешь", "Zadržiš ili otkažeš"),
    "onboarding.premiumTrial.cancelAnytime": row(
        "Ingen binding", "Ingen binding", "Без обязательств", "Bez obveze"),
    "onboarding.premiumTrial.cta": row(
        "Start min prøve", "Start prøven min", "Начать бесплатный период",
        "Pokreni probu"),
})

# --- paywall: headers, benefits, teaser ------------------------------------
# `*.highlight` values MUST stay exact substrings of their headline, so the
# headlines are worded around the highlighted word rather than the reverse.
STRINGS.update({
    "paywall.cancelAnytime": row(
        "Afmeld når som helst, gratis.", "Avbryt når som helst, gratis.",
        "Отменить можно когда угодно, бесплатно.",
        "Otkaži kad god želiš, bez naplate."),
    "paywall.header": row(
        "Bliv den mest\ninteressante\nperson i rummet.",
        "Bli den mest\ninteressante\npersonen i rommet.",
        "Стань самым\nинтересным человеком\nв комнате.",
        "Postani\nnajzanimljivija\nosoba u prostoriji."),
    "paywall.header.highlight": row(
        "interessante", "interessante", "интересным", "najzanimljivija"),
    "paywall.weaponHeadline": row(
        "Sophia, dit hemmelige\nvåben til:",
        "Sophia, ditt hemmelige\nvåpen for:",
        "Sophia — твоё секретное\nоружие для:",
        "Sophia, tvoje tajno\noružje za:"),
    "paywall.weaponHeadline.highlight": row(
        "hemmelige", "hemmelige", "секретное", "tajno"),
    "paywall.benefit.conversations": row(
        "💬 Bedre samtaler", "💬 Bedre samtaler", "💬 Разговоры интереснее",
        "💬 Bolji razgovori"),
    "paywall.benefit.curiosity": row(
        "💡 Mere nysgerrighed", "💡 Mer nysgjerrighet", "💡 Больше любопытства",
        "💡 Više znatiželje"),
    "paywall.benefit.confidence": row(
        "🔥 Mere selvtillid", "🔥 Mer selvtillit", "🔥 Больше уверенности",
        "🔥 Više samopouzdanja"),
    "paywall.benefit.screenTime": row(
        "📱 Skærmtid der tæller", "📱 Skjermtid som teller",
        "📱 Экранное время с пользой", "📱 Korisnije vrijeme na ekranu"),
    "paywall.premiumHeadline": row(
        "Lås Premium op i 3 dage\nGRATIS",
        "Lås opp Premium i 3 dager\nGRATIS",
        "Открой Premium на 3 дня\nБЕСПЛАТНО",
        "Otključaj Premium na 3 dana\nBESPLATNO"),
    "paywall.premiumHeadline.highlight": row(
        "GRATIS", "GRATIS", "БЕСПЛАТНО", "BESPLATNO"),
    "paywall.freeSubjects": row(
        "Dine 3 gratis emner", "De 3 gratis emnene dine",
        "Твои 3 бесплатных предмета", "Tvoja 3 besplatna predmeta"),
    "paywall.lockedSubjects": row(
        "3 emner at låse op", "3 emner å låse opp", "3 закрытых предмета",
        "3 zaključana predmeta"),
    "paywall.lockedSubjectsWithPremium": row(
        "3 emner du låser op med Premium",
        "3 emner du låser opp med Premium",
        "3 предмета откроются с Premium",
        "3 predmeta otključavaš uz Premium"),
    "paywall.teaserTitle": row(
        "Et smugkig på det, der venter", "Et smugkikk på det som venter",
        "Загляни, что тебя ждёт", "Pogled na ono što te čeka"),
    "paywall.teaserSubtitle": row(
        "Hundredvis af premium-kurser at låse op",
        "Hundrevis av premium-kurs å låse opp",
        "Сотни premium-курсов ждут",
        "Stotine premium tečajeva čeka otključavanje"),
})

# --- paywall: comparison table, plans, FAQ, course gate, reviews -----------
# Fallback prices stay in USD like every other non-French table; only the
# per-month suffix is localised. Quote marks follow each locale: da »…«,
# nb «…», ru «…», hr „…”.
STRINGS.update({
    "paywall.featureColumn": row(
        "Funktioner", "Funksjoner", "Возможности", "Značajke"),
    "paywall.freeColumn": row("Gratis", "Gratis", "Бесплатно", "Besplatno"),
    "paywall.premiumColumn": row("Premium", "Premium", "Premium", "Premium"),
    "paywall.feature.3subjects": row(
        "3 emner", "3 emner", "3 предмета", "3 predmeta"),
    "paywall.feature.allSubjects": row(
        "Alle emner", "Alle emner", "Все предметы", "Svi predmeti"),
    "paywall.feature.unlimitedCourses": row(
        "Ubegrænsede kurser", "Ubegrensede kurs", "Курсы без лимита",
        "Neograničeni tečajevi"),
    "paywall.feature.miniQuiz": row(
        "Mini-quiz", "Mini-quiz", "Мини-тесты", "Mini kvizovi"),
    "paywall.feature.fullLibrary": row(
        "Hele biblioteket", "Hele biblioteket", "Вся библиотека",
        "Cijela knjižnica"),
    "paywall.plan.yearly": row("Årligt", "Årlig", "Годовой", "Godišnje"),
    "paywall.plan.monthly": row("Månedligt", "Månedlig", "Месячный", "Mjesečno"),
    "paywall.plan.yearlySubtitle": row(
        "Betales årligt", "Betales årlig", "Оплата раз в год",
        "Naplata jednom godišnje"),
    "paywall.plan.monthlySubtitle": row(
        "Ingen binding", "Ingen binding", "Без обязательств", "Bez obveze"),
    "paywall.plan.perYear": row("/ år", "/ år", "/ год", "/ god."),
    "paywall.plan.perMonth": row("/ md.", "/ mnd.", "/ мес.", "/ mj."),
    "paywall.plan.discount": row("-58%", "-58%", "-58%", "-58%"),
    "paywall.plan.fallback.yearlyPrice": row(
        "$34.99", "$34.99", "$34.99", "$34.99"),
    "paywall.plan.fallback.monthlyPrice": row("$8.99", "$8.99", "$8.99", "$8.99"),
    "paywall.plan.fallback.yearlyMonthly": row(
        "$2,92 / måned", "$2,92 / måned", "$2,92 / мес.", "2,92 $ / mjesec"),
    "paywall.trialBadge": row(
        "3 dages gratis prøve", "3 dagers gratis prøve", "3 дня бесплатно",
        "3 dana besplatno"),
    "paywall.restoreRow": row(
        "Gendan · Vilkår · Privatliv",
        "Gjenopprett · Vilkår · Personvern",
        "Восстановить · Условия · Приватность",
        "Vrati · Uvjeti · Privatnost"),
    "paywall.restore": row("Gendan", "Gjenopprett", "Восстановить", "Vrati"),
    "paywall.quiz.title": row(
        "Lås quizzen op", "Lås opp quizen", "Открой тест", "Otključaj kviz"),
    "paywall.quiz.subtitle": row(
        "Test dig selv og fastgør det, du lige har lært, med kursets quiz.",
        "Test deg selv og fest det du nettopp lærte, med quizen til kurset.",
        "Проверь себя и закрепи только что пройденное тестом этого курса.",
        "Provjeri se i učvrsti ono što si upravo naučio kvizom ovog tečaja."),
    "paywall.quiz.faq.q1": row(
        "Er abonnementet nemt at opsige?",
        "Er abonnementet lett å si opp?",
        "Подписку легко отменить?",
        "Je li pretplatu lako otkazati?"),
    "paywall.quiz.faq.a1": row(
        "Ja. Gå til App Store → din konto → Abonnementer → Sophia → Opsig. Klaret på få tryk.",
        "Ja. Gå til App Store → kontoen din → Abonnementer → Sophia → Si opp. Ferdig på noen trykk.",
        "Да. Зайди в App Store → свой аккаунт → Подписки → Sophia → Отменить. Пара нажатий.",
        "Da. Idi u App Store → svoj račun → Pretplate → Sophia → Otkaži. Gotovo u nekoliko dodira."),
    "paywall.quiz.faq.q2": row(
        "Giver Sophia Pro adgang til Sophia Repetition?",
        "Gir Sophia Pro tilgang til Sophia Repetisjon?",
        "Sophia Pro открывает Sophia Повторение?",
        "Daje li Sophia Pro pristup Sophia Ponavljanju?"),
    "paywall.quiz.faq.a2": row(
        "Ja. Sophia Pro låser også Sophia Repetition op: aktiv genkaldelse, der stiller spørgsmålene igen på det rigtige tidspunkt, så det, du lærer, bliver siddende.",
        "Ja. Sophia Pro låser også opp Sophia Repetisjon: aktiv gjenkalling som henter fram spørsmålene igjen til rett tid, så det du lærer sitter.",
        "Да. Sophia Pro открывает и Sophia Повторение: активное припоминание возвращает вопросы вовремя, чтобы выученное осталось надолго.",
        "Da. Sophia Pro otključava i Sophia Ponavljanje: aktivno prisjećanje koje vraća pitanja u pravom trenutku da naučeno ostane."),
    "paywall.quiz.faq.q3": row(
        "Kan jeg opsige abonnementet når som helst?",
        "Kan jeg si opp abonnementet når som helst?",
        "Можно отменить подписку в любой момент?",
        "Mogu li otkazati pretplatu kad god želim?"),
    "paywall.quiz.faq.a3": row(
        "Ja — inden den gratis prøveperiode slutter, og når som helst bagefter. Prøveperioden er der, så du kan opdage appen og alt, den kan.",
        "Ja — før den gratis prøveperioden er over, og når som helst etterpå. Prøveperioden er der så du kan bli kjent med appen og alt den kan.",
        "Да — до конца бесплатного периода и в любой момент после. Бесплатный период на то и нужен, чтобы ты освоился в приложении и его возможностях.",
        "Da — prije kraja besplatnog razdoblja i bilo kada poslije. Besplatno razdoblje tu je da upoznaš aplikaciju i sve što nudi."),
    "paywall.quiz.faq.q3.noTrial": row(
        "Binder jeg mig for en periode?",
        "Binder jeg meg for en periode?",
        "Есть ли обязательства по сроку?",
        "Vežem li se na neko razdoblje?"),
    "paywall.quiz.faq.a3.noTrial": row(
        "Nej. Ingen binding: opsig når du vil i App Store, og du beholder adgangen resten af den periode, du allerede har betalt for.",
        "Nei. Ingen binding: si opp når du vil i App Store, og du beholder tilgangen ut perioden du allerede har betalt for.",
        "Нет. Никаких обязательств: отменяй когда угодно в App Store — доступ останется до конца уже оплаченного периода.",
        "Ne. Bez obveze: otkaži kad god želiš u App Storeu i zadržavaš pristup do kraja već plaćenog razdoblja."),
    "paywall.course.title": row(
        "Du har allerede læst dagens gratis kursus",
        "Du har allerede lest dagens gratis kurs",
        "Ты уже прочитал бесплатный курс на сегодня",
        "Već si pročitao današnji besplatni tečaj"),
    "paywall.course.subtitle": row(
        "Du har brugt dagens gratis kursus. Kom tilbage i morgen, eller lås alt op nu.",
        "Du har brukt dagens gratis kurs. Kom tilbake i morgen, eller lås opp alt nå.",
        "Бесплатный курс на сегодня уже использован. Возвращайся завтра или открой всё прямо сейчас.",
        "Iskoristio si današnji besplatni tečaj. Vrati se sutra ili otključaj sve odmah."),
    "paywall.course.subtitle.named": row(
        "Du har brugt dagens gratis kursus. Lås »%@« og alle kurser op nu, eller kom tilbage i morgen.",
        "Du har brukt dagens gratis kurs. Lås opp «%@» og alle kurs nå, eller kom tilbake i morgen.",
        "Бесплатный курс на сегодня уже использован. Открой «%@» и все курсы прямо сейчас или возвращайся завтра.",
        "Iskoristio si današnji besplatni tečaj. Otključaj „%@” i sve tečajeve odmah ili se vrati sutra."),
    "paywall.course.comeBack": row(
        "Næste gratis kursus om", "Neste gratis kurs om",
        "Следующий бесплатный курс через", "Sljedeći besplatni tečaj za"),
    "paywall.course.stat.value": row("6", "6", "6", "6"),
    "paywall.course.stat.label": row(
        "kurser / dag", "kurs / dag", "курсов / день", "tečajeva / dan"),
    "paywall.course.stat.caption": row(
        "læses i gennemsnit af Sophia Premium-medlemmer",
        "leses i snitt av Sophia Premium-medlemmer",
        "в среднем читают участники Sophia Premium",
        "u prosjeku pročitaju članovi Sophia Premiuma"),
    "paywall.rating": row(
        "på App Store", "på App Store", "в App Store", "na App Storeu"),
    "paywall.reviews.r1.quote": row(
        "Jeg sluger et kursus, så snart jeg har 5 minutter. Jeg har aldrig lært så meget.",
        "Jeg sluker et kurs så snart jeg har 5 minutter. Jeg har aldri lært så mye.",
        "Проглатываю курс, как только есть 5 минут. Никогда столько не узнавал.",
        "Progutam tečaj čim imam 5 minuta. Nikad nisam toliko naučio."),
    "paywall.reviews.r1.author": row(
        "Camille, 22 år", "Camille, 22 år", "Камий, 22 года", "Camille, 22 godine"),
    "paywall.reviews.r2.quote": row(
        "Abonnementet tjente sig hjem på en uge. Jeg læser flere kurser om dagen.",
        "Abonnementet tjente seg inn på en uke. Jeg leser flere kurs om dagen.",
        "Подписка окупилась за неделю. Читаю по несколько курсов в день.",
        "Pretplata mi se isplatila u tjedan dana. Čitam više tečajeva dnevno."),
    "paywall.reviews.r2.author": row(
        "Thomas, 29 år", "Thomas, 29 år", "Тома, 29 лет", "Thomas, 29 godina"),
    "paywall.reviews.r3.quote": row(
        "Jeg føler mig klogere for hver uge. Svært at stoppe ved ét kursus.",
        "Jeg føler meg klokere for hver uke. Vanskelig å stoppe på ett kurs.",
        "С каждой неделей чувствую себя эрудированнее. Трудно остановиться на одном курсе.",
        "Svaki tjedan se osjećam obrazovanije. Teško je stati na jednom tečaju."),
    "paywall.reviews.r3.author": row(
        "Inès, 25 år", "Inès, 25 år", "Инес, 25 лет", "Inès, 25 godina"),
    "paywall.benefit.unlimited": row(
        "Ubegrænsede kurser, hver dag", "Ubegrensede kurs, hver dag",
        "Курсы без лимита каждый день", "Neograničeni tečajevi, svaki dan"),
    "paywall.benefit.quiz": row(
        "Alle quizzer, så det sidder fast", "Alle quizer, så det sitter",
        "Все тесты — чтобы запомнить", "Svi kvizovi za bolje pamćenje"),
    "paywall.benefit.allSubjects": row(
        "Alle emner, uden reklamer", "Alle emner, uten reklame",
        "Все темы, без рекламы", "Sve teme, bez reklama"),
    "paywall.cta.unlockFree": row(
        "Lås op gratis", "Lås opp gratis", "Открыть бесплатно",
        "Otključaj besplatno"),
    "paywall.cta.subscribe": row(
        "Abonnér nu", "Abonner nå", "Оформить подписку", "Pretplati se sada"),
})

# --- paywall: practice pitch, quiz demo, flash offer ------------------------
# "Sophia Entraînement" is the Practice brand: Repetition / Repetisjon /
# Повторение / Ponavljanje, kept identical everywhere it appears.
STRINGS.update({
    "paywall.cta.activateTrial": row(
        "Aktivér min gratis prøve", "Aktiver den gratis prøven",
        "Активировать бесплатный период", "Aktiviraj besplatnu probu"),
    "paywall.price.trialThenYearly": row(
        "3 dages gratis prøve, derefter %@ / år (%@)",
        "3 dagers gratis prøve, deretter %@ / år (%@)",
        "3 дня бесплатно, затем %@ / год (%@)",
        "3 dana besplatno, zatim %@ / god. (%@)"),
    "paywall.price.yearlyNoTrial": row(
        "%@ / år (%@) · Opsig når som helst",
        "%@ / år (%@) · Si opp når som helst",
        "%@ / год (%@) · Отмена в любой момент",
        "%@ / god. (%@) · Otkaži kad god želiš"),
    "paywall.training.title": row(
        "Få det til at sidde fast, for altid", "Få det til å sitte, for godt",
        "Закрепи выученное навсегда", "Neka naučeno ostane zauvijek"),
    "paywall.training.subtitle": row(
        "Repetition henter dine quizspørgsmål frem igen på det perfekte tidspunkt — lige før hjernen når at glemme dem.",
        "Repetisjon henter fram quizspørsmålene dine til perfekt tid — rett før hjernen rekker å glemme dem.",
        "Повторение возвращает вопросы теста в идеальный момент — прямо перед тем, как мозг их забудет.",
        "Ponavljanje vraća pitanja iz kvizova u savršenom trenutku — točno prije nego ih mozak zaboravi."),
    "paywall.training.stat1.value": row("+200 %", "+200 %", "+200 %", "+200 %"),
    "paywall.training.stat1.label": row(
        "bedre hukommelse med spredt repetition, mod bare at læse igen",
        "bedre hukommelse med spredt repetisjon, mot bare å lese om igjen",
        "к запоминанию благодаря интервальному повторению вместо перечитывания",
        "bolje pamćenje uz razmaknuto ponavljanje, u odnosu na puko ponovno čitanje"),
    "paywall.training.stat2.value": row("90 %", "90 %", "90 %", "90 %"),
    "paywall.training.stat2.label": row(
        "af det, vi lærer, er glemt på en uge… uden repetition",
        "av det vi lærer, er glemt på en uke… uten repetisjon",
        "выученного забывается за неделю… без повторения",
        "naučenog zaboravi se u tjedan dana… bez ponavljanja"),
    "paywall.training.how.title": row(
        "SÅDAN VIRKER DET", "SLIK FUNGERER DET", "КАК ЭТО РАБОТАЕТ",
        "KAKO TO FUNKCIONIRA"),
    "paywall.training.how.step1": row(
        "Gennemfør et kursus og dets quiz", "Fullfør et kurs og quizen",
        "Пройди курс и его тест", "Završi tečaj i njegov kviz"),
    "paywall.training.how.step2": row(
        "Spørgsmålene ryger ind i din Repetition",
        "Spørsmålene havner i Repetisjonen din",
        "Его вопросы попадают в твоё Повторение",
        "Njegova pitanja ulaze u tvoje Ponavljanje"),
    "paywall.training.how.step3": row(
        "Repetér på det rigtige tidspunkt, så du aldrig glemmer igen",
        "Repeter til rett tid, så du aldri glemmer igjen",
        "Повторяй в нужный момент — и больше не забудешь",
        "Ponavljaj u pravom trenutku i više nikad ne zaboraviš"),
    "paywall.training.footnote": row(
        "Spredt repetition er den bedst dokumenterede metode til at gøre viden varig.",
        "Spredt repetisjon er den best dokumenterte måten å gjøre kunnskap varig på.",
        "Интервальное повторение — самый доказанный способ сделать знания прочными.",
        "Razmaknuto ponavljanje najbolje je dokazan način da znanje postane trajno."),
    "paywall.quiz.rating": row(
        "på App Store", "på App Store", "в App Store", "na App Storeu"),
    "paywall.quiz.demo.title": row(
        "Test dig selv efter hvert kursus", "Test deg selv etter hvert kurs",
        "Проверяй себя после каждого курса", "Provjeri se nakon svakog tečaja"),
    "paywall.quiz.demo.badge.mcq": row(
        "Flervalg", "Flervalg", "Выбор ответа", "Izbor odgovora"),
    "paywall.quiz.demo.badge.trueFalse": row(
        "Sandt / falsk", "Sant / usant", "Верно / неверно", "Točno / netočno"),
    "paywall.quiz.demo.badge.slider": row("Gæt", "Gjett", "Оценка", "Procjena"),
    "paywall.quiz.demo.badge.chrono": row(
        "Tidslinje", "Tidslinje", "Хронология", "Kronologija"),
    "paywall.quiz.demo.mcq.q": row(
        "Hvem malede Stjernenat?", "Hvem malte Stjernenatt?",
        "Кто написал «Звёздную ночь»?", "Tko je naslikao Zvjezdanu noć?"),
    "paywall.quiz.demo.mcq.o1": row(
        "Van Gogh", "Van Gogh", "Ван Гог", "Van Gogh"),
    "paywall.quiz.demo.mcq.o2": row("Monet", "Monet", "Моне", "Monet"),
    "paywall.quiz.demo.mcq.o3": row("Picasso", "Picasso", "Пикассо", "Picasso"),
    "paywall.quiz.demo.tf.q": row(
        "Den Kinesiske Mur kan ses fra Månen.",
        "Den kinesiske mur kan ses fra månen.",
        "Великую Китайскую стену видно с Луны.",
        "Kineski zid vidljiv je s Mjeseca."),
    "paywall.quiz.demo.tf.true": row("Sandt", "Sant", "Верно", "Točno"),
    "paywall.quiz.demo.tf.false": row("Falsk", "Usant", "Неверно", "Netočno"),
    "paywall.quiz.demo.slider.q": row(
        "Hvilket år begyndte Den Franske Revolution?",
        "Hvilket år startet Den franske revolusjon?",
        "В каком году началась Французская революция?",
        "Koje je godine počela Francuska revolucija?"),
    "paywall.quiz.demo.chrono.q": row(
        "Sæt perioderne i rækkefølge", "Sett periodene i rekkefølge",
        "Расставь эпохи по порядку", "Poredaj razdoblja kronološki"),
    "paywall.quiz.demo.chrono.i1": row(
        "Oldtiden", "Oldtiden", "Античность", "Antika"),
    "paywall.quiz.demo.chrono.i2": row(
        "Middelalderen", "Middelalderen", "Средневековье", "Srednji vijek"),
    "paywall.quiz.demo.chrono.i3": row(
        "Renæssancen", "Renessansen", "Возрождение", "Renesansa"),
    "paywall.quiz.reviews.title": row(
        "De lærer med Sophia", "De lærer med Sophia", "Они учатся с Sophia",
        "Oni napreduju uz Sophiju"),
    "paywall.quiz.review1.quote": row(
        "Quizzerne fik mig til at huske langt mere end bare at læse. 5 min, og det sidder.",
        "Quizene fikk meg til å huske mye mer enn bare lesing. 5 min, og det sitter.",
        "Тесты помогли запомнить куда больше, чем просто чтение. 5 минут — и держится.",
        "Kvizovi su me natjerali da zapamtim puno više nego samo čitanjem. 5 min i ostaje."),
    "paywall.quiz.review1.author": row(
        "Camille, 22 år", "Camille, 22 år", "Камий, 22 года", "Camille, 22 godine"),
    "paywall.quiz.review2.quote": row(
        "Endelig en app, hvor jeg virkelig husker det, jeg lærer. Quizzerne er vanedannende.",
        "Endelig en app der jeg faktisk husker det jeg lærer. Quizene er vanedannende.",
        "Наконец приложение, где я правда запоминаю. От тестов не оторваться.",
        "Konačno aplikacija u kojoj stvarno pamtim ono što učim. Kvizovi su zarazni."),
    "paywall.quiz.review2.author": row(
        "Thomas, 29 år", "Thomas, 29 år", "Тома, 29 лет", "Thomas, 29 godina"),
    "paywall.quiz.review3.quote": row(
        "Jeg føler mig klogere for hver uge. Quizzerne forankrer det hele.",
        "Jeg føler meg klokere for hver uke. Quizene forankrer alt.",
        "С каждой неделей чувствую себя эрудированнее. Тесты закрепляют всё.",
        "Svaki tjedan se osjećam obrazovanije. Kvizovi sve učvrste."),
    "paywall.quiz.review3.author": row(
        "Inès, 25 år", "Inès, 25 år", "Инес, 25 лет", "Inès, 25 godina"),
    "paywall.discount.endsIn": row(
        "Slutter om", "Slutter om", "Заканчивается через", "Završava za"),
    "paywall.discount.title": row(
        "Lyntilbud, kun i dag", "Lyntilbud, bare i dag", "Акция только сегодня",
        "Munjevita ponuda, samo danas"),
    "paywall.discount.subtitle": row(
        "Et helt liv med Premium-viden, til den laveste pris vi nogensinde har givet.",
        "Et helt liv med Premium-kunnskap, til den laveste prisen vi noen gang har gitt.",
        "Целая жизнь знаний с Premium — по самой низкой цене, что мы предлагали.",
        "Cijeli život Premium znanja, po najnižoj cijeni koju smo ikad ponudili."),
    "paywall.discount.perYear": row(
        "om året, ingen binding", "i året, ingen binding", "в год, без обязательств",
        "godišnje, bez obveze"),
    "paywall.discount.cta": row(
        "Jeg slår til", "Jeg slår til", "Забираю предложение", "Uzimam ponudu"),
    "paywall.discount.noTrial": row(
        "Ingen gratis prøve · Opsig når som helst",
        "Ingen gratis prøve · Si opp når som helst",
        "Без пробного периода · Отмена в любой момент",
        "Bez besplatne probe · Otkaži kad god želiš"),
    "paywall.discount.fallbackPrice": row(
        "$19.99", "$19.99", "$19.99", "$19.99"),
    "paywall.terms": row("Vilkår", "Vilkår", "Условия", "Uvjeti"),
    "paywall.privacy": row("Privatliv", "Personvern", "Приватность", "Privatnost"),
    "paywall.trialSheet.title": row(
        "Start din gratis\nprøve på 3 dage", "Start den gratis\nprøven på 3 dager",
        "Начни бесплатный\nпериод на 3 дня", "Pokreni besplatnu\nprobu od 3 dana"),
    "paywall.trialSheet.start": row(
        "Start gratis prøve", "Start gratis prøve", "Начать бесплатный период",
        "Pokreni besplatnu probu"),
})

# --- paywall trial timeline, review carousel, one-time offer, profile ------
# Review quotes stay unquoted like every other table: the card draws stars and
# the author line, no typographic quotes. Only onboardingV2.exams.quote* and
# onboardingV2.review.quote carry « » in the French source.
STRINGS.update({
    "paywall.trial.today": row("I dag", "I dag", "Сегодня", "Danas"),
    "paywall.trial.noPayment": row(
        "Ingen betaling", "Ingen betaling", "Без оплаты", "Bez plaćanja"),
    "paywall.trial.todayDetail": row(
        "Adgang til alle Premium-funktioner.",
        "Tilgang til alle Premium-funksjoner.",
        "Доступ ко всем возможностям Premium.",
        "Pristup svim Premium značajkama."),
    "paywall.trial.in2days": row(
        "Om 2 dage", "Om 2 dager", "Через 2 дня", "Za 2 dana"),
    "paywall.trial.reminder": row(
        "Vi siger til", "Vi sier fra", "Мы напомним", "Javit ćemo ti"),
    "paywall.trial.reminderDetail": row(
        "Besked 1 dag før prøveperioden slutter.",
        "Varsel 1 dag før prøveperioden er over.",
        "Уведомление за 1 день до конца пробного периода.",
        "Obavijest 1 dan prije kraja probnog razdoblja."),
    "paywall.trial.in3days": row(
        "Om 3 dage", "Om 3 dager", "Через 3 дня", "Za 3 dana"),
    "paywall.trial.starts": row(
        "Dit abonnement starter", "Abonnementet ditt starter",
        "Начинается подписка", "Počinje tvoja pretplata"),
    "paywall.trial.startsDetail": row(
        "Afmeld inden, hvis du ikke vil fortsætte.",
        "Avbryt før det, hvis du ikke vil fortsette.",
        "Отмени раньше, если не хочешь продолжать.",
        "Otkaži prije ako ne želiš nastaviti."),
    "paywall.review1.quote": row(
        "Perfekt i toget. Jeg lærer noget hver dag uden at anstrenge mig.",
        "Perfekt på bussen. Jeg lærer noe hver dag uten å anstrenge meg.",
        "Идеально в дороге. Каждый день узнаю что-то новое без усилий.",
        "Savršeno u prijevozu. Svaki dan naučim nešto bez napora."),
    "paywall.review1.author": row(
        "Marie, 28 år", "Marie, 28 år", "Мари, 28 лет", "Marie, 28 godina"),
    "paywall.review2.quote": row(
        "Endelig en app, der gør scrolling til viden.",
        "Endelig en app som gjør scrolling til kunnskap.",
        "Наконец приложение, которое превращает залипание в знания.",
        "Konačno aplikacija koja skrolanje pretvara u znanje."),
    "paywall.review2.author": row(
        "Thomas, 34 år", "Thomas, 34 år", "Тома, 34 года", "Thomas, 34 godine"),
    "paywall.review3.quote": row(
        "Kurserne er korte, sjove, og jeg husker dem faktisk.",
        "Kursene er korte, morsomme, og jeg husker dem faktisk.",
        "Курсы короткие, забавные — и я правда их запоминаю.",
        "Tečajevi su kratki, zabavni i stvarno ih pamtim."),
    "paywall.review3.author": row(
        "Inès, 22 år", "Inès, 22 år", "Инес, 22 года", "Inès, 22 godine"),
    "paywall.review4.quote": row(
        "Mine venner spørger, hvor jeg har alle de anekdoter fra.",
        "Vennene mine spør hvor jeg har alle anekdotene fra.",
        "Друзья спрашивают, откуда я беру все эти истории.",
        "Prijatelji me pitaju odakle mi sve te zanimljivosti."),
    "paywall.review4.author": row(
        "Lucas, 31 år", "Lucas, 31 år", "Лукас, 31 год", "Lucas, 31 godina"),
    "paywall.review5.quote": row(
        "Den personlige opstart overbeviste mig på det første minut.",
        "Den personlige starten overbeviste meg på det første minuttet.",
        "Персональная настройка убедила меня с первой минуты.",
        "Osobni uvod uvjerio me u prvoj minuti."),
    "paywall.review5.author": row(
        "Sarah, 26 år", "Sarah, 26 år", "Сара, 26 лет", "Sarah, 26 godina"),
    "offer.unique": row(
        "Dit enestående tilbud", "Ditt enestående tilbud", "Твоё особое предложение",
        "Tvoja jedinstvena ponuda"),
    "offer.discount": row(
        "-70 % FOR ALTID", "-70 % FOR ALLTID", "-70 % НАВСЕГДА", "-70 % ZAUVIJEK"),
    "offer.perMonth": row("/md.", "/mnd.", "/мес.", "/mj."),
    "offer.billed": row("faktureret", "fakturert", "списывается", "naplaćeno"),
    "offer.expiresIn": row(
        "Udløber om", "Utløper om", "Истекает через", "Ističe za"),
    "offer.unlock": row(
        "Lås mine -70 % op", "Lås opp mine -70 %", "Забрать -70 %",
        "Otključaj mojih -70 %"),
    "offer.restore": row(
        "Gendan køb", "Gjenopprett kjøp", "Восстановить покупки", "Vrati kupnje"),
    "offer.feature1": row(
        "240 kurser i almen viden", "240 kurs i allmennkunnskap",
        "240 курсов по общей культуре", "240 tečajeva opće kulture"),
    "offer.feature2": row(
        "Ubegrænsede interaktive quizzer", "Ubegrensede interaktive quizer",
        "Интерактивные тесты без лимита", "Neograničeni interaktivni kvizovi"),
    "offer.feature3": row(
        "Nyt indhold hver uge", "Nytt innhold hver uke",
        "Новый материал каждую неделю", "Novi sadržaj svaki tjedan"),
    "profile.title": row("Profil", "Profil", "Профиль", "Profil"),
    "profile.streak.start": row(
        "Læs et kursus for at komme i gang!", "Les et kurs for å komme i gang!",
        "Прочитай курс, чтобы начать!", "Pročitaj tečaj i kreni!"),
    "profile.streak.beginning": row(
        "Du er i gang — bliv ved!", "Du er i gang — fortsett!",
        "Ты начал — продолжай!", "Krenuo si, samo nastavi!"),
    "profile.streak.good": row(
        "Flot regelmæssighed 👏", "Flott jevnhet 👏", "Отличная регулярность 👏",
        "Odlična redovitost 👏"),
    "profile.streak.great": row(
        "Du brænder igennem 🔥", "Du brenner 🔥", "Ты в ударе 🔥", "Gori ti 🔥"),
    "profile.favorites": row(
        "Mine favoritter", "Favorittene mine", "Избранное", "Moji favoriti"),
    "profile.favorites.count": row(
        "%d gemte kurser", "%d lagrede kurs", "Сохранено курсов: %d",
        "%d spremljenih tečajeva"),
    "profile.quiz.recent": row(
        "MINE SENESTE QUIZZER", "DE SISTE QUIZENE MINE", "МОИ ПОСЛЕДНИЕ ТЕСТЫ",
        "MOJI NEDAVNI KVIZOVI"),
    "profile.quiz.locked": row(
        "Quizzer er låst", "Quizene er låst", "Тесты закрыты",
        "Kvizovi su zaključani"),
    "profile.quiz.lockedSubtitle": row(
        "Tilgængelige med den gratis prøve — 3 dage gratis",
        "Tilgjengelige med den gratis prøven — 3 dager gratis",
        "Откроются с бесплатным периодом — 3 дня в подарок",
        "Dostupni uz besplatnu probu — 3 dana gratis"),
    "profile.quiz.unlock": row(
        "Lås mine quizzer op", "Lås opp quizene mine", "Открыть мои тесты",
        "Otključaj moje kvizove"),
    "profile.quiz.emptyTitle": row(
        "Ingen quizzer endnu", "Ingen quizer ennå", "Тестов пока нет",
        "Još nema kvizova"),
    "profile.quiz.emptySubtitle": row(
        "Gennemfør et kursus for at tage din første quiz.",
        "Fullfør et kurs for å ta den første quizen din.",
        "Пройди курс, чтобы открыть первый тест.",
        "Završi tečaj da odradiš svoj prvi kviz."),
    "profile.progress.bySubject": row(
        "FREMGANG PR. EMNE", "FRAMGANG PER EMNE", "ПРОГРЕСС ПО ТЕМАМ",
        "NAPREDAK PO TEMAMA"),
    "profile.stats.coursesDone": row(
        "Gennemførte kurser", "Fullførte kurs", "Курсов пройдено",
        "Završeni tečajevi"),
    "profile.mastery.title": row(
        "DIT VIDENSKORT", "KUNNSKAPSKARTET DITT", "ТВОЯ КАРТА ЗНАНИЙ",
        "TVOJA KARTA ZNANJA"),
    "profile.mastery.details": row(
        "Se detaljer pr. emne", "Se detaljer per emne", "Подробнее по предметам",
        "Prikaži detalje po predmetima"),
    "profile.mastery.hide": row(
        "Skjul detaljer", "Skjul detaljer", "Свернуть", "Sakrij detalje"),
    "profile.unlock.trial": row(
        "Lås op med den gratis prøve", "Lås opp med den gratis prøven",
        "Открыть с бесплатным периодом", "Otključaj uz besplatnu probu"),
    "profile.quiz.retry": row("Tag igen", "Ta på nytt", "Ещё раз", "Ponovi"),
    "profile.quiz.all": row(
        "Alle mine quizzer", "Alle quizene mine", "Все мои тесты",
        "Svi moji kvizovi"),
})

# --- profile progress, friends leaderboard, quiz feedback ------------------
# Streak wording stays "dage i træk / dager på rad / дней подряд / dana
# zaredom" everywhere, including the compact stat labels.
STRINGS.update({
    "profile.quiz.none": row(
        "Ingen quizzer lige nu.", "Ingen quizer akkurat nå.", "Пока нет тестов.",
        "Trenutačno nema kvizova."),
    "profile.progress.max": row(
        "%d XP · maks. niveau", "%d XP · maks nivå", "%d XP · макс. уровень",
        "%d XP · maks. razina"),
    "profile.progress.toNext": row(
        "%d XP · %d til niv. %d", "%d XP · %d til nivå %d", "%d XP · %d до ур. %d",
        "%d XP · %d do raz. %d"),
    "friends.title": row(
        "VENNERANGLISTE", "VENNERANGERING", "РЕЙТИНГ ДРУЗЕЙ",
        "LJESTVICA PRIJATELJA"),
    "friends.you": row("Dig", "Deg", "Ты", "Ti"),
    "friends.add.short": row("Tilføj", "Legg til", "Добавить", "Dodaj"),
    "friends.add.title": row(
        "Tilføj en ven", "Legg til en venn", "Добавить друга", "Dodaj prijatelja"),
    "friends.add.subtitle": row(
        "Indtast din vens @ for at tilføje vedkommende til din rangliste.",
        "Skriv inn @-en til vennen din for å legge vedkommende til i rangeringen.",
        "Введи @ друга, чтобы добавить его в свой рейтинг.",
        "Upiši @ svog prijatelja da ga dodaš na svoju ljestvicu."),
    "friends.add.requestSubtitle": row(
        "Indtast din vens @: vedkommende får en anmodning at acceptere.",
        "Skriv inn @-en til vennen din: vedkommende får en forespørsel å godta.",
        "Введи @ друга — он получит запрос и сможет его принять.",
        "Upiši @ svog prijatelja: dobit će zahtjev koji može prihvatiti."),
    "friends.request.send": row(
        "Send anmodning", "Send forespørsel", "Отправить запрос", "Pošalji zahtjev"),
    "friends.request.sent": row(
        "Anmodning sendt!", "Forespørsel sendt!", "Запрос отправлен!",
        "Zahtjev poslan!"),
    "friends.request.autoAccepted": row(
        "I er venner nu!", "Nå er dere venner!", "Теперь вы друзья!",
        "Sada ste prijatelji!"),
    "friends.requests.title": row(
        "MODTAGNE ANMODNINGER", "MOTTATTE FORESPØRSLER", "ВХОДЯЩИЕ ЗАПРОСЫ",
        "PRIMLJENI ZAHTJEVI"),
    "friends.requests.accept": row("Accepter", "Godta", "Принять", "Prihvati"),
    "friends.requests.decline": row("Afvis", "Avslå", "Отклонить", "Odbij"),
    "friends.error.alreadyFriends": row(
        "I er allerede venner.", "Dere er allerede venner.", "Вы уже друзья.",
        "Već ste prijatelji."),
    "friends.error.requestAlreadySent": row(
        "Anmodningen er allerede sendt.", "Forespørselen er allerede sendt.",
        "Запрос уже отправлен.", "Zahtjev je već poslan."),
    "friends.error.requestNotFound": row(
        "Denne anmodning findes ikke længere.",
        "Denne forespørselen finnes ikke lenger.",
        "Этот запрос больше недоступен.", "Ovaj zahtjev više nije dostupan."),
    "friends.add.action": row("Tilføj", "Legg til", "Добавить", "Dodaj"),
    "friends.add.success": row(
        "Ven tilføjet!", "Venn lagt til!", "Друг добавлен!", "Prijatelj dodan!"),
    "friends.handle.placeholder": row(
        "brugernavn", "brukernavn", "никнейм", "korisničko ime"),
    "friends.handle.edit.title": row(
        "Rediger dit @", "Endre @-en din", "Изменить свой @", "Promijeni svoj @"),
    "friends.handle.edit.subtitle": row(
        "Dit @ gør, at dine venner kan finde dig.",
        "@-en din gjør at vennene dine finner deg.",
        "По @ друзья смогут тебя найти.",
        "Po @ te prijatelji mogu pronaći."),
    "friends.handle.save": row("Gem", "Lagre", "Сохранить", "Spremi"),
    "friends.handle.rules": row(
        "3–20 tegn, kun bogstaver og tal, skal starte med et bogstav.",
        "3–20 tegn, bare bokstaver og tall, må starte med en bokstav.",
        "3–20 символов, только буквы и цифры, начинается с буквы.",
        "3 – 20 znakova, samo slova i brojke, počinje slovom."),
    "friends.period.week": row("7 dage", "7 dager", "7 дней", "7 dana"),
    "friends.period.all": row("I alt", "Totalt", "Всё время", "Ukupno"),
    "friends.empty.title": row(
        "Ingen venner endnu", "Ingen venner ennå", "Друзей пока нет",
        "Još nema prijatelja"),
    "friends.empty.body": row(
        "Tilføj venner med deres @ for at sammenligne XP.",
        "Legg til venner med @-en deres for å sammenligne XP.",
        "Добавь друзей по @, чтобы сравнивать XP.",
        "Dodaj prijatelje preko @ da usporedite XP."),
    "friends.signedOut.title": row(
        "Log ind for venner", "Logg inn for venner", "Войди, чтобы добавлять друзей",
        "Prijavi se za prijatelje"),
    "friends.signedOut.body": row(
        "Opret en konto for at få et @ og tilføje venner.",
        "Opprett en konto for å få en @ og legge til venner.",
        "Создай аккаунт, чтобы получить @ и добавлять друзей.",
        "Otvori račun da dobiješ @ i dodaješ prijatelje."),
    "friends.remove": row(
        "Fjern ven", "Fjern venn", "Удалить из друзей", "Ukloni prijatelja"),
    "friends.remove.title": row(
        "Fjern denne ven?", "Fjerne denne vennen?", "Удалить этого друга?",
        "Ukloniti ovog prijatelja?"),
    "friends.remove.message": row(
        "Du kan tilføje vedkommende igen senere med @.",
        "Du kan legge vedkommende til igjen senere med @.",
        "Позже сможешь добавить его снова по @.",
        "Kasnije ga možeš ponovno dodati preko @."),
    "friends.remove.confirm": row("Fjern", "Fjern", "Удалить", "Ukloni"),
    "friends.stats.streak": row(
        "Dage i træk", "Dager på rad", "Дней подряд", "Dana zaredom"),
    "friends.stats.quizzes": row(
        "Gennemførte quizzer", "Fullførte quizer", "Тестов пройдено",
        "Završeni kvizovi"),
    "friends.error.generic": row(
        "Noget gik galt. Prøv igen.", "Noe gikk galt. Prøv igjen.",
        "Что-то пошло не так. Попробуй ещё раз.",
        "Nešto je pošlo po zlu. Pokušaj ponovno."),
    "friends.error.notSignedIn": row(
        "Log ind for at fortsætte.", "Logg inn for å fortsette.",
        "Войди, чтобы продолжить.", "Prijavi se za nastavak."),
    "friends.error.invalidHandle": row(
        "Dette @ er ikke gyldigt.", "Denne @-en er ikke gyldig.",
        "Такой @ недопустим.", "Ovaj @ nije valjan."),
    "friends.error.handleTaken": row(
        "Dette @ er allerede taget.", "Denne @-en er allerede tatt.",
        "Этот @ уже занят.", "Ovaj @ je već zauzet."),
    "friends.error.userNotFound": row(
        "Ingen bruger med dette @.", "Ingen bruker med denne @-en.",
        "Пользователь с таким @ не найден.", "Nema korisnika s tim @."),
    "friends.error.cannotAddSelf": row(
        "Du kan ikke tilføje dig selv.", "Du kan ikke legge til deg selv.",
        "Себя добавить нельзя.", "Ne možeš dodati sam sebe."),
    "friends.error.notFriends": row(
        "I er ikke venner.", "Dere er ikke venner.", "Вы не друзья.",
        "Niste prijatelji."),
    "quiz.feedback.correct": row("Rigtigt!", "Riktig!", "Верно!", "Točno!"),
    "quiz.feedback.excellent": row(
        "Fremragende!", "Utmerket!", "Отлично!", "Izvrsno!"),
    "quiz.feedback.amazing": row(
        "Vildt!", "Vilt!", "Невероятно!", "Nevjerojatno!"),
    "quiz.feedback.wrong": row(
        "Ikke helt...", "Ikke helt...", "Не совсем...", "Nije baš..."),
    "quiz.completed": row(
        "Flot, quizzen er færdig!", "Bra, quizen er ferdig!",
        "Отлично, тест пройден!", "Bravo, kviz je gotov!"),
    "quiz.correctAnswers": row(
        "rigtige svar", "riktige svar", "верных ответов", "točnih odgovora"),
})

# --- quiz results, course end, prepaywall, global ranks --------------------
# `globalRank.xpBefore` inserts a rank NAME after a preposition: Russian "до"
# and Croatian "do" both govern the genitive, so the frame says "до ранга %@" /
# "do ranga %@" and the name stays in its nominative dictionary form. Same
# reason `course.streak.message` puts the subject in apposition after
# "тема"/"tema" instead of inflecting it.
STRINGS.update({
    "quiz.xpProgress": row(
        "XP-fremgang", "XP-framgang", "Прогресс XP", "XP napredak"),
    "quiz.levelUp": row("Nyt niveau!", "Nytt nivå!", "Новый уровень!", "Nova razina!"),
    "quiz.breakdown.correct": row(
        "Rigtige svar", "Riktige svar", "Верные ответы", "Točni odgovori"),
    "quiz.breakdown.completed": row(
        "Quiz gennemført", "Quiz fullført", "Тест пройден", "Kviz završen"),
    "quiz.xpProgress.max": row(
        "%d XP · maks. niveau", "%d XP · maks nivå", "%d XP · макс. уровень",
        "%d XP · maks. razina"),
    "quiz.xpProgress.toNext": row(
        "%d XP til niv. %d", "%d XP til nivå %d", "%d XP до ур. %d",
        "%d XP do raz. %d"),
    "quiz.pointsEarned": row(
        "point optjent", "poeng opptjent", "очков получено", "osvojenih bodova"),
    "quiz.feedback.close": row("Næsten!", "Nesten!", "Почти!", "Skoro!"),
    "quiz.feedback.far": row("Tæt på", "Nære på", "Близко", "Blizu"),
    "quiz.trueFalse.true": row("Sandt", "Sant", "Верно", "Točno"),
    "quiz.trueFalse.false": row("Falsk", "Usant", "Неверно", "Netočno"),
    "quiz.chronological.instruction": row(
        "Sæt begivenhederne i kronologisk rækkefølge (tryk eller træk).",
        "Sett hendelsene i kronologisk rekkefølge (trykk eller dra).",
        "Расставь события в хронологическом порядке (нажми или перетащи).",
        "Poredaj događaje kronološki (dodirni ili povuci)."),
    "quiz.chronological.remaining": row(
        "Svar der mangler", "Svar som gjenstår", "Осталось расставить",
        "Preostali odgovori"),
    "quiz.chronological.emptySlot": row(
        "Tom plads", "Tom plass", "Пустое место", "Prazno mjesto"),
    "quiz.chronological.validate": row(
        "Bekræft rækkefølgen", "Bekreft rekkefølgen", "Проверить порядок",
        "Potvrdi redoslijed"),
    "quiz.chronological.correctOrder": row(
        "Rigtig rækkefølge", "Riktig rekkefølge", "Верный порядок",
        "Točan redoslijed"),
    "quiz.slider.validate": row("Bekræft", "Bekreft", "Проверить", "Potvrdi"),
    "quiz.slider.yourGuess": row(
        "Dit svar", "Svaret ditt", "Твой ответ", "Tvoj odgovor"),
    "quiz.slider.correctAnswer": row(
        "Rigtigt svar", "Riktig svar", "Верный ответ", "Točan odgovor"),
    "course.completed": row(
        "Kurset er gennemført!", "Kurset er fullført!", "Курс пройден!",
        "Tečaj je završen!"),
    "course.dailyFreeDone": row(
        "Du har gennemført dagens gratis kursus",
        "Du har fullført dagens gratis kurs",
        "Ты прошёл бесплатный курс на сегодня",
        "Završio si današnji besplatni tečaj"),
    "course.unlock.free": row(
        "Lås op gratis", "Lås opp gratis", "Открыть бесплатно",
        "Otključaj besplatno"),
    "course.quiz.access": row(
        "Åbn quizzen", "Åpne quizen", "Перейти к тесту", "Otvori kviz"),
    "course.unlock.cta": row(
        "Lås kurset op", "Lås opp kurset", "Открыть курс", "Otključaj tečaj"),
    "course.streak.day": row(
        "Dag i træk", "Dag på rad", "День подряд", "Dan zaredom"),
    "course.streak.days": row(
        "Dage i træk", "Dager på rad", "Дней подряд", "Dana zaredom"),
    "course.streak.message": row(
        "Du bliver virkelig skarp — snart er du uovervindelig i %@!",
        "Du blir virkelig skarp — snart er du uslåelig i %@!",
        "Ты реально прокачался — тема «%@» тебе уже по зубам!",
        "Stvarno napreduješ — tema „%@” ti više ne može ništa!"),
    "course.streak.onTrack": row(
        "På vej mod dage i træk!", "På vei mot dager på rad!",
        "Серия уже на подходе!", "Niz je na pomolu!"),
    "prepaywall.quiz.title": row(
        "Lås quizzerne op\ngratis", "Lås opp quizene\ngratis",
        "Открой тесты\nбесплатно", "Otključaj kvizove\nbesplatno"),
    "prepaywall.quiz.subtitle": row(
        "Test din viden og\nbliv bedre hver dag",
        "Test kunnskapen din og\nbli bedre hver dag",
        "Проверяй знания и\nрасти каждый день",
        "Provjeri znanje i\nnapreduj svaki dan"),
    "prepaywall.course.subtitle": row(
        "Bliv ved med at lære og\nopdag nye emner",
        "Fortsett å lære og\noppdag nye emner",
        "Продолжай учиться и\nоткрывай новые темы",
        "Nastavi učiti i\notkrivaj nove teme"),
    "prepaywall.course.access": row(
        "Åbn kurset", "Åpne kurset", "Перейти к курсу", "Otvori tečaj"),
    "levelUp.title": row(
        "Nyt niveau!", "Nytt nivå!", "Новый уровень!", "Nova razina!"),
    "globalRank.curieux": row(
        "Nysgerrig", "Nysgjerrig", "Любознательный", "Znatiželjnik"),
    "globalRank.erudit": row("Belæst", "Belest", "Эрудит", "Erudit"),
    "globalRank.savant": row("Lærd", "Lærd", "Знаток", "Učenjak"),
    "globalRank.maitre": row("Mester", "Mester", "Мастер", "Majstor"),
    "globalRank.legende": row("Legende", "Legende", "Легенда", "Legenda"),
    "globalRank.title": row(
        "Global rang", "Global rangering", "Общий ранг", "Globalni rang"),
    "globalRank.badge": row(
        "GLOBAL RANG", "GLOBAL RANGERING", "ОБЩИЙ РАНГ", "GLOBALNI RANG"),
    "globalRank.maxLevel": row(
        "Maks. niveau", "Maks nivå", "Макс. уровень", "Maks. razina"),
    "globalRank.xpBefore": row(
        "%d XP til %@", "%d XP til %@", "%d XP до ранга %@", "%d XP do ranga %@"),
    "globalRank.newRank": row(
        "Ny rang!", "Ny rangering!", "Новый ранг!", "Novi rang!"),
    "globalRank.reachedLevel": row(
        "Du har lige nået niveau %d", "Du nådde nettopp nivå %d",
        "Ты только что достиг уровня %d", "Upravo si dosegnuo razinu %d"),
    "paywall.unavailable.title": row(
        "Tilbud ikke tilgængeligt", "Tilbudet er utilgjengelig",
        "Предложение недоступно", "Ponuda nije dostupna"),
    "paywall.unavailable.message": row(
        "Tilbuddet kan ikke hentes lige nu.",
        "Tilbudet kan ikke lastes akkurat nå.",
        "Сейчас не удаётся загрузить это предложение.",
        "Trenutačno nije moguće učitati ovu ponudu."),
    "course.finish": row(
        "Afslut kurset", "Fullfør kurset", "Завершить курс", "Završi tečaj"),
    "course.funFact.hint": row(
        "Tryk for at afsløre", "Trykk for å avsløre", "Нажми, чтобы открыть",
        "Dodirni za otkrivanje"),
    "onboardingV2.pw.pro": row("PRO", "PRO", "PRO", "PRO"),
    "quiz.combo": row("Combo x%d", "Combo x%d", "Комбо x%d", "Combo x%d"),
})
