#!/usr/bin/env python3
"""Questions de duel tirées de données : drapeaux, capitales, comparaisons (matière « world »).

    python3 scripts/duels_geo_source.py      contrôle les écarts et affiche les effectifs

- FLAGS : « Which country's flag is this? ». L'image est le drapeau du pays (flagcdn.com,
  domaine public), posé sur un fond neutre au format du cadre de l'app par
  scripts/duels_images.py. Les trois mauvaises réponses sont des pays au drapeau voisin,
  jamais un drapeau identique (Indonésie / Monaco, Roumanie / Tchad ne s'opposent pas).
- CAPITALS : « What is the capital of X? » (mauvaises réponses : d'autres villes du pays) ou
  « X is the capital of which country? » (mauvaises réponses : des pays voisins). Les pays à
  plusieurs capitales ou à capitale discutée (Bolivie, Afrique du Sud, Pays-Bas, Sri Lanka,
  Côte d'Ivoire) sont écartés.
- COMPARISONS : deux réponses, la première est la bonne. Pour les pays, les chiffres sont ceux
  de la Banque mondiale pour 2023 (population en millions, PIB en milliards de dollars
  courants) et les superficies usuelles (milliers de km²) ; un couple n'est gardé que si
  l'écart est net (× 1,3 au moins pour la population et la superficie, × 2 pour le PIB), pour
  que la réponse ne se retourne pas d'une année sur l'autre.
"""
from __future__ import annotations

import sys

# (code ISO du drapeau, pays, niveau, trois pays au drapeau voisin)
FLAGS = [
    ("us", "United States", 1, ["United Kingdom", "Australia", "France"]),
    ("jp", "Japan", 1, ["China", "South Korea", "Vietnam"]),
    ("ca", "Canada", 1, ["United States", "Switzerland", "Denmark"]),
    ("gb", "United Kingdom", 1, ["Australia", "New Zealand", "Ireland"]),
    ("fr", "France", 1, ["Italy", "Netherlands", "Belgium"]),
    ("it", "Italy", 2, ["Ireland", "Mexico", "Hungary"]),
    ("de", "Germany", 2, ["Belgium", "Austria", "Netherlands"]),
    ("br", "Brazil", 2, ["Argentina", "Portugal", "Colombia"]),
    ("cn", "China", 2, ["Vietnam", "Japan", "Turkey"]),
    ("ch", "Switzerland", 2, ["Denmark", "Austria", "Sweden"]),
    ("es", "Spain", 3, ["Portugal", "Colombia", "Germany"]),
    ("in", "India", 3, ["Ireland", "Italy", "Pakistan"]),
    ("mx", "Mexico", 3, ["Italy", "Hungary", "Iran"]),
    ("au", "Australia", 3, ["New Zealand", "United Kingdom", "Fiji"]),
    ("gr", "Greece", 3, ["Finland", "Israel", "Uruguay"]),
    ("se", "Sweden", 4, ["Norway", "Finland", "Denmark"]),
    ("ar", "Argentina", 4, ["Uruguay", "Honduras", "Greece"]),
    ("kr", "South Korea", 4, ["Japan", "North Korea", "Taiwan"]),
    ("tr", "Turkey", 4, ["Tunisia", "Morocco", "Pakistan"]),
    ("za", "South Africa", 4, ["Kenya", "Zimbabwe", "Jamaica"]),
    ("pt", "Portugal", 5, ["Spain", "Brazil", "Italy"]),
    ("no", "Norway", 5, ["Iceland", "Denmark", "Sweden"]),
    ("il", "Israel", 5, ["Greece", "Finland", "Argentina"]),
    ("eg", "Egypt", 5, ["Iraq", "Syria", "Yemen"]),
    ("nl", "Netherlands", 5, ["France", "Russia", "Croatia"]),
    ("pl", "Poland", 6, ["Indonesia", "Austria", "Denmark"]),
    ("vn", "Vietnam", 6, ["China", "Morocco", "Turkey"]),
    ("jm", "Jamaica", 6, ["South Africa", "Tanzania", "Ghana"]),
    ("sa", "Saudi Arabia", 6, ["Pakistan", "Iran", "Iraq"]),
    ("ie", "Ireland", 6, ["Italy", "India", "Hungary"]),
    ("ke", "Kenya", 7, ["Uganda", "Tanzania", "Ethiopia"]),
    ("cl", "Chile", 7, ["Cuba", "Czechia", "Philippines"]),
    ("fi", "Finland", 7, ["Sweden", "Iceland", "Greece"]),
    ("th", "Thailand", 7, ["Costa Rica", "Netherlands", "Cambodia"]),
    ("np", "Nepal", 7, ["Bhutan", "Sri Lanka", "Mongolia"]),
    ("bt", "Bhutan", 8, ["Nepal", "Sri Lanka", "Brunei"]),
    ("kz", "Kazakhstan", 8, ["Uzbekistan", "Kyrgyzstan", "Palau"]),
    ("uy", "Uruguay", 8, ["Argentina", "Greece", "El Salvador"]),
    ("mz", "Mozambique", 8, ["Angola", "Zimbabwe", "Zambia"]),
    ("ee", "Estonia", 8, ["Latvia", "Lithuania", "Botswana"]),
]

