# Monétisation : où on en est, et ce qu'il faut repenser

Compte rendu du 10 novembre 2026. Il couvre les paywalls, le modèle freemium, l'onboarding, l'offre
à prix réduit et la façon de mener les tests A/B.

Sources : RevenueCat (projet Sophia, lecture seule, chiffres en dollars), le code iOS et Android
tel qu'il est sur `main`, le journal des tests de prix d'octobre (`docs/plan-ab-tests-prix.md`, § 9).
Ce document ne refait pas la veille concurrentielle ni la grille de prix par pays, qui y sont déjà.
Rien n'a été modifié, ni dans l'app ni dans RevenueCat.

## 1. L'essentiel

1. **Sophia vend presque tout au même endroit : le paywall de fin d'onboarding.** Il fait environ
   70 % du revenu d'octobre. L'offre à prix réduit fait 17 %. Les paywalls rencontrés ensuite dans
   l'app (quiz, cours verrouillé) font moins de 2 %, et 0,4 % début novembre. Le « modèle freemium » ne vend donc presque
   rien par lui-même : il sert de salle d'attente à l'offre à 19,99.
2. **91 % des nouveaux utilisateurs ne démarrent jamais d'essai**, et parmi ceux qui en démarrent
   un, deux sur trois annulent. Au total 3,2 % paient. Ces taux sont bons pour la catégorie ; le
   gisement n'est pas dans le prix (les tests d'octobre l'ont montré) mais dans les 91 % et dans
   les deux tiers d'essais perdus.
3. **Un abonnement annuel sur dix est remboursé**, ce qui place Sophia dans le pire décile de sa
   catégorie. Une cause probable est dans l'app : l'onboarding iOS promet « un rappel 1 jour avant
   la fin de ton essai », et aucun rappel n'est programmé.
4. **On teste à l'aveugle.** L'app publiée n'envoie aucun événement d'usage : on ne sait pas à
   quelle page de l'onboarding les gens partent, combien voient chaque paywall, combien ouvrent
   le cadeau. Tous les tests passés ont été lus sur le seul revenu, avec trop peu de monde.
5. **Les tests de prix d'octobre ont été arrêtés trop tôt et sur trop de fronts.** Cinq groupes de
   pays en parallèle, des arrêts à J+5, J+10, J+14 quand le plan disait J+30. Un bras est passé de
   90 % à 46 % de chances de gagner en trois jours. Depuis le 21 octobre, plus aucun test ne
   tourne, alors qu'il arrive 5 000 nouveaux utilisateurs par jour.

