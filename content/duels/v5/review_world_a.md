# Review: world, lane a (geography)

The draft had 125 questions. The final file has 117: 94 kept from the draft (2 of them reworded), 31 dropped and 23 written to replace them.
Levels: L1 15, L2 15, L3 15, L4 15, L5 15, L6 14, L7 14, L8 14. Kinds: 82 mcq, 28 tf (14 true, 14 false), 7 sliders.
Validated with python3: mcq has 2 or 4 distinct options, each 30 characters or fewer; tf answers are bools; sliders use integers with min < value < max, a positive step and a unit, and no value sits exactly mid-range. Every question is 110 characters or fewer.

How the repetition rule was applied: a specific mountain, river, lake, sea, island, landmark or site counts as a "place", including its appearances in other subjects (art, history, mythology, science) and in the other v5 drafts. Sovereign countries and continents were treated as frames, not places. They already have capital, flag, area and population questions, so counting them would exclude almost every country. The Equator and the prime meridian were treated as reference lines, like the Earth and Moon in the science review. Distractor appearances do not count.

## Dropped (31)

### Counts that can change
- L1 slider "Number of US states, 50": a political count (statehood proposals exist).
- L1 slider "Countries in the United Kingdom, 4": a political count (independence referendums).
- L3 slider "Independent countries in South America, 12": a political count.
- L4 slider "UN members in Africa, 54": UN membership counts are not timeless.
- L7 slider "UN members in Oceania, 14": UN membership counts are not timeless.
- L6 slider "Time zones in Russia, 11": Russia changed this count in 2010 (to 9) and in 2014 (back to 11).
- L6 slider "Tokyo is 9 h ahead of London in winter": it depends on national time-zone policy, and the UK has debated a permanent change.

### Measurements where sources differ, or rounding makes the value ambiguous
- L5 slider "Arctic Circle, 67°": the true value is 66.56° and drifts over time, so "nearest degree" is ambiguous. No clean rewording, so it was dropped.
- L5 slider "Mont Blanc, 4806 m": surveys give 4,805.59 m, 4,806 m, 4,807.81 m and 4,808 m, because the snow cap changes. Mont Blanc also already has 2 questions (Everest/Mont Blanc and Kilimanjaro/Mont Blanc).
- L7 slider "Lake Titicaca, 3812 m": sources give 3,808, 3,810 and 3,812 m.
- L4 slider "Average radius of the Earth, 6371 km": the value changes with the definition (mean, equatorial 6,378, polar 6,357). This is also science-lane material on the size of the Earth.
- L3 slider "Length of the Equator, 40,000 km": the science lane dropped the same fact as the 3rd question on the size of the Earth. It also appears in draft_science_a.