# (niveau, question, [bonne réponse, trois mauvaises])
CAPITALS = [
    (1, "What is the capital of France?", ["Paris", "Lyon", "Marseille", "Nice"]),
    (1, "What is the capital of Japan?", ["Tokyo", "Osaka", "Kyoto", "Yokohama"]),
    (1, "What is the capital of Italy?", ["Rome", "Milan", "Naples", "Venice"]),
    (1, "What is the capital of Egypt?", ["Cairo", "Alexandria", "Luxor", "Giza"]),
    (1, "What is the capital of Spain?", ["Madrid", "Barcelona", "Seville", "Valencia"]),
    (2, "What is the capital of Germany?", ["Berlin", "Munich", "Hamburg", "Frankfurt"]),
    (2, "What is the capital of Russia?", ["Moscow", "Saint Petersburg", "Kazan", "Novosibirsk"]),
    (2, "What is the capital of China?", ["Beijing", "Shanghai", "Hong Kong", "Guangzhou"]),
    (2, "What is the capital of Greece?", ["Athens", "Thessaloniki", "Sparta", "Corinth"]),
    (2, "What is the capital of the United States?", ["Washington, D.C.", "New York", "Los Angeles", "Chicago"]),
    (3, "What is the capital of Australia?", ["Canberra", "Sydney", "Melbourne", "Perth"]),
    (3, "What is the capital of Canada?", ["Ottawa", "Toronto", "Montreal", "Vancouver"]),
    (3, "What is the capital of Brazil?", ["Brasília", "Rio de Janeiro", "São Paulo", "Salvador"]),
    (3, "What is the capital of Turkey?", ["Ankara", "Istanbul", "Izmir", "Antalya"]),
    (3, "What is the capital of India?", ["New Delhi", "Mumbai", "Kolkata", "Bangalore"]),
    (4, "What is the capital of Switzerland?", ["Bern", "Zurich", "Geneva", "Basel"]),
    (4, "What is the capital of Morocco?", ["Rabat", "Casablanca", "Marrakesh", "Fez"]),
    (4, "What is the capital of Argentina?", ["Buenos Aires", "Córdoba", "Rosario", "Mendoza"]),
    (4, "What is the capital of South Korea?", ["Seoul", "Busan", "Incheon", "Daegu"]),
    (4, "What is the capital of Poland?", ["Warsaw", "Kraków", "Gdańsk", "Wrocław"]),
    (5, "What is the capital of New Zealand?", ["Wellington", "Auckland", "Christchurch", "Queenstown"]),
    (5, "What is the capital of Vietnam?", ["Hanoi", "Ho Chi Minh City", "Da Nang", "Hue"]),
    (5, "What is the capital of Pakistan?", ["Islamabad", "Karachi", "Lahore", "Peshawar"]),
    (5, "What is the capital of Nigeria?", ["Abuja", "Lagos", "Kano", "Ibadan"]),
    (5, "Nairobi is the capital of which country?", ["Kenya", "Tanzania", "Uganda", "Ethiopia"]),
    (6, "What is the capital of Peru?", ["Lima", "Cusco", "Arequipa", "Trujillo"]),
    (6, "What is the capital of Tanzania?", ["Dodoma", "Dar es Salaam", "Arusha", "Zanzibar City"]),
    (6, "What is the capital of Myanmar?", ["Naypyidaw", "Yangon", "Mandalay", "Bagan"]),
    (6, "What is the capital of Colombia?", ["Bogotá", "Medellín", "Cali", "Cartagena"]),
    (6, "Reykjavik is the capital of which country?", ["Iceland", "Norway", "Finland", "Denmark"]),
    (7, "Ulaanbaatar is the capital of which country?", ["Mongolia", "Kazakhstan", "Kyrgyzstan", "Nepal"]),
    (7, "What is the capital of Uruguay?", ["Montevideo", "Punta del Este", "Salto", "Colonia del Sacramento"]),
    (7, "Tbilisi is the capital of which country?", ["Georgia", "Armenia", "Azerbaijan", "Moldova"]),
    (7, "Tashkent is the capital of which country?", ["Uzbekistan", "Kazakhstan", "Turkmenistan", "Tajikistan"]),
    (7, "What is the capital of Ecuador?", ["Quito", "Guayaquil", "Cuenca", "Lima"]),
    (8, "Thimphu is the capital of which country?", ["Bhutan", "Nepal", "Laos", "Brunei"]),
    (8, "Ouagadougou is the capital of which country?", ["Burkina Faso", "Mali", "Niger", "Benin"]),
    (8, "Paramaribo is the capital of which country?", ["Suriname", "Guyana", "Belize", "Paraguay"]),
    (8, "Vaduz is the capital of which country?", ["Liechtenstein", "Luxembourg", "Andorra", "Monaco"]),
    (8, "Antananarivo is the capital of which country?", ["Madagascar", "Mozambique", "Mauritius", "Malawi"]),
]