Ce que je recommande, dans l'ordre : mesurer (publier la version qui envoie les événements),
réparer la promesse du rappel d'essai, puis mener **un test à la fois sur tout le trafic**, en
commençant par ce qui touche les 91 % (longueur de l'onboarding, connexion obligatoire) et le
modèle freemium, pas le prix.

## 2. Les chiffres

### 2.1 Trajectoire

| Mois 2026 | Nouveaux utilisateurs | Essais démarrés | Essai ou achat sous 7 j | Payants sous 7 j | Essais convertis | Revenu ($) | Remboursés |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Juin | 9 007 | 748 | 8,1 % | 3,1 % | 44,8 % | 8 441 | 10,3 % |
| Juillet | 14 985 | 966 | 6,4 % | 2,8 % | 44,0 % | 18 611 | 7,9 % |
| Août | 72 038 | 5 868 | 8,6 % | 2,8 % | 32,8 % | 66 982 | 11,0 % |
| Septembre | 98 656 | 7 155 | 7,5 % | 2,4 % | 31,0 % | 93 834 | 9,7 % |
| Octobre | 163 156 | 13 511 | 8,7 % | 3,2 % | 33,6 % | 189 623 | 9,2 % |
| Novembre (1 au 10) | 66 409 | 5 244 | en cours | en cours | en cours | 68 340 | en cours |

Au 10 novembre : 12 828 abonnements actifs, 2 094 essais en cours, revenu récurrent mensuel
d'environ 45 000 $. Un nouvel utilisateur rapporte 1,15 $ sous 30 jours (octobre) ; un utilisateur
qui paie rapporte 33,7 $, chiffre stable depuis juin.

Lecture : le volume a été multiplié par 18 depuis juin sans que les taux bougent. Le produit
convertit pareil à 9 000 et à 163 000 utilisateurs par mois. La croissance vient de l'acquisition,
pas d'un progrès de la monétisation. La conversion d'essai a perdu 11 points en août, quand le
trafic a changé d'échelle, et n'est jamais remontée.

### 2.2 D'où vient le revenu (octobre)

| Source | Revenu ($) | Part | Remboursés |
| --- | ---: | ---: | ---: |
| Paywall de fin d'onboarding, offre normale | 85 079 | 45 % | 10,8 % |
| Paywall de fin d'onboarding, variantes des tests de prix | 45 894 | 24 % | 8,6 à 14,2 % |
| Offre à prix réduit (le « cadeau », 19,99) | 31 591 | 17 % | 3,2 à 5,0 % |
| Non attribué (renouvellements, restaurations) | 21 391 | 11 % | 8,2 % |
| Paywalls dans l'app (quiz, cours verrouillé) | moins de 3 000 | moins de 2 % | — |

Du 1er au 10 novembre, sans test en cours : onboarding 71 %, cadeau 18 %, cours verrouillé 0,3 %,
quiz 0,1 %.

- **Annuel : 96 % du revenu.** Le mensuel fait 4 % et perd 58 % de ses abonnés chaque mois.
- **iOS : 88 % du revenu.** Android convertit moins bien ses essais (24,7 % contre 35,3 %).
- **Le cadeau fait 23 % des transactions** pour 17 % du revenu, avec trois fois moins de
  remboursements que l'onboarding : ce sont des gens qui ont utilisé l'app avant de payer.

### 2.3 Par pays (octobre)

| Pays | Nouveaux utilisateurs | Revenu ($) | Revenu par nouvel utilisateur ($) |
| --- | ---: | ---: | ---: |
| Hongrie | 6 662 | 15 504 | 2,33 |
| Allemagne | 10 148 | 21 497 | 2,12 |
| France | 8 046 | 13 236 | 1,65 |
| Grèce | 6 454 | 9 087 | 1,41 |
| Italie | 13 112 | 14 846 | 1,13 |
| Espagne | 7 746 | 7 780 | 1,00 |
| Pologne | 11 634 | 11 246 | 0,97 |
| Türkiye | 21 807 | 16 214 | 0,74 |
| Mexique | 11 420 | 8 107 | 0,71 |

Le revenu par pays inclut des renouvellements : c'est un ordre de grandeur, pas une valeur de
cohorte. Brésil (6 216 nouveaux) et Colombie (5 289) ne figurent pas dans les douze premiers
revenus. Un utilisateur allemand vaut trois utilisateurs turcs ou mexicains.

## 3. Ce que fait l'app aujourd'hui

### 3.1 Onboarding (iOS)

- **32 écrans** avant d'entrer dans l'app. Le paywall est le 31e.
- **Connexion obligatoire** au 24e écran (Apple ou Google seulement). Sur Android, on peut
  continuer sans compte.
- Le paywall annuel a une croix immédiate ; elle mène à un second paywall (comparaison gratuit
  contre PRO, annuel contre mensuel), dont la croix fait entrer dans l'app en gratuit.
- Deux écrans avant le paywall préparent l'essai : la chronologie de l'essai et « Tu recevras un
  rappel 1 jour avant la fin de ton essai ».
- **Ce rappel n'existe pas sur iOS.** Aucune notification n'est programmée. Il y a seulement un
  bandeau qui s'affiche une seconde, la veille, si l'app est ouverte. Android, lui, programme la
  notification.

### 3.2 Freemium

- **Un cours gratuit par jour** : le premier ouvert dans la journée, lisible en entier.
- Tous les autres cours : première leçon seulement, la suite floutée derrière un cadenas.
- **Toujours payants** : le quiz (même sur le cours gratuit), l'audio, l'onglet Entraînement, le
  bloqueur TikTok.
- **Gratuits** : le Parcours et les Duels.
- Un déblocage de cours avec les points d'expérience est écrit dans le code mais n'est branché nulle part.

### 3.3 Paywalls dans l'app

Sept paywalls, tous dessinés dans l'app, un par contexte (cours verrouillé, quiz, entraînement,
audio, bloqueur, fin d'onboarding, cadeau). Ils affichent l'annuel seul. Fermer celui du quiz ou
du cours verrouillé empile le paywall de comparaison par-dessus. La croix apparaît après 2 à
4 secondes selon le paywall.

Textes et mise en page sont écrits dans l'app : seuls les prix, les formules et la présence d'un
essai peuvent changer à distance. **Changer un mot sur un paywall demande une nouvelle version.**

### 3.4 L'offre à prix réduit

- Au troisième cours feuilleté sur l'accueil, un cadeau apparaît. L'ouvrir lance un compte à
  rebours de 60 minutes, réel, qui continue app fermée.
- L'annuel à 19,99, sans essai.
- **Elle revient tous les jours.** Qui ne l'a pas prise la revoit le lendemain.
- Le code tire encore au sort entre deux offres (19,99 et 29,99) alors que le test est tranché
  depuis le 7 octobre et que les deux vendent désormais le même produit à 19,99.

## 4. Diagnostic

### 4.1 Le prix n'est pas le levier

Les tests d'octobre ont essayé 29,99, 49,99, 59,99, 69,99 et des paliers à moitié prix. Aucun n'a
battu 39,99 de façon nette. Le plus cher perd des essais ; le moins cher ne gagne que si l'on
retire le cadeau de l'équation. C'est une information solide, même si les tests étaient courts :
la demande est peu sensible au prix dans cette fourchette, à la hausse comme à la baisse.

Une raison l'explique : **l'offre à 19,99 fixe le vrai prix.** Quelqu'un qui refuse 39,99 ou 49,99
à l'onboarding se voit proposer 19,99 dans l'heure, puis chaque jour. Monter le prix affiché
pousse simplement plus de monde vers le cadeau (107 achats du cadeau dans le bras à 49,99 contre
73 dans le bras à 39,99). Tester le prix de l'annuel sans toucher au cadeau, c'est tester un prix
barré.

### 4.2 Le freemium ne vend pas, il retient mal

Les paywalls du quiz et du cours verrouillé rapportent moins de 2 % du revenu (0,4 % début novembre). Deux lectures
possibles, que les données actuelles ne départagent pas :

- peu de gens reviennent après l'onboarding, donc peu de gens voient ces paywalls ;
- ou ils les voient, mais un cours complet par jour suffit à qui n'a pas payé le premier jour.

Dans les deux cas, la conclusion pratique est la même : aujourd'hui, **un utilisateur qui ferme le
paywall d'onboarding ne paiera presque jamais le plein tarif.** Sa seule issue payante est le
cadeau. Le modèle réel est donc : 39,99 avec essai le premier jour, 19,99 sans essai ensuite.

### 4.3 L'essai fuit par les deux bouts

- **Deux tiers des essais n'aboutissent pas.** Trois jours d'essai, démarrés à la fin d'un
  onboarding de 32 écrans, avant d'avoir lu un seul cours : beaucoup s'inscrivent sans intention.
- **10 % des annuels sont remboursés.** Le remboursement type est quelqu'un qui a oublié l'essai
  et découvre le prélèvement. La promesse de rappel non tenue sur iOS y contribue certainement,
  et c'est aussi un risque vis-à-vis d'Apple, qui regarde ces promesses.
- Le mensuel sans essai, adopté en Europe du Sud le 13 octobre parce qu'il pousse vers l'essai
  annuel, affiche **14,2 % de remboursements** contre 10,8 % pour l'offre normale. Le gain mesuré
  à l'époque (+2,4 points d'essais) est peut-être mangé par ces remboursements. À relire.