### Duplicates with existing questions or other v5 drafts
- L1 "Country of the pyramids of Giza": an exact duplicate of an existing history L1 question, same options.
- L1 "Country of the Great Wall": an exact duplicate of an existing history L1 question.
- L3 "Country of Angkor Wat": an exact duplicate of an existing art L3 question.
- L4 "Country of Petra": duplicates draft_art_a L2 ("In which country is Petra…").
- L5 slider "Amundsen reaches the South Pole, 1911": duplicates draft_history_b L7.
- L8 slider "Abel Tasman reaches New Zealand, 1642": duplicates draft_history_b L8.
- L6 slider "Korean border near the 38th parallel": duplicates the existing history L3 question on Korea and the 38th parallel.
- L8 tf "Chimborazo, not Everest, is farthest from the Earth's centre": a near-duplicate of the existing science L6 tf (Everest's summit is not the point farthest from the centre).
- L2 "Molten rock from a volcano → Lava": science-lane material. It overlaps the existing science question on volcanoes ("erupts lava and ash") and two science_a questions on lava.

### Repetition (the place would have appeared more than twice)
- L2 "Country of Machu Picchu": existing art L3 and history L7 already cover Machu Picchu.
- L3 "Mount Fuji vs Mount Olympus": Fuji already has 3 questions (world tf "Fuji in China", world "Fuji vs Elbrus", art Hokusai).
- L3 tf "Vesuvius overlooks the Bay of Naples": existing history (Pompeii) and draft_history_a (Herculaneum) already cover Vesuvius.
- L4 "Rhine vs Thames": this would be the 3rd river comparison involving the Rhine (with Volga/Rhine and Danube/Rhine).
- L6 "Kalahari vs Atacama": with the existing "Atacama vs Gobi" and the kept tf "Atacama in Africa", it would be the 3rd Atacama question.
- L7 "Lake Tanganyika vs Lake Superior, deeper": Tanganyika already has 2 questions, and so does Superior.
- L6 "White and Blue Nile meet at Khartoum": the Nile already has 2 existing questions (it flows north through Egypt; Nile vs Danube).
- L2 "Mediterranean vs Black Sea": the Mediterranean has the existing world L3 question and the "Mare Nostrum" question in draft_history_a. The Black Sea already has 2 existing questions (Danube tf, Bosphorus).
- L4 "Largest island in the Mediterranean → Sicily": Sicily already has 2 questions in the v5 drafts (draft_history_a on the Normans, draft_literature_b on "The Leopard").
- L3 "Name of the 0° longitude line": with the kept Gulf of Guinea question and the Greenwich 1884 slider, it would be the 3rd prime meridian question. It was also the most trivial of the three.

## Fixed
- L3 monsoon: "What is the seasonal wind that…" became "Which wind brings heavy summer rains to South Asia?". In Japanese and Chinese, "monsoon" is 季節風 ("seasonal wind"), and in Arabic it is "seasonal winds", so the old wording gave the answer away.
- L7 Yellowstone slider: "established as the world's first national park" became "usually called the world's first national park". The "first" claim is the usual one, but it is contested (Bogd Khan Uul, 1778).

## New (23)
- L1 mcq: a piece of land surrounded by water on all sides → Island.
- L1 mcq: a huge mass of ice that moves slowly over land → Glacier (Iceberg is ruled out by "over land").
- L1 tf: Mexico is part of North America → true. This holds under both the 6- and 7-continent models.
- L2 tf: most of Greenland is covered by a thick ice sheet → true (about 80%).
- L2 mcq: the island country just off the south-eastern coast of India → Sri Lanka (the Maldives lie to the south-west).
- L3 mcq: the sea that separates Egypt from Saudi Arabia → Red Sea.
- L3 mcq: the tropical grassland with scattered trees in East Africa → Savanna ("tropical" rules out Steppe).
- L3 mcq: a large, flat area of land raised high above its surroundings → Plateau.
- L3 tf: Corsica belongs to Italy → false (France). Corsica now has 2 questions, with the existing history question on Napoleon's birthplace.
- L3 mcq: the country on the Iberian Peninsula → Portugal (distractors Italy, Greece, Croatia).
- L4 mcq: the mountain range across Morocco, Algeria and Tunisia → Atlas.
- L4 mcq: Serengeti National Park → Tanzania. The ecosystem reaches into Kenya, but the national park does not.
- L4 tf: Cuba is the largest island in the Caribbean → true (about 110,000 km², against about 76,000 km² for Hispaniola).
- L4 tf: the Ganges flows into the Bay of Bengal → true.
- L5 mcq: the Pampas lie mainly in → Argentina. Uruguay and Brazil are left out of the options.
- L5 slider: Mount St. Helens eruption → 1980 (range 1900–2020).
- L6 mcq: the lake that largely dried up after Soviet irrigation projects → Aral Sea.
- L6 mcq: the river through Bangkok → Chao Phraya.
- L6 mcq: the river through Lisbon → Tagus. Lisbon now has 2 questions, with the Lisbon/Dublin comparison.
- L6 slider: Krakatoa eruption → 1883 (range 1750–1950).
- L7 mcq: the strait between the North and South Islands of New Zealand → Cook Strait.
- L7 mcq: the country where the Mekong has its source → China (Qinghai, on the Tibetan Plateau). The Mekong now has 2 questions, with the existing Mekong/Seine comparison.
- L8 mcq: the Kerguelen Islands belong to → France.

## Checked and kept (notes)
- Etna vs Olympus: Etna's height changes with eruptions (about 3,320–3,400 m), but it is always far above Olympus (2,918 m). Olympus now has 2 questions, with the mythology L1 question.
- About a quarter of the Netherlands lies below sea level: Dutch government figures give about 26%.
- China uses a single official time zone: kept, because it is a true/false statement about a long-standing policy (since 1949), not a count.
- Socotra belongs to Yemen: this is its legal status, whatever the de facto control on the ground.
- Saint Martin is divided between France and the Netherlands (the Kingdom of the Netherlands, through Sint Maarten).
- Lake Malawi is not entirely within Malawi: the statement is clearly false, because Mozambique's share is undisputed (the Tanzanian share is disputed).
- Ibn Battuta's birthplace, Tangier: this makes 2 questions on him, with the existing history L6 question.
- Victoria Falls has 2 questions (the borders and the Zambezi). Easter Island has 2 (the existing art question on the moai and the country question).
- Rio Grande: translators should use the local name "Río Bravo" where it is the norm.
- Antarctica (the desert tf and the Treaty slider) is treated as a continent. Each question covers a different topic.