# Banque mondiale, 2023 : population (millions), PIB (milliards de dollars courants).
POPULATION = {
    "India": 1438.1, "China": 1410.7, "United States": 336.8, "Indonesia": 281.2, "Pakistan": 247.5,
    "Nigeria": 227.9, "Brazil": 211.1, "Bangladesh": 171.5, "Russia": 143.8, "Mexico": 129.7,
    "Ethiopia": 128.7, "Japan": 124.5, "Philippines": 114.9, "Egypt": 114.5, "DR Congo": 105.8,
    "Vietnam": 100.4, "Iran": 90.6, "Turkey": 85.3, "Germany": 83.3, "United Kingdom": 68.5,
    "France": 68.4, "Tanzania": 66.6, "Italy": 59.0, "Kenya": 55.3, "Spain": 48.4, "Algeria": 46.2,
    "Canada": 40.0, "Uzbekistan": 35.7, "Australia": 26.7, "Netherlands": 17.9, "Portugal": 10.6,
}
GDP = {
    "United States": 27812, "China": 18270, "Germany": 4562, "Japan": 4385, "India": 3501,
    "Italy": 2317, "Brazil": 2191, "Russia": 2046, "South Korea": 1845, "Mexico": 1794,
    "Australia": 1734, "Saudi Arabia": 1219, "Netherlands": 1135, "Switzerland": 928, "Belgium": 651,
    "Argentina": 649, "Singapore": 511, "Nigeria": 487, "Egypt": 396, "Pakistan": 337,
    "Ethiopia": 136, "Kenya": 108,
}
# Superficie totale, en milliers de km² (France métropolitaine).
AREA = {
    "Russia": 17098, "Canada": 9985, "China": 9597, "Brazil": 8516, "Australia": 7741, "India": 3287,
    "Argentina": 2780, "Kazakhstan": 2725, "Algeria": 2382, "DR Congo": 2345, "Mexico": 1964,
    "Sudan": 1861, "Libya": 1760, "Mongolia": 1564, "Peru": 1285, "Chad": 1284, "South Africa": 1221,
    "Egypt": 1002, "Turkey": 784, "Madagascar": 587, "France": 549, "Spain": 506, "Sweden": 450,
    "Japan": 378, "Germany": 358, "United Kingdom": 244,
}

Q_POP = "Which country has more people?"
Q_AREA = "Which country is larger in area?"
Q_GDP = "Which country has the larger economy (GDP)?"