### 4.4 L'onboarding est une hypothèse jamais testée

32 écrans et une connexion obligatoire avant le paywall : c'est long, et c'est peut-être très
bien (les onboardings longs convertissent souvent mieux, parce qu'ils engagent). Mais personne ne
sait où les gens partent. 8,7 % démarrent un essai ou achètent ; on ignore si les 91 % restants ont vu le paywall et
dit non, ou s'ils sont partis au 12e écran ou à l'écran de connexion. Ce sont deux problèmes
opposés, avec des remèdes opposés.

L'écart entre iOS et Android est un indice à exploiter : Android n'impose pas la connexion. Si
Android amène proportionnellement plus de monde jusqu'au paywall, la connexion obligatoire coûte
cher.

### 4.5 La méthode des tests

Ce qui a mal fonctionné en octobre, à corriger avant de relancer quoi que ce soit :

- **Trop de tests à la fois.** Cinq groupes de pays, donc 400 à 700 personnes par jour et par
  test, réparties en deux à quatre bras.
- **Arrêts précoces.** Le plan fixait « pas de lecture positive avant J+30 ». Les décisions ont
  été prises entre J+5 et J+14, sur 100 à 270 essais terminés par bras.
- **Lecture sur des essais en cours.** Le 49,99 est passé de 90 % à 46 % de chances de gagner
  entre le 15 et le 18 octobre, une fois les essais terminés.
- **Un effet de bord non vu pendant cinq jours** : la clôture du test en Europe du Sud a rendu son
  offre courante pour le monde entier du 13 au 18 octobre (mensuel sans essai sur iOS, mensuel
  absent sur Android).
- **Le cadeau brouille tout**, comme décrit plus haut.
- **Aucun test n'a porté sur autre chose que le prix et la formule** depuis juillet.

Ordre de grandeur utile : avec 5 000 nouveaux utilisateurs par jour, un test à deux bras sur tout
le trafic détecte un écart de 10 % sur la part d'utilisateurs qui démarrent un essai en une
semaine environ, et un écart de 10 % sur la part de payants en trois semaines, auxquelles il faut
ajouter le temps que les essais se terminent. Découpé en cinq groupes de pays, il faut cinq fois
plus longtemps.

## 5. Réflexions de fond

### 5.1 Quel modèle freemium ?

Trois directions cohérentes. Elles s'excluent en partie ; il faut en choisir une et la tester
contre l'actuelle.

| Direction | Principe | Pour | Contre |
| --- | --- | --- | --- |
| **A. Mur dur** | Plus de cours gratuit quotidien après les premiers jours ; l'essai est la seule porte | Simple, aligne tout sur l'essai, supprime la salle d'attente | Moins d'utilisateurs actifs, moins de bouche-à-oreille, notes en baisse |
| **B. Freemium qui vend** | Garder un cours par jour, mais rendre la limite visible et désirable : quiz offert une fois, compteur, déblocage contre des points | Garde l'audience, donne des occasions d'achat au plein tarif | Plus de travail, effet incertain |
| **C. Freemium assumé + offre unique** | Garder le gratuit tel quel et faire du cadeau l'offre officielle des revenants, une fois, pas tous les jours | Reflète ce qui marche déjà, moins de remboursements | Tire le prix moyen vers 19,99 |

Mon avis : **B, avec un seul changement pour commencer**, celui du quiz. Le quiz est verrouillé
même sur le cours gratuit du jour, donc un utilisateur gratuit ne sait pas ce qu'il achèterait.
Offrir le quiz du premier cours terminé, puis le verrouiller, donne une raison concrète de payer
au moment où la personne vient de finir un cours. C'est testable seul.

### 5.2 L'offre à prix réduit

Elle rapporte 17 % du revenu avec peu de remboursements : il ne faut pas la supprimer. Mais telle
qu'elle est, elle apprend à attendre. Trois réglages à tester, un par un :

- **Une seule fois, pas tous les jours.** Une offre qui revient chaque matin n'est plus une offre.
- **Plus tard.** Aujourd'hui elle arrive au troisième cours feuilleté, souvent dans la première
  heure, donc juste après le refus du paywall à 39,99. La proposer à J+3 ou J+7 laisse une chance
  au plein tarif.
- **Réservée à ceux qui ont lu.** La déclencher après un cours terminé plutôt qu'après trois
  cartes feuilletées.

Le tirage au sort entre les deux offres à 19,99 est à retirer du code : il ne teste plus rien.

### 5.3 L'onboarding

Sans mesure, je ne recommande pas de le raccourcir à l'instinct. Une fois les événements en place,
trois tests valent la peine, dans cet ordre :

1. **Connexion après le paywall, ou facultative**, comme sur Android.
2. **Un cours lu avant le paywall.** L'onboarding fait déjà feuilleter des cours ; en faire lire un
   vrai (deux minutes) avant de demander de l'argent. C'est le test qui peut le plus changer la
   conversion des essais, parce qu'il filtre les curieux et convainc les autres.
3. **Version courte** (une quinzaine d'écrans) contre l'actuelle.

### 5.4 L'essai et les remboursements

- **Programmer le rappel promis sur iOS.** Ce n'est pas un test, c'est une réparation.
- Tester **7 jours contre 3**. Trois jours laissent à peine le temps de lire trois cours ; la
  conversion d'essai est tombée de 44 % à 33 % quand le public s'est élargi.
- Regarder les remboursements **par pays et par offre** avant d'étendre le mensuel sans essai.

### 5.5 Les paywalls

- Ils ne peuvent pas changer sans nouvelle version. Lire dans l'app quelques champs fournis par
  RevenueCat avec l'offre (titre, arguments, ordre des formules) permettrait de tester des textes
  en un jour au lieu de deux semaines.
- Le seul test de texte un peu lisible (juillet) pointait vers le **prix affiché par semaine** :
  moins d'essais démarrés, mais plus d'essais convertis. À refaire proprement.
- Le paywall de comparaison empilé à la fermeture de chaque paywall mérite d'être mesuré : on ne
  sait pas s'il rattrape des ventes ou s'il agace.

### 5.6 Les pays

Un utilisateur turc ou mexicain rapporte trois fois moins qu'un Allemand ou un Hongrois, au même
prix. Les paliers bas n'ont pas gagné. La question n'est donc plus « quel prix pour ces pays »,
mais « combien dépenser pour y acquérir des utilisateurs ». C'est une décision d'acquisition, hors
du champ de l'app, mais c'est probablement le levier de rentabilité le plus direct.

## 6. Programme proposé

Un test à la fois, sur tout le trafic iOS, lu sur le revenu net de remboursements à 30 jours.

| Ordre | Quoi | Type | Ce qu'on en attend |
| --- | --- | --- | --- |
| 0 | Publier la version qui envoie les événements ; ajouter « paywall fermé », « cadeau affiché », « cadeau ouvert » | Prérequis | Savoir où les gens partent |
| 0 | Programmer le rappel de fin d'essai sur iOS | Réparation | Moins de remboursements |
| 0 | Retirer le tirage au sort du cadeau | Ménage | Rien de mesurable |
| 1 | Cadeau une seule fois et à J+3, contre l'actuel | Test, 4 semaines | Savoir si le cadeau prend des ventes au plein tarif |
| 2 | Connexion facultative ou après le paywall | Test, 3 semaines | Plus de monde devant le paywall |
| 3 | Quiz offert sur le premier cours terminé | Test, 4 semaines | Des ventes au plein tarif après l'onboarding |
| 4 | Essai de 7 jours contre 3 | Test, 5 semaines | Plus d'essais convertis, moins de remboursements |
| 5 | Un cours lu avant le paywall | Test, 4 semaines | Meilleure conversion des essais |

Règles à tenir, tirées d'octobre :

- La durée et le critère de décision sont écrits avant le lancement et ne changent pas en route.
- On ne lit jamais un bras dont les essais ne sont pas terminés.
- On arrête avant la date seulement pour un garde-fou (remboursements, chute brutale), jamais pour
  une bonne nouvelle.
- Après chaque arrêt, on vérifie le jour même quelle offre est servie par défaut.

## 7. Ce qu'il te faut décider

1. **Le cap freemium** : mur dur, freemium qui vend, ou freemium assumé (§ 5.1). Tout le reste en
   découle.
2. **Le statut du cadeau** : offre de rattrapage unique, ou prix d'appel permanent (§ 5.2).
3. **La connexion obligatoire sur iOS** : es-tu prêt à la rendre facultative si le test le
   justifie, sachant que les amis, les duels et la synchronisation en dépendent ?
4. **Le rythme** : un test à la fois pendant trois à cinq semaines, c'est quatre ou cinq réponses
   solides d'ici mars au lieu de dix réponses fragiles.

## 8. Limites de ce compte rendu

- **Aucune donnée d'usage.** La table des événements de l'app ne contient que deux appareils de
  test, depuis aujourd'hui. Tout ce qui concerne le comportement dans l'onboarding et devant les
  paywalls est déduit du code et du revenu, pas observé.
- Les chiffres par offre d'octobre mélangent l'offre normale et les variantes de test, qui
  n'étaient pas servies aux mêmes pays.
- Novembre est incomplet : essais en cours, remboursements à venir.
- Les causes avancées pour les remboursements et pour la faiblesse des paywalls dans l'app sont
  des hypothèses plausibles, pas des faits établis.
- Je n'ai pas relu les paywalls écran par écran ni comparé leur rédaction à celle des concurrents.
