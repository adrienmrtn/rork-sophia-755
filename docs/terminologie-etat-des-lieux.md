# Terminologie : état des lieux au 27/10/2026

Étape 1 du plan de remise en ordre des traductions (voir `docs/audit-traductions-naturel.md`).
Ce document dit ce que le contrôle `scripts/check_terminology.py` trouve aujourd'hui dans l'app, avec les listes de `content/terminology/`. C'est l'entrée de l'étape 2 (corrections) et la base de la porte de sortie de l'étape 5.

## Ce qui a changé

- **Le français est la source de toute traduction.** `MT_SOURCE_LANG = "fr"` dans `scripts/i18n_languages.py`, lu par tous les pipelines. Les trois qui partaient encore de l'anglais sont retournés : chaînes d'interface, catalogue (glossaire, collections, index des cours), textes légaux iOS et Android. Traduire depuis l'anglais prenait les mots français dans leur sens anglais le plus fréquent (essai → *trial* → procès).
- **Trois listes, 26 langues** dans `content/terminology/` : 60 mots pièges (forme imposée et formes fautives), 20 termes produit (un terme canonique par langue et les variantes à remplacer), 68 titres d'œuvres (titre établi par langue). Remplies par un relecteur natif par langue à partir des constats de l'audit, puis vérifiées une à une sur leurs occurrences réelles par un second relecteur : 642 expressions retirées ou resserrées (`elagage.json`).
- **Un contrôle qui balaye tout** : chaînes iOS et Android, cours, quiz, glossaire, collections, catalogue, fiche App Store, textes légaux, dans les 26 langues, en un peu plus de 3 minutes.
- **Parité des clés avec le français** : douze clés mortes retirées des tables iOS, la QA des chaînes se compare désormais au français.

## Occurrences par langue et par surface

| Langue | Total | ui | store | catalogue | collections | cours | quiz | glossaire | legal |
|---|---|---|---|---|---|---|---|---|---|
| Finnois (`fi`) | **1321** | 146 | 2 | 55 | 3 | 977 | 100 | 37 | 1 |
| Russe (`ru`) | **1038** | 108 | 3 | 23 | 2 | 669 | 123 | 104 | 6 |
| Bulgare (`bg`) | **1003** | 133 | 0 | 45 | 2 | 559 | 116 | 142 | 6 |
| Serbe (`sr`) | **699** | 80 | 0 | 23 | 0 | 452 | 97 | 47 | 0 |
| Arabe (`ar`) | **610** | 336 | 4 | 17 | 1 | 142 | 74 | 30 | 6 |
| Hébreu (`he`) | **604** | 268 | 4 | 35 | 0 | 193 | 62 | 35 | 7 |
| Slovène (`sl`) | **522** | 74 | 2 | 35 | 0 | 304 | 73 | 33 | 1 |
| Croate (`hr`) | **484** | 68 | 1 | 15 | 0 | 324 | 53 | 22 | 1 |
| Estonien (`et`) | **471** | 102 | 0 | 30 | 0 | 243 | 67 | 24 | 5 |
| Norvégien (`nb`) | **414** | 85 | 2 | 33 | 0 | 148 | 108 | 35 | 3 |
| Polonais (`pl`) | **358** | 36 | 1 | 16 | 0 | 189 | 92 | 21 | 3 |
| Roumain (`ro`) | **352** | 160 | 4 | 14 | 0 | 61 | 82 | 28 | 3 |
| Slovaque (`sk`) | **309** | 88 | 2 | 18 | 0 | 115 | 61 | 24 | 1 |
| Danois (`da`) | **261** | 69 | 2 | 17 | 0 | 105 | 45 | 18 | 5 |
| Hongrois (`hu`) | **257** | 98 | 2 | 12 | 0 | 28 | 73 | 36 | 8 |
| Tchèque (`cs`) | **188** | 64 | 3 | 12 | 0 | 43 | 32 | 29 | 5 |
| Turc (`tr`) | **175** | 62 | 4 | 8 | 0 | 33 | 38 | 27 | 3 |
| Espagnol (`es`) | **167** | 74 | 1 | 7 | 2 | 25 | 31 | 27 | 0 |
| Suédois (`sv`) | **152** | 38 | 3 | 14 | 1 | 35 | 34 | 24 | 3 |
| Anglais (`en`) | **129** | 67 | 2 | 12 | 0 | 26 | 20 | 2 | 0 |
| Néerlandais (`nl`) | **119** | 30 | 2 | 5 | 0 | 27 | 36 | 17 | 2 |
| Italien (`it`) | **100** | 45 | 3 | 5 | 0 | 7 | 33 | 7 | 0 |
| Allemand (`de`) | **79** | 47 | 1 | 3 | 0 | 4 | 21 | 3 | 0 |
| Grec (`el`) | **68** | 24 | 1 | 1 | 0 | 7 | 19 | 16 | 0 |
| Portugais (BR) (`pt`) | **64** | 49 | 1 | 5 | 0 | 4 | 4 | 1 | 0 |
| Portugais (PT) (`pt-PT`) | **41** | 22 | 1 | 4 | 0 | 5 | 7 | 2 | 0 |

Total : 9 985 occurrences. Les cours concentrent l'essentiel, en tête les langues sans guide de traduction (finnois, russe, serbe) et le bulgare, dont les siècles sont écrits « 20. век ».

## Les règles qui touchent le plus