# (niveau, question, [le plus grand, l'autre])
COUNTRY_COMPARISONS = [
    (1, Q_POP, ["India", "United States"]),
    (1, Q_POP, ["China", "Russia"]),
    (2, Q_POP, ["Japan", "Germany"]),
    (2, Q_POP, ["Brazil", "Canada"]),
    (3, Q_POP, ["Indonesia", "Japan"]),
    (3, Q_POP, ["Mexico", "Italy"]),
    (3, Q_POP, ["Turkey", "Australia"]),
    (4, Q_POP, ["Indonesia", "Brazil"]),
    (4, Q_POP, ["Pakistan", "Germany"]),
    (4, Q_POP, ["Iran", "Canada"]),
    (5, Q_POP, ["Nigeria", "Russia"]),
    (5, Q_POP, ["Egypt", "France"]),
    (5, Q_POP, ["Vietnam", "Spain"]),
    (6, Q_POP, ["Bangladesh", "Japan"]),
    (6, Q_POP, ["Ethiopia", "Germany"]),
    (6, Q_POP, ["Philippines", "United Kingdom"]),
    (7, Q_POP, ["DR Congo", "France"]),
    (7, Q_POP, ["Tanzania", "Australia"]),
    (7, Q_POP, ["Kenya", "Canada"]),
    (8, Q_POP, ["Uzbekistan", "Netherlands"]),
    (1, Q_AREA, ["Russia", "China"]),
    (2, Q_AREA, ["Canada", "India"]),
    (3, Q_AREA, ["Brazil", "India"]),
    (3, Q_AREA, ["Australia", "India"]),
    (5, Q_AREA, ["Argentina", "Mexico"]),
    (5, Q_AREA, ["Mongolia", "France"]),
    (5, Q_AREA, ["Sweden", "United Kingdom"]),
    (5, Q_AREA, ["Peru", "Spain"]),
    (6, Q_AREA, ["Algeria", "South Africa"]),
    (6, Q_AREA, ["Kazakhstan", "Mexico"]),
    (6, Q_AREA, ["DR Congo", "Egypt"]),
    (6, Q_AREA, ["Japan", "United Kingdom"]),
    (7, Q_AREA, ["Libya", "Egypt"]),
    (7, Q_AREA, ["Chad", "Germany"]),
    (7, Q_AREA, ["Sudan", "Turkey"]),
    (8, Q_AREA, ["Madagascar", "United Kingdom"]),
    (1, Q_GDP, ["United States", "Japan"]),
    (2, Q_GDP, ["China", "Japan"]),
    (3, Q_GDP, ["Brazil", "Argentina"]),
    (4, Q_GDP, ["Japan", "Russia"]),
    (4, Q_GDP, ["Germany", "Brazil"]),
    (4, Q_GDP, ["India", "Australia"]),
    (5, Q_GDP, ["South Korea", "Nigeria"]),
    (5, Q_GDP, ["Mexico", "Pakistan"]),
    (5, Q_GDP, ["Australia", "Egypt"]),
    (6, Q_GDP, ["South Korea", "Argentina"]),
    (7, Q_GDP, ["Netherlands", "Nigeria"]),
    (7, Q_GDP, ["Switzerland", "Egypt"]),
    (7, Q_GDP, ["Belgium", "Ethiopia"]),
    (8, Q_GDP, ["Singapore", "Kenya"]),
]

# Géographie physique : (niveau, question, [bonne, autre], (valeur bonne, valeur autre, unité))
PHYSICAL_COMPARISONS = [
    (1, "Which mountain is higher?", ["Mount Everest", "Mont Blanc"], (8849, 4806, "m")),
    (3, "Which mountain is higher?", ["K2", "Kilimanjaro"], (8611, 5895, "m")),
    (4, "Which mountain is higher?", ["Kilimanjaro", "Mont Blanc"], (5895, 4806, "m")),
    (5, "Which mountain is higher?", ["Mount Elbrus", "Mount Fuji"], (5642, 3776, "m")),
    (2, "Which river is longer?", ["Nile", "Danube"], (6650, 2850, "km")),
    (3, "Which river is longer?", ["Mekong", "Seine"], (4350, 777, "km")),
    (4, "Which river is longer?", ["Yangtze", "Ganges"], (6300, 2525, "km")),
    (5, "Which river is longer?", ["Volga", "Rhine"], (3530, 1230, "km")),
    (7, "Which river is longer?", ["Congo", "Zambezi"], (4700, 2574, "km")),
    (1, "Which ocean is larger?", ["Pacific Ocean", "Atlantic Ocean"], (165.2, 106.5, "M km²")),
    (3, "Which ocean is larger?", ["Indian Ocean", "Arctic Ocean"], (70.6, 14.1, "M km²")),
    (2, "Which desert is larger?", ["Sahara", "Gobi"], (9200, 1295, "k km²")),
    (7, "Which desert is larger?", ["Arabian Desert", "Kalahari"], (2330, 900, "k km²")),
    (5, "Which lake is deeper?", ["Lake Baikal", "Lake Superior"], (1642, 406, "m")),
    (7, "Which lake has the larger surface?", ["Lake Victoria", "Lake Tanganyika"], (68.9, 32.9, "k km²")),
    (3, "Which island is larger?", ["Greenland", "Madagascar"], (2166, 587, "k km²")),
    (4, "Which island is larger?", ["Madagascar", "Iceland"], (587, 103, "k km²")),
    (5, "Which island is larger?", ["Borneo", "Great Britain"], (743, 209, "k km²")),
    (7, "Which island is larger?", ["New Guinea", "Honshu"], (786, 228, "k km²")),
    (1, "Which continent is larger?", ["Asia", "Africa"], (44.6, 30.4, "M km²")),
    (2, "Which continent is larger?", ["Africa", "Europe"], (30.4, 10.2, "M km²")),
    (5, "Which continent is larger?", ["Antarctica", "Europe"], (14.2, 10.2, "M km²")),
    (5, "Which city is farther north?", ["Paris", "New York"], (48.9, 40.7, "°N")),
    (6, "Which city is farther north?", ["London", "Montreal"], (51.5, 45.5, "°N")),
    (6, "Which city is farther north?", ["Rome", "Tokyo"], (41.9, 35.7, "°N")),
    (8, "Which city is farther north?", ["Oslo", "Moscow"], (59.9, 55.8, "°N")),
    (8, "Which city is farther south?", ["Buenos Aires", "Johannesburg"], (34.6, 26.2, "°S")),
]

FLAG_QUESTION = "Which country's flag is this?"


def check() -> list[str]:
    """Les couples gardés ont un écart net ; les effectifs par niveau sont équilibrés."""
    problems = []
    for level, question, (big, small) in COUNTRY_COMPARISONS:
        table, minimum = {Q_POP: (POPULATION, 1.3), Q_AREA: (AREA, 1.3), Q_GDP: (GDP, 2.0)}[question]
        if big not in table or small not in table:
            problems.append(f"chiffre manquant : {big} / {small} ({question})")
            continue
        ratio = table[big] / table[small]
        if ratio < minimum:
            problems.append(f"écart trop faible (× {ratio:.2f}) : {big} / {small} ({question})")
    for level, question, (big, small), (a, b, _unit) in PHYSICAL_COMPARISONS:
        if a / b < 1.07 if "north" in question or "south" in question else a / b < 1.2:
            problems.append(f"écart trop faible : {big} / {small} ({question})")
    for code, country, level, wrong in FLAGS:
        if country in wrong or len(set(wrong)) != 3:
            problems.append(f"drapeau {code} : mauvaises réponses à revoir")
    seen = set()
    for level, question, options in CAPITALS:
        if len(set(options)) != 4 or question in seen:
            problems.append(f"capitale à revoir : {question}")
        seen.add(question)
        if any(len(o) > 34 for o in options):
            problems.append(f"option trop longue : {question}")
    return problems


def questions() -> list[dict]:
    """Toutes les questions de ce fichier, au format de scripts/build_duels_seed.py."""
    out = []
    for code, country, level, wrong in FLAGS:
        out.append({"level": level, "kind": "image", "subject": "world", "question": FLAG_QUESTION,
                    "image": f"flags/{code}", "options": [country] + wrong})
    for level, question, options in CAPITALS:
        out.append({"level": level, "kind": "mcq", "subject": "world", "question": question, "options": options})
    for level, question, options in COUNTRY_COMPARISONS:
        out.append({"level": level, "kind": "mcq", "subject": "world", "question": question, "options": options})
    for level, question, options, _facts in PHYSICAL_COMPARISONS:
        out.append({"level": level, "kind": "mcq", "subject": "world", "question": question, "options": options})
    return out


if __name__ == "__main__":
    import collections
    found = check()
    for p in found:
        print("PROBLÈME", p)
    by_level = collections.Counter(q["level"] for q in questions())
    print(f"{len(FLAGS)} drapeaux, {len(CAPITALS)} capitales, {len(COUNTRY_COMPARISONS)} comparaisons de pays, "
          f"{len(PHYSICAL_COMPARISONS)} comparaisons de géographie physique")
    print("par niveau :", dict(sorted(by_level.items())))
    sys.exit(1 if found else 0)