| Règle | Type | Occurrences | Langues |
|---|---|---|---|
| « En 622 » / « Vers 630 » : la date avec le mot ou la forme que la lan | mot piège | 2416 | 15 |
| Cours (une leçon de 10 minutes ; l'unité de contenu) | terme produit | 719 | 23 |
| razzia, jizya, calife, dhimma, Oumma (termes de glossaire du cours sur | mot piège | 675 | 22 |
| VIIe siècle (de 601 à 700) : forme locale exacte, sans décalage | mot piège | 621 | 8 |
| « On » impersonnel (On veut le tuer ; On y vit en tribus) : tournure i | mot piège | 599 | 12 |
| Quiz (questionnaire de fin de cours ; mini quiz) | terme produit | 215 | 10 |
| Essai gratuit (période d'essai de l'abonnement) | terme produit | 191 | 19 |
| Voici comment… / Voici ce que… (phrase d'annonce) | mot piège | 185 | 16 |
| Spleen (Baudelaire : mélancolie ; titre de section « Spleen et Idéal » | mot piège | 174 | 21 |
| Parcours (onglet : chemin de progression thématique) | terme produit | 159 | 17 |
| Sophia (marque : jamais translittérée ; déclinée seulement si la langu | terme produit | 133 | 5 |
| l'offre (écran d'abonnement ; le code dit « paywall ») | mot piège | 113 | 23 |
| Essai gratuit (période d'essai de l'abonnement) | mot piège | 109 | 11 |
| Médée | titre d'œuvre | 102 | 8 |
| Premium (nom de l'offre : conservé tel quel, jamais traduit ni transli | mot piège | 98 | 8 |
| Bloqueur (TikTok blocker : fonction qui verrouille TikTok) | terme produit | 96 | 24 |
| Le Père Goriot | titre d'œuvre | 91 | 17 |
| Impression, soleil levant | titre d'œuvre | 89 | 21 |
| Les Demoiselles d'Avignon | titre d'œuvre | 84 | 13 |
| Matière (histoire, sciences… ; distinct de « sujet ») | terme produit | 83 | 8 |

Les trois premières sont mécaniques et se corrigent par script à l'étape 2 : la date sans le mot « année » ou avec la préposition calquée (« U 1857 », « В 1857 », « 1857:ssä »), les termes de glossaire collés à un suffixe (« **Badr**:ssä ») ou laissés en latin, les siècles mal écrits ou décalés. Le « on » rendu par « nous » demande un relecteur.

## Contresens de l'interface et de la fiche App Store à corriger en premier

Ce sont les chaînes que tout utilisateur voit (onboarding, paywall, réglages, fiche du store). Liste complète, une ligne par clé et par règle ; le détail avec contexte est dans `docs/audit-traductions/_terminologie_occurrences.json`.

| Langue | Clé | Texte trouvé | Forme imposée |
|---|---|---|---|
| he | `offer.unlock` | בטל את הנעילה | לפתוח / פתיחה (impératif «פתח את הקורס», «פתח את Premium») |
| he | `onboarding.intro.title` | תהיה מתורבת | ידע כללי ; cultivé = משכיל («הפוך למשכיל באמת») |
| he | `onboarding.phone.intensity.light` | אור | קל (échelle : קל / מתון / אינטנסיבי) |
| he | `onboarding.premiumTrial.step1.title` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `onboarding.showcase.quiz.option.1` | אור | קל (échelle : קל / מתון / אינטנסיבי) |
| he | `onboarding.trial.trialEnds` | המשפט מסתיים | ניסיון חינם (תקופת ניסיון חינם; «סיום תקופת הניסיון») |
| he | `onboardingV2.exams.author2` | שנה בוגרת | י״ב (signature : «אינס, י״ב») |
| he | `onboardingV2.exams.quote1` | קדנציה | סמסטר (témoignage scolaire : «בסמסטר הזה» ; מחצית acceptable |
| he | `onboardingV2.exams.quote2` | אני משנה 10 דקות | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| he | `onboardingV2.exams.quote4` | מושלם לתיקון | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| he | `onboardingV2.pw.priceNoTrial` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `onboardingV2.screenTime.title` | קח את הזמן שלך אחורה | קח בחזרה את הזמן שלך (ou neutre : «הזמן שלך חוזר אליך») |
| he | `paywall.discount.subtitle` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.error.unavailable` | חומת תשלום | ההצעה (écran d'abonnement : «לא ניתן לטעון את ההצעה») |
| he | `paywall.lockedSubjectsWithPremium` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.plan.monthly` | ירחון | חודשי (מנוי חודשי) |
| he | `paywall.premiumColumn` | פרמיה | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.teaserSubtitle` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.trial.todayDetail` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.ambassador.banner.badge` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.premium.title` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.section.premium` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `training.how.step3` | בדוק אותם בזמן | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| he | `offer.unlock` | בטל את הנעילה | לפתוח / פתיחה (impératif «פתח את הקורס», «פתח את Premium») |
| he | `onboarding.intro.title` | תהיה מתורבת | ידע כללי ; cultivé = משכיל («הפוך למשכיל באמת») |
| he | `onboarding.phone.intensity.light` | אור | קל (échelle : קל / מתון / אינטנסיבי) |
| he | `onboarding.premiumTrial.step1.title` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `onboarding.showcase.quiz.option.1` | אור | קל (échelle : קל / מתון / אינטנסיבי) |
| he | `onboarding.trial.trialEnds` | המשפט מסתיים | ניסיון חינם (תקופת ניסיון חינם; «סיום תקופת הניסיון») |
| he | `onboardingV2.exams.author2` | שנה בוגרת | י״ב (signature : «אינס, י״ב») |
| he | `onboardingV2.exams.quote1` | קדנציה | סמסטר (témoignage scolaire : «בסמסטר הזה» ; מחצית acceptable |
| he | `onboardingV2.exams.quote2` | אני משנה 10 דקות | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| he | `onboardingV2.exams.quote4` | מושלם לתיקון | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| he | `onboardingV2.pw.priceNoTrial` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `onboardingV2.screenTime.title` | קח את הזמן שלך אחורה | קח בחזרה את הזמן שלך (ou neutre : «הזמן שלך חוזר אליך») |
| he | `paywall.discount.subtitle` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.error.unavailable` | חומת תשלום | ההצעה (écran d'abonnement : «לא ניתן לטעון את ההצעה») |
| he | `paywall.lockedSubjectsWithPremium` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.plan.monthly` | ירחון | חודשי (מנוי חודשי) |
| he | `paywall.premiumColumn` | פרמיה | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.teaserSubtitle` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `paywall.trial.todayDetail` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.ambassador.banner.badge` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.debug.audioPaywall` | חומת התשלום | ההצעה (écran d'abonnement : «לא ניתן לטעון את ההצעה») |
| he | `settings.premium.title` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `settings.section.premium` | פרימיום | Premium (en lettres latines, invariable : «שדרג ל-Premium»,  |
| he | `training.how.step3` | בדוק אותם בזמן | לחזור על החומר / חזרה (scolaire : «חזרה על החומר 10 דקות ביו |
| ar | `ambassador.bonus` | بريميوم | Premium |
| ar | `course.unlock.cta` | فتح الدورة | افتح قفل |
| ar | `offer.feature1` | المعرفة العامة | الثقافة العامة (مثقّف) |
| ar | `onboarding.phone.intensity.light` | ضوء | خفيف |
| ar | `onboarding.showcase.quiz.option.1` | ضوء | خفيف |
| ar | `onboarding.trial.trialEnds` | تنتهي المحاكمة | التجربة المجانية |
| ar | `onboardingV2.screenTime.title` | خذ وقتك إلى الوراء | استعد وقتك لنفسك |
| ar | `onboardingV2.trial.title` | النسخة التجريبية | التجربة المجانية |
| ar | `paywall.course.proPitch` | افتح Sophia PRO | افتح قفل |
| ar | `paywall.course.stat.caption` | بريميوم | Premium |
| ar | `paywall.discount.noTrial` | نسخة تجريبية | التجربة المجانية |
| ar | `paywall.error.unavailable` | نظام حظر الاشتراك | العرض |
| ar | `paywall.freeColumn` | حر | مجاني |
| ar | `paywall.header` | للاهتمام
في الغرفة | أكثر شخص مثير للاهتمام بين الحاضرين |
| ar | `paywall.premiumColumn` | غالي | Premium |
| ar | `paywall.premiumHeadline` | افتح Premium | افتح قفل |
| ar | `paywall.price.trialThenYearly` | نسخة تجريبية | التجربة المجانية |
| ar | `paywall.quiz.faq.a3` | النسخة التجريبية | التجربة المجانية |
| ar | `paywall.quiz.subtitle` | افتح Sophia PRO | افتح قفل |
| ar | `paywall.trial.reminderDetail` | النسخة التجريبية | التجربة المجانية |
| ar | `paywall.trial.todayDetail` | الميزات المميزة | Premium |
| ar | `paywall.trialSheet.start` | النسخة التجريبية | التجربة المجانية |
| ar | `profile.quiz.lockedSubtitle` | الإصدار التجريبي | التجربة المجانية |
| ar | `profile.unlock.trial` | النسخة التجريبية | التجربة المجانية |
| ar | `settings.ambassador.banner.badge` | بريميوم | Premium |
| ar | `settings.premium.title` | بريميوم | Premium |
| ar | `settings.section.premium` | بريميوم | Premium |
| ar | `training.how.step2` | ممارستك | التدريب |
| ar | `ar-SA/description` | المعرفة العامة | الثقافة العامة (مثقّف) |
| ar | `ambassador.bonus` | بريميوم | Premium |
| ar | `course.unlock.cta` | فتح الدورة | افتح قفل |
| ar | `offer.feature1` | المعرفة العامة | الثقافة العامة (مثقّف) |
| ar | `onboarding.phone.intensity.light` | ضوء | خفيف |
| ar | `onboarding.showcase.quiz.option.1` | ضوء | خفيف |
| ar | `onboarding.trial.trialEnds` | تنتهي المحاكمة | التجربة المجانية |
| ar | `onboardingV2.screenTime.title` | خذ وقتك إلى الوراء | استعد وقتك لنفسك |
| ar | `onboardingV2.trial.title` | النسخة التجريبية | التجربة المجانية |
| ar | `paywall.course.proPitch` | افتح Sophia PRO | افتح قفل |
| ar | `paywall.discount.noTrial` | نسخة تجريبية | التجربة المجانية |
| ar | `paywall.error.unavailable` | نظام حظر الاشتراك | العرض |
| ar | `paywall.freeColumn` | حر | مجاني |
| ar | `paywall.header` | للاهتمام
في الغرفة | أكثر شخص مثير للاهتمام بين الحاضرين |
| ar | `paywall.premiumColumn` | غالي | Premium |
| ar | `paywall.premiumHeadline` | افتح Premium | افتح قفل |
| ar | `paywall.price.trialThenYearly` | نسخة تجريبية | التجربة المجانية |
| ar | `paywall.quiz.subtitle` | افتح Sophia PRO | افتح قفل |
| ar | `paywall.trial.reminderDetail` | النسخة التجريبية | التجربة المجانية |
| ar | `paywall.trial.todayDetail` | الميزات المميزة | Premium |
| ar | `paywall.trialSheet.start` | النسخة التجريبية | التجربة المجانية |
| ar | `profile.quiz.lockedSubtitle` | الإصدار التجريبي | التجربة المجانية |
| ar | `profile.unlock.trial` | النسخة التجريبية | التجربة المجانية |
| ar | `settings.ambassador.banner.badge` | بريميوم | Premium |
| ar | `settings.debug.audioPaywall` | جدار الدفع | العرض |
| ar | `settings.premium.title` | بريميوم | Premium |
| ar | `settings.section.premium` | بريميوم | Premium |
| ar | `training.how.step2` | ممارستك | التدريب |
| et | `home.swipe.subtitle` | pühi | Libista, et avastada |
| et | `offer.expiresIn` | Aegub aastal | Lõpeb (silt enne tagasiloendust: „Lõpeb 02:59:59“) |
| et | `onboarding.phone.intensity.light` | Valgus | Kerge (Kerge / Mõõdukas / Intensiivne) |
| et | `onboarding.premiumTrial.cta` | Alusta minu kohtuprotsessi | tasuta prooviperiood (CTA: „Alusta prooviperioodi“; „Proovip |
| et | `onboarding.showcase.quiz.option.1` | Valgus | Kerge (Kerge / Mõõdukas / Intensiivne) |
| et | `onboarding.trial.trialEnds` | Kohtuprotsess lõppeb | tasuta prooviperiood (CTA: „Alusta prooviperioodi“; „Proovip |
| et | `onboardingV2.exams.author2` | vanem kursus | 12. klass („Inès, 12. klass“) |
| et | `onboardingV2.exams.quote1` | sel ametiajal | veerand (sel veerandil) |
| et | `onboardingV2.exams.quote2` | vaatan 10 minutit | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `onboardingV2.exams.quote4` | ülevaatamiseks | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `onboardingV2.pw.priceNoTrial` | Lisatasu | Premium (muutumatu ladina kujul; käändelõpp ilma ülakomata:  |
| et | `onboardingV2.swipe.subtitle` | Pühi | Libista, et avastada |
| et | `paywall.error.unavailable` | Paywalli | pakkumine („Pakkumist ei saa laadida“) |
| et | `paywall.freeSubjects` | vaba ainet | Tasuta |
| et | `paywall.review4.quote` | anekdoodid | põnevad faktid |
| et | `paywall.training.how.step3` | Vaata üle | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `paywall.training.stat2.label` | ülevaatamiseta | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `training.emptyMessage` | ülevaatamist | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `training.how.step2` | praktikaga | Harjutamine (vahekaart; „lisanduvad sinu Harjutamisse“) |
| et | `home.swipe.subtitle` | pühi | Libista, et avastada |
| et | `offer.expiresIn` | Aegub aastal | Lõpeb (silt enne tagasiloendust: „Lõpeb 02:59:59“) |
| et | `onboarding.phone.intensity.light` | Valgus | Kerge (Kerge / Mõõdukas / Intensiivne) |
| et | `onboarding.premiumTrial.cta` | Alusta minu kohtuprotsessi | tasuta prooviperiood (CTA: „Alusta prooviperioodi“; „Proovip |
| et | `onboarding.showcase.quiz.option.1` | Valgus | Kerge (Kerge / Mõõdukas / Intensiivne) |
| et | `onboarding.trial.trialEnds` | Kohtuprotsess lõppeb | tasuta prooviperiood (CTA: „Alusta prooviperioodi“; „Proovip |
| et | `onboardingV2.exams.author2` | vanem kursus | 12. klass („Inès, 12. klass“) |
| et | `onboardingV2.exams.quote1` | sel ametiajal | veerand (sel veerandil) |
| et | `onboardingV2.exams.quote2` | vaatan 10 minutit | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `onboardingV2.exams.quote4` | ülevaatamiseks | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `onboardingV2.pw.priceNoTrial` | Lisatasu | Premium (muutumatu ladina kujul; käändelõpp ilma ülakomata:  |
| et | `onboardingV2.swipe.subtitle` | Pühi | Libista, et avastada |
| et | `paywall.error.unavailable` | Paywalli | pakkumine („Pakkumist ei saa laadida“) |
| et | `paywall.freeSubjects` | vaba ainet | Tasuta |
| et | `paywall.review4.quote` | anekdoodid | põnevad faktid |
| et | `paywall.training.how.step3` | Vaata üle | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `paywall.training.stat2.label` | ülevaatamiseta | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `settings.debug.audioPaywall` | maksemüüri | pakkumine („Pakkumist ei saa laadida“) |
| et | `settings.debug.courseUnlockPaywall` | paywall | pakkumine („Pakkumist ei saa laadida“) |
| et | `settings.debug.discountPaywall` | paywall | pakkumine („Pakkumist ei saa laadida“) |
| et | `settings.debug.quizPaywall` | paywall | pakkumine („Pakkumist ei saa laadida“) |
| et | `training.emptyMessage` | ülevaatamist | Korda / kordamine („Kordan 10 minutit päevas“, „kui seda ei  |
| et | `training.how.step2` | praktikaga | Harjutamine (vahekaart; „lisanduvad sinu Harjutamisse“) |
| fi | `course.unlock.free` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `onboarding.premiumTrial.cta` | Aloita oikeudenkäyntini | ilmainen kokeilu (jakso : kokeilujakso ; « Aloita kokeilujak |
| fi | `onboarding.showcase.courses.swipe` | PYYHÄVÄ | Pyyhkäise ja tutustu (bouton : PYYHKÄISE JA TUTUSTU) |
| fi | `onboarding.trial.trialEnds` | Oikeudenkäynti päättyy | ilmainen kokeilu (jakso : kokeilujakso ; « Aloita kokeilujak |
| fi | `onboardingV2.exams.author2` | vanhempi vuosi | abiturientti (abi) — « Inès, abiturientti » |
| fi | `onboardingV2.exams.quote2` | Tarkastelen 10 minuuttia | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| fi | `onboardingV2.exams.quote4` | tarkistamiseen | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| fi | `paywall.cta.unlockFree` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `paywall.error.unavailable` | Maksumuurin | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `paywall.freeSubjects` | vapaata aihettasi | Ilmainen (colonne : Ilmainen / Premium) |
| fi | `paywall.review2.quote` | rullaamisen kulttuuriksi | yleissivistys (adj. : sivistynyt ; « kasvattaa sivistystäsi  |
| fi | `paywall.trial.in2days` | 2 päivässä | Aikaa jäljellä (étiquette devant un compte à rebours) ; duré |
| fi | `paywall.trial.in3days` | 3 päivässä | Aikaa jäljellä (étiquette devant un compte à rebours) ; duré |
| fi | `profile.unlock.trial` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `training.how.step2` | käytäntöösi | Harjoittelu (onglet ; « siirtyvät Harjoitteluusi ») |
| fi | `training.how.step3` | Tarkista ne | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| fi | `course.unlock.free` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `onboarding.premiumTrial.cta` | Aloita oikeudenkäyntini | ilmainen kokeilu (jakso : kokeilujakso ; « Aloita kokeilujak |
| fi | `onboarding.showcase.courses.swipe` | PYYHÄVÄ | Pyyhkäise ja tutustu (bouton : PYYHKÄISE JA TUTUSTU) |
| fi | `onboarding.trial.trialEnds` | Oikeudenkäynti päättyy | ilmainen kokeilu (jakso : kokeilujakso ; « Aloita kokeilujak |
| fi | `onboardingV2.exams.author2` | vanhempi vuosi | abiturientti (abi) — « Inès, abiturientti » |
| fi | `onboardingV2.exams.quote2` | Tarkastelen 10 minuuttia | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| fi | `onboardingV2.exams.quote4` | tarkistamiseen | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| fi | `paywall.cta.unlockFree` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `paywall.error.unavailable` | Maksumuurin | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `paywall.freeSubjects` | vapaata aihettasi | Ilmainen (colonne : Ilmainen / Premium) |
| fi | `paywall.review2.quote` | rullaamisen kulttuuriksi | yleissivistys (adj. : sivistynyt ; « kasvattaa sivistystäsi  |
| fi | `paywall.trial.in2days` | 2 päivässä | Aikaa jäljellä (étiquette devant un compte à rebours) ; duré |
| fi | `paywall.trial.in3days` | 3 päivässä | Aikaa jäljellä (étiquette devant un compte à rebours) ; duré |
| fi | `profile.unlock.trial` | Avaa lukitus | Avaa (Avaa Premium, Avaa kurssi) ; infinitif avata |
| fi | `settings.debug.audioPaywall` | maksumuuri | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `settings.debug.courseUnlockPaywall` | paywall | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `settings.debug.discountPaywall` | paywall | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `settings.debug.quizPaywall` | paywall | tarjous (Premium-tarjous ; « Katso tarjous ») — jamais maksu |
| fi | `training.how.step2` | käytäntöösi | Harjoittelu (onglet ; « siirtyvät Harjoitteluusi ») |
| fi | `training.how.step3` | Tarkista ne | kerrata (nom : kertaus ; « Kertaa 10 minuuttia päivässä ») |
| ru | `offer.feature1` | общей культуре | Эрудиция (cultivé → эрудированный) |
| ru | `onboarding.premiumTrial.badge` | Бесплатный период | Пробный период |
| ru | `onboarding.premiumTrial.cta` | бесплатный период | Пробный период |
| ru | `onboarding.premiumTrial.title` | бесплатный период | Пробный период |
| ru | `onboarding.trial.notifyTitle` | бесплатного периода | Пробный период |
| ru | `paywall.cta.activateTrial` | бесплатный период | Пробный период |
| ru | `paywall.header` | интересным человеком
в комнате | самый интересный человек в любой компании |
| ru | `paywall.quiz.faq.a3` | бесплатного периода | Пробный период |
| ru | `paywall.trialSheet.start` | бесплатный период | Пробный период |
| ru | `paywall.trialSheet.title` | бесплатный
период | Пробный период |
| ru | `profile.quiz.lockedSubtitle` | бесплатным периодом | Пробный период |
| ru | `profile.unlock.trial` | бесплатным периодом | Пробный период |
| ru | `offer.feature1` | общей культуре | Эрудиция (cultivé → эрудированный) |
| ru | `onboarding.premiumTrial.badge` | Бесплатный период | Пробный период |
| ru | `onboarding.premiumTrial.cta` | бесплатный период | Пробный период |
| ru | `onboarding.premiumTrial.title` | бесплатный период | Пробный период |
| ru | `onboarding.trial.notifyTitle` | бесплатного периода | Пробный период |
| ru | `paywall.cta.activateTrial` | бесплатный период | Пробный период |
| ru | `paywall.header` | интересным человеком
в комнате | самый интересный человек в любой компании |
| ru | `paywall.trialSheet.start` | бесплатный период | Пробный период |
| ru | `paywall.trialSheet.title` | бесплатный
период | Пробный период |
| ru | `profile.quiz.lockedSubtitle` | бесплатным периодом | Пробный период |
| ru | `profile.unlock.trial` | бесплатным периодом | Пробный период |
| ru | `settings.debug.audioPaywall` | paywall | Подписка |
| ru | `settings.debug.courseUnlockPaywall` | пейволл | Подписка |
| ru | `settings.debug.discountPaywall` | пейволл | Подписка |
| ru | `settings.debug.quizPaywall` | пейволл | Подписка |
| ru | `ru/description` | стать более культурным | Эрудиция (cultivé → эрудированный) |
| sl | `onboarding.showcase.courses.swipe` | PODRSAJ ZA ODKRIVANJE | Podrsaj in odkrij |
| sl | `onboardingV2.review.title` | Evo | Pravilo: »Takole …« / »Tako …« + glagol (»Takole deluje:«, » |
| sl | `onboardingV2.screenTime.title` | Vzemi si čas nazaj | Vzemi si spet čas zase |
| sl | `paywall.header` | najzanimivejša oseba
v prostoru | najbolj zanimiva oseba v družbi |
| sl | `onboarding.showcase.courses.swipe` | PODRSAJ ZA ODKRIVANJE | Podrsaj in odkrij |
| sl | `onboardingV2.review.title` | Evo | Pravilo: »Takole …« / »Tako …« + glagol (»Takole deluje:«, » |
| sl | `onboardingV2.screenTime.title` | Vzemi si čas nazaj | Vzemi si spet čas zase |
| sl | `paywall.header` | najzanimivejša oseba
v prostoru | najbolj zanimiva oseba v družbi |
| sl | `settings.debug.audioPaywall` | paywall | Ponudba |
| sl | `settings.debug.courseUnlockPaywall` | paywall | Ponudba |
| sl | `settings.debug.discountPaywall` | paywall | Ponudba |
| sl | `settings.debug.quizPaywall` | paywall | Ponudba |
| sl | `sl-SI/description` | kultivirana | splošna razgledanost (cultivé: razgledan / razgledana) |
| sk | `course.streak.onTrack` | Séria je na spadnutie | séria (dní v rade) — „Tvoja séria: 5 dní“ |
| sk | `onboarding.graph.title` | rastie
tvoje vedomie | všeobecný rozhľad (cultivé: „rozhľadený“) — „Takto rastie tv |
| sk | `onboarding.premiumTrial.badge` | Bezplatná skúška | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `onboarding.premiumTrial.cta` | Spustiť skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `onboarding.premiumTrial.title` | bezplatná skúška | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.cta.activateTrial` | bezplatnú skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trial.reminderDetail` | koncom skúšky | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trialSheet.start` | Spustiť bezplatnú skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trialSheet.title` | Začni bezplatnú
skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `profile.quiz.lockedSubtitle` | bezplatnou skúškou | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `profile.unlock.trial` | bezplatnou skúškou | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `course.streak.onTrack` | Séria je na spadnutie | séria (dní v rade) — „Tvoja séria: 5 dní“ |
| sk | `onboarding.graph.title` | rastie
tvoje vedomie | všeobecný rozhľad (cultivé: „rozhľadený“) — „Takto rastie tv |
| sk | `onboarding.premiumTrial.badge` | Bezplatná skúška | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `onboarding.premiumTrial.cta` | Spustiť skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `onboarding.premiumTrial.title` | bezplatná skúška | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.cta.activateTrial` | bezplatnú skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trial.reminderDetail` | koncom skúšky | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trialSheet.start` | Spustiť bezplatnú skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `paywall.trialSheet.title` | Začni bezplatnú
skúšku | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `profile.quiz.lockedSubtitle` | bezplatnou skúškou | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `profile.unlock.trial` | bezplatnou skúškou | Skúšobné obdobie zadarmo (tlačidlo: „Vyskúšať zadarmo“) |
| sk | `settings.debug.audioPaywall` | paywall | ponuka (obrazovka predplatného: „Ponuka Premium“) |
| sk | `settings.debug.courseUnlockPaywall` | paywall | ponuka (obrazovka predplatného: „Ponuka Premium“) |
| sk | `settings.debug.discountPaywall` | paywall | ponuka (obrazovka predplatného: „Ponuka Premium“) |
| sk | `settings.debug.quizPaywall` | paywall | ponuka (obrazovka predplatného: „Ponuka Premium“) |
| hr | `audio.downloads.footer` | bez veze | Nema internetske veze |
| hr | `offer.expiresIn` | Ističe za | Istječe za ({n} d {n} h) |
| hr | `onboarding.showcase.courses.swipe` | PREVUCI ZA OTKRIVANJE | Prevuci i otkrij |
| hr | `paywall.error.network` | Nema veze | Nema internetske veze |
| hr | `audio.downloads.footer` | bez veze | Nema internetske veze |
| hr | `offer.expiresIn` | Ističe za | Istječe za ({n} d {n} h) |
| hr | `onboarding.showcase.courses.swipe` | PREVUCI ZA OTKRIVANJE | Prevuci i otkrij |
| sr | `audio.downloads.footer` | bez veze | Nema interneta |
| sr | `paywall.error.network` | Nema veze | Nema interneta |
| sr | `audio.downloads.footer` | bez veze | Nema interneta |
| sr | `settings.debug.audioPaywall` | paywall | ponuda (ekran ponude; „Pogledaj ponudu“) |
| sr | `settings.debug.courseUnlockPaywall` | paywall | ponuda (ekran ponude; „Pogledaj ponudu“) |
| sr | `settings.debug.discountPaywall` | paywall | ponuda (ekran ponude; „Pogledaj ponudu“) |
| sr | `settings.debug.quizPaywall` | paywall | ponuda (ekran ponude; „Pogledaj ponudu“) |
| da | `settings.debug.audioPaywall` | paywall | tilbuddet (fx »Se tilbuddet«) ; en interne : abonnementsskær |
| da | `settings.debug.courseUnlockPaywall` | paywallen | tilbuddet (fx »Se tilbuddet«) ; en interne : abonnementsskær |
| da | `settings.debug.discountPaywall` | paywallen | tilbuddet (fx »Se tilbuddet«) ; en interne : abonnementsskær |
| da | `settings.debug.quizPaywall` | paywallen | tilbuddet (fx »Se tilbuddet«) ; en interne : abonnementsskær |
| nb | `onboarding.premiumTrial.badge` | Gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `onboarding.premiumTrial.cta` | Start prøven | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.discount.noTrial` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.price.trialThenYearly` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.trialBadge` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.trialSheet.start` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `onboarding.premiumTrial.badge` | Gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `onboarding.premiumTrial.cta` | Start prøven | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.discount.noTrial` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.price.trialThenYearly` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.trialBadge` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `paywall.trialSheet.start` | gratis prøve | gratis prøveperiode (knapp: «Start prøveperioden») |
| nb | `settings.debug.audioPaywall` | paywall | tilbudet / abonnementssiden (aldri «betalingsmur») |
| nb | `settings.debug.courseUnlockPaywall` | paywallen | tilbudet / abonnementssiden (aldri «betalingsmur») |
| nb | `settings.debug.discountPaywall` | paywallen | tilbudet / abonnementssiden (aldri «betalingsmur») |
| nb | `settings.debug.quizPaywall` | paywallen | tilbudet / abonnementssiden (aldri «betalingsmur») |
| bg | `onboarding.graph.title` | културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `onboarding.premiumTrial.badge` | пробна версия | Безплатен пробен период |
| bg | `onboarding.premiumTrial.step1.title` | Премиум | Premium |
| bg | `onboardingV2.exams.author2` | последен клас | 12-и клас |
| bg | `onboardingV2.screenTime.title` | Вземи си времето обратно | Върни си времето |
| bg | `path.quiz.review` | Прегледай курсовете | Преговори (преговор на курсовете) |
| bg | `paywall.discount.subtitle` | Премиум | Premium |
| bg | `paywall.header` | интересният
човек
в стаята | най-интересният човек в компанията |
| bg | `paywall.premiumColumn` | Премиум | Premium |
| bg | `paywall.quiz.review3.quote` | по-културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `paywall.quiz.subtitle` | културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `paywall.review4.quote` | анекдоти | любопитни факти |
| bg | `paywall.reviews.r3.quote` | по-културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `settings.section.premium` | Премиум | Premium |
| bg | `share.message` | по-културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `onboarding.graph.title` | културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `onboarding.premiumTrial.badge` | пробна версия | Безплатен пробен период |
| bg | `onboarding.premiumTrial.step1.title` | Премиум | Premium |
| bg | `onboardingV2.exams.author2` | последен клас | 12-и клас |
| bg | `onboardingV2.screenTime.title` | Вземи си времето обратно | Върни си времето |
| bg | `path.quiz.review` | Прегледай курсовете | Преговори (преговор на курсовете) |
| bg | `paywall.discount.subtitle` | Премиум | Premium |
| bg | `paywall.header` | интересният
човек
в стаята | най-интересният човек в компанията |
| bg | `paywall.premiumColumn` | Премиум | Premium |
| bg | `paywall.quiz.subtitle` | културен | Обща култура (знание); за „cultivé“: начетен, образован |
| bg | `paywall.review4.quote` | анекдоти | любопитни факти |
| bg | `settings.debug.audioPaywall` | paywall | офертата (екранът за абонамент) |
| bg | `settings.debug.courseUnlockPaywall` | paywall | офертата (екранът за абонамент) |
| bg | `settings.debug.discountPaywall` | paywall | офертата (екранът за абонамент) |
| bg | `settings.debug.quizPaywall` | paywall | офертата (екранът за абонамент) |
| bg | `settings.section.premium` | Премиум | Premium |
| bg | `share.message` | по-културен | Обща култура (знание); за „cultivé“: начетен, образован |
| tr | `ambassador.form.presentation.placeholder` | Genel bilgi | genel kültür / kültürlü («240 genel kültür kursu», «gerçekte |
| tr | `offer.feature1` | genel bilgi | genel kültür / kültürlü («240 genel kültür kursu», «gerçekte |
| tr | `paywall.error.unavailable` | Ödeme duvarı | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `paywall.header` | Odadaki en
ilginç | ortamın en ilginç insanı |
| tr | `ambassador.form.presentation.placeholder` | Genel bilgi | genel kültür / kültürlü («240 genel kültür kursu», «gerçekte |
| tr | `offer.feature1` | genel bilgi | genel kültür / kültürlü («240 genel kültür kursu», «gerçekte |
| tr | `paywall.error.unavailable` | Ödeme duvarı | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `paywall.header` | Odadaki en
ilginç | ortamın en ilginç insanı |
| tr | `settings.debug.audioPaywall` | paywall | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `settings.debug.courseUnlockPaywall` | paywall | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `settings.debug.discountPaywall` | paywall | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `settings.debug.quizPaywall` | paywall | Teklif (« Teklif yüklenemedi », « Teklifi gör ») |
| tr | `tr/description` | Genel Bilgi | genel kültür / kültürlü («240 genel kültür kursu», «gerçekte |
| ro | `offer.feature1` | cunoștințe generale | cultură generală / (devino mai) cult |
| ro | `onboarding.trial.trialEnds` | Procesul se termină | Probă gratuită (badge) / proba gratuită se termină (prose) |
| ro | `onboardingV2.screenTime.title` | Ia-ți timpul | Recuperează-ți timpul |
| ro | `paywall.header` | persoană
din cameră | din încăpere (« cea mai interesantă persoană din încăpere ») |
| ro | `paywall.trial.reminderDetail` | încheierea procesului | Probă gratuită (badge) / proba gratuită se termină (prose) |
| ro | `offer.feature1` | cunoștințe generale | cultură generală / (devino mai) cult |
| ro | `onboarding.trial.trialEnds` | Procesul se termină | Probă gratuită (badge) / proba gratuită se termină (prose) |
| ro | `onboardingV2.screenTime.title` | Ia-ți timpul | Recuperează-ți timpul |
| ro | `paywall.header` | persoană
din cameră | din încăpere (« cea mai interesantă persoană din încăpere ») |
| ro | `paywall.trial.reminderDetail` | încheierea procesului | Probă gratuită (badge) / proba gratuită se termină (prose) |
| ro | `settings.debug.audioPaywall` | paywallul | oferta (écran d'abonnement : « Nu am putut încărca oferta ») |
| ro | `settings.debug.courseUnlockPaywall` | paywallul | oferta (écran d'abonnement : « Nu am putut încărca oferta ») |
| ro | `settings.debug.discountPaywall` | paywallul | oferta (écran d'abonnement : « Nu am putut încărca oferta ») |
| ro | `settings.debug.quizPaywall` | paywallul | oferta (écran d'abonnement : « Nu am putut încărca oferta ») |
| ro | `ro/description` | General Knowledge | cultură generală / (devino mai) cult |
| pl | `onboardingV2.trial.step2.title` | wersji próbnej | Bezpłatny okres próbny (przycisk: „Wypróbuj za darmo”) |
| pl | `settings.streak.title` | passa | Seria (« Seria: 5 dni ») |
| pl | `settings.streak.title.few` | passa | Seria (« Seria: 5 dni ») |
| pl | `settings.streak.title.many` | passa | Seria (« Seria: 5 dni ») |
| pl | `settings.streak.title.one` | passa | Seria (« Seria: 5 dni ») |
| pl | `settings.streak.title.other` | passa | Seria (« Seria: 5 dni ») |
| pl | `sync.conflict.summary` | passa | Seria (« Seria: 5 dni ») |
| pl | `onboardingV2.trial.step2.title` | wersji próbnej | Bezpłatny okres próbny (przycisk: „Wypróbuj za darmo”) |
| pl | `settings.debug.audioPaywall` | paywall | Oferta (écran d'abonnement) |
| pl | `settings.debug.courseUnlockPaywall` | paywall | Oferta (écran d'abonnement) |
| pl | `settings.debug.discountPaywall` | paywall | Oferta (écran d'abonnement) |
| pl | `settings.debug.quizPaywall` | paywall | Oferta (écran d'abonnement) |
| pl | `settings.streak.title` | passa | Seria (« Seria: 5 dni ») |
| pl | `sync.conflict.summary` | passa | Seria (« Seria: 5 dni ») |
| pl | `pl/description` | kulturalną | Wiedza ogólna (cultivé : oczytany, obyty) |
| cs | `onboarding.premiumTrial.badge` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboarding.premiumTrial.cta` | zkušební verzi | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboarding.premiumTrial.title` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboardingV2.trial.title` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `paywall.header` | nejzajímavější osobou
v místnosti | nejzajímavější člověk ve společnosti |
| cs | `paywall.price.trialThenYearly` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `paywall.quiz.faq.a3` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `paywall.quiz.review3.quote` | kultivovanější | všeobecný přehled (vzdělaný, sečtělý: „Rozšiř si všeobecný p |
| cs | `paywall.review4.quote` | anekdoty | zajímavosti (zajímavé historky) |
| cs | `paywall.reviews.r3.quote` | kultivovanější | všeobecný přehled (vzdělaný, sečtělý: „Rozšiř si všeobecný p |
| cs | `profile.quiz.lockedSubtitle` | zkušební verzí | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `cs/description` | kultivovanějším | všeobecný přehled (vzdělaný, sečtělý: „Rozšiř si všeobecný p |
| cs | `onboarding.premiumTrial.badge` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboarding.premiumTrial.cta` | zkušební verzi | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboarding.premiumTrial.title` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `onboardingV2.trial.title` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `paywall.header` | nejzajímavější osobou
v místnosti | nejzajímavější člověk ve společnosti |
| cs | `paywall.price.trialThenYearly` | zkušební verze | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `paywall.review4.quote` | anekdoty | zajímavosti (zajímavé historky) |
| cs | `profile.quiz.lockedSubtitle` | zkušební verzí | Zkušební období zdarma (tlačítko: „Vyzkoušet zdarma“) |
| cs | `settings.debug.audioPaywall` | paywall | nabídka (např. „Zobrazit nabídku“) |
| cs | `settings.debug.courseUnlockPaywall` | paywall | nabídka (např. „Zobrazit nabídku“) |
| cs | `settings.debug.discountPaywall` | paywall | nabídka (např. „Zobrazit nabídku“) |
| cs | `settings.debug.quizPaywall` | paywall | nabídka (např. „Zobrazit nabídku“) |
| hu | `discount.gift.tapToOpen` | kinyitáshoz | Feloldás (gomb) / „Oldd fel” (felszólítás) |
| hu | `onboarding.premiumTrial.step1.title` | Prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.discount.subtitle` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.header` | a szoba
legérdekesebb | a társaság legérdekesebb embere |
| hu | `paywall.premiumColumn` | Prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.teaserSubtitle` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.trial.todayDetail` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `hu/description` | kulturáltabb | általános műveltség / művelt |
| hu | `discount.gift.tapToOpen` | kinyitáshoz | Feloldás (gomb) / „Oldd fel” (felszólítás) |
| hu | `onboarding.premiumTrial.step1.title` | Prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.discount.subtitle` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.header` | a szoba
legérdekesebb | a társaság legérdekesebb embere |
| hu | `paywall.premiumColumn` | Prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.teaserSubtitle` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `paywall.trial.todayDetail` | prémium | Premium (változatlan; toldalék közvetlenül: Premiumot, Premi |
| hu | `settings.debug.audioPaywall` | paywall | Ajánlat (előfizetési képernyő címe) |
| hu | `settings.debug.courseUnlockPaywall` | paywall | Ajánlat (előfizetési képernyő címe) |
| hu | `settings.debug.discountPaywall` | paywall | Ajánlat (előfizetési képernyő címe) |
| hu | `settings.debug.quizPaywall` | paywall | Ajánlat (előfizetési képernyő címe) |
| el | `paywall.header` | άτομο
στο δωμάτιο | ο πιο ενδιαφέρων άνθρωπος της παρέας |
| el | `paywall.review4.quote` | ανέκδοτα | Αξιοπερίεργα (ή «ιστορίες» όταν πρόκειται για αφήγηση) |
| el | `paywall.header` | άτομο
στο δωμάτιο | ο πιο ενδιαφέρων άνθρωπος της παρέας |
| el | `paywall.review4.quote` | ανέκδοτα | Αξιοπερίεργα (ή «ιστορίες» όταν πρόκειται για αφήγηση) |
| el | `settings.debug.audioPaywall` | paywall | η προσφορά (οθόνη συνδρομής· π.χ. «Δες την προσφορά») |
| el | `settings.debug.courseUnlockPaywall` | paywall | η προσφορά (οθόνη συνδρομής· π.χ. «Δες την προσφορά») |
| el | `settings.debug.discountPaywall` | paywall | η προσφορά (οθόνη συνδρομής· π.χ. «Δες την προσφορά») |
| el | `settings.debug.quizPaywall` | paywall | η προσφορά (οθόνη συνδρομής· π.χ. «Δες την προσφορά») |
| sv | `onboardingV2.review.title` | Här är vad | Regel: « Så här … » / « Det här är … » (Voici comment ça mar |
| sv | `paywall.quiz.review3.quote` | kultiverad | Allmänbildning (adj. allmänbildad) |
| sv | `onboardingV2.review.title` | Här är vad | Regel: « Så här … » / « Det här är … » (Voici comment ça mar |
| sv | `settings.debug.audioPaywall` | paywall | erbjudandet (skärmen heter Sophia Premium) |
| sv | `settings.debug.courseUnlockPaywall` | paywallen | erbjudandet (skärmen heter Sophia Premium) |
| sv | `sv/description` | kultiverad | Allmänbildning (adj. allmänbildad) |
| nl | `onboardingV2.screenTime.title` | Neem je tijd terug | Pak je tijd terug |
| nl | `onboardingV2.screenTime.title` | Neem je tijd terug | Pak je tijd terug |
| en | `onboardingV2.exams.quote2` | revise | Review (your courses); in testimonials about school: study |
| en | `onboardingV2.exams.quote4` | revising | Review (your courses); in testimonials about school: study |
| en | `onboardingV2.trial.step1.title` | Sophia Pro | Premium |
| en | `paywall.course.proPitch` | Sophia PRO | Premium |
| en | `paywall.quiz.faq.a2` | Sophia Pro | Premium |
| en | `paywall.quiz.faq.q2` | Sophia Pro | Premium |
| en | `paywall.quiz.subtitle` | Sophia PRO | Premium |
| en | `paywall.review4.quote` | anecdotes | Fun facts |
| en | `onboardingV2.exams.quote2` | revise | Review (your courses); in testimonials about school: study |
| en | `onboardingV2.exams.quote4` | revising | Review (your courses); in testimonials about school: study |
| en | `onboardingV2.trial.step1.title` | Sophia Pro | Premium |
| en | `paywall.blocker.subtitle.noTrial` | Sophia PRO | Premium |
| en | `paywall.course.proPitch` | Sophia PRO | Premium |
| en | `paywall.quiz.subtitle` | Sophia PRO | Premium |
| en | `paywall.review4.quote` | anecdotes | Fun facts |
| es | `onboarding.program.title` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| es | `onboardingV2.exams.author2` | último año | 2.º de Bachillerato (firma: « Inès, 2.º de Bachillerato ») |
| es | `onboardingV2.profile.eyebrow` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| es | `paywall.quiz.faq.a2` | abre el Repaso | Desbloquear |
| es | `training.ob.welcome.line` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| es | `onboarding.program.title` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| es | `onboardingV2.exams.author2` | último año | 2.º de Bachillerato (firma: « Inès, 2.º de Bachillerato ») |
| es | `onboardingV2.profile.eyebrow` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| es | `settings.debug.audioPaywall` | paywall | la oferta (Oferta no disponible ; No se pudo cargar la ofert |
| es | `settings.debug.courseUnlockPaywall` | paywall | la oferta (Oferta no disponible ; No se pudo cargar la ofert |
| es | `settings.debug.discountPaywall` | paywall | la oferta (Oferta no disponible ; No se pudo cargar la ofert |
| es | `settings.debug.quizPaywall` | paywall | la oferta (Oferta no disponible ; No se pudo cargar la ofert |
| es | `training.ob.welcome.line` | Aquí está tu | Regla: « Así es como… » / « Esto es lo que… » / « Este es tu |
| de | `de-DE/description` | General Knowledge | Allgemeinbildung / gebildet |
| pt | `onboarding.program.title` | Aqui está seu | Regra: « Veja como… » / « Veja o que… » / « Este é o seu… »  |
| pt | `onboardingV2.exams.author2` | , último ano | 3º ano do ensino médio (assinatura de depoimento: « Inès, 3º |
| pt | `onboardingV2.profile.eyebrow` | Aqui está seu | Regra: « Veja como… » / « Veja o que… » / « Este é o seu… »  |
| pt | `paywall.quiz.faq.a2` | libera a Revisão | Desbloquear (Desbloquear o curso; Desbloqueie o Premium) |
| pt | `onboarding.program.title` | Aqui está seu | Regra: « Veja como… » / « Veja o que… » / « Este é o seu… »  |
| pt | `onboardingV2.exams.author2` | , último ano | 3º ano do ensino médio (assinatura de depoimento: « Inès, 3º |
| pt | `onboardingV2.profile.eyebrow` | Aqui está seu | Regra: « Veja como… » / « Veja o que… » / « Este é o seu… »  |
| pt | `settings.debug.audioPaywall` | paywall | a oferta (tela de assinatura: « Não foi possível carregar a  |
| pt | `settings.debug.courseUnlockPaywall` | paywall | a oferta (tela de assinatura: « Não foi possível carregar a  |
| pt | `settings.debug.discountPaywall` | paywall | a oferta (tela de assinatura: « Não foi possível carregar a  |
| pt | `settings.debug.quizPaywall` | paywall | a oferta (tela de assinatura: « Não foi possível carregar a  |
| pt-PT | `settings.debug.audioPaywall` | paywall | a oferta / o ecrã de subscrição (nunca « paywall » nem decal |
| pt-PT | `settings.debug.courseUnlockPaywall` | paywall | a oferta / o ecrã de subscrição (nunca « paywall » nem decal |
| pt-PT | `settings.debug.discountPaywall` | paywall | a oferta / o ecrã de subscrição (nunca « paywall » nem decal |
| pt-PT | `settings.debug.quizPaywall` | paywall | a oferta / o ecrã de subscrição (nunca « paywall » nem decal |
| it | `onboardingV2.pw.compare.title` | Chi è Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `onboardingV2.trial.step1.title` | Sophia Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `path.quiz.review` | Rivedi i corsi | ripassare / ripasso (scolaire : revoir ses cours ; onglet «  |
| it | `paywall.course.proPitch` | Sophia PRO | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `paywall.quiz.faq.a2` | Sophia Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `paywall.quiz.faq.q2` | Sophia Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `paywall.quiz.subtitle` | Sophia PRO | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `onboardingV2.pw.compare.title` | Chi è Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `onboardingV2.trial.step1.title` | Sophia Pro | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `path.quiz.review` | Rivedi i corsi | ripassare / ripasso (scolaire : revoir ses cours ; onglet «  |
| it | `paywall.blocker.subtitle.noTrial` | Sophia PRO | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `paywall.course.proPitch` | Sophia PRO | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `paywall.quiz.subtitle` | Sophia PRO | Premium (nom de l'offre : invariable, majuscule initiale, ja |
| it | `settings.debug.audioPaywall` | paywall | l'offerta (écran d'abonnement : « Offerta non disponibile », |
| it | `settings.debug.courseUnlockPaywall` | paywall | l'offerta (écran d'abonnement : « Offerta non disponibile », |
| it | `settings.debug.discountPaywall` | paywall | l'offerta (écran d'abonnement : « Offerta non disponibile », |
| it | `settings.debug.quizPaywall` | paywall | l'offerta (écran d'abonnement : « Offerta non disponibile », |
| it | `it/description` | Conoscenza Generale | cultura generale / colto (« migliorare la tua cultura genera |


## Relancer le contrôle

```bash
python3 scripts/check_terminology.py                 # résumé par langue
python3 scripts/check_terminology.py --lang he -v    # chaque occurrence avec son contexte
python3 scripts/check_terminology.py --json occurrences.json
python3 scripts/check_terminology.py --gate          # code retour 1 s'il reste une occurrence
```

## Limites

- Une expression régulière ne lit pas le sens : il reste des faux positifs, surtout sur les termes produit dans les cours (le mot « leçon » est légitime dans un texte d'histoire) et sur les dates. Chaque occurrence est à confirmer avant correction automatique ; l'étape 2 ne corrige par script que les motifs mécaniques.
- Les listes couvrent les fautes connues. Une faute que personne n'a encore vue n'est pas détectée ; on l'ajoute à la liste la première fois.
