# Review: science, lane a (physics, chemistry, astronomy, earth sciences, maths)

The draft had 125 questions. The final file has 117: 110 kept from the draft (7 of them reworded), 15 dropped and 7 written to replace them.
Levels: L1 15, L2 15, L3 15, L4 15, L5 15, L6 14, L7 14, L8 14. True/false answers: 12 true, 11 false.
Validated with python3: mcq has 2 or 4 distinct options, each 30 characters or fewer; tf answers are bools; sliders use integers with min < value < max, a positive step and a unit, and no value sits exactly mid-range.

How the repetition rule was applied: a planet counts as a "place". Mars (Red Planet, Olympus Mons, moon count), Jupiter, Venus, Saturn, Mercury and Neptune already have 2 or more existing questions each, so questions mainly about those planets were dropped. The Earth, Moon and Sun are treated as reference bodies for core concepts (phases, eclipses, tides, distance), so they were not counted under this rule. Questions about a single moon or an event (Phobos, Titan, Shoemaker-Levy 9, Chang'e 4) were kept.

## Dropped (15)
- L1 "Which is closer to the Earth? Moon/Sun": too trivial. The existing set already compares Sun and Earth sizes and has "closest star → Sun".
- L2 "Which is hotter? Sun's surface / candle flame": overlaps the L6 slider on the Sun's surface temperature. The existing set has three "Which is hotter?" comparisons already.
- L3 "Smallest planet → Mercury": Mercury already has 2 existing questions (closest to the Sun, 88-day orbit).
- L4 "Saturn is the only planet with rings (F)": Saturn already has 2 existing questions, and this is close to "famous for its rings".
- L4 "A year on Mars is longer than on Earth": Mars already has 3 existing questions.
- L5 "Main gas of Mars's atmosphere": Mars already has 3 existing questions.
- L5 "Second person on the Moon → Aldrin": this would be the 3rd question on the Apollo Moon landings (existing 1969 slider plus the moonwalker-count slider, which is kept).
- L5 "Faces of an icosahedron": not translatable. The Japanese and Chinese name 正二十面体 ("twenty-face body") and the Greek εἰκοσάεδρο both contain the answer.
- L6 "Ocean of the Ring of Fire → Pacific": not translatable. The standard Japanese and Chinese term (環太平洋火山帯) contains "Pacific". It was also levelled too high.
- L6 "A day on Jupiter is shorter than on Earth": Jupiter already has 3 or more existing questions.
- L6 "Higher boiling point: water / ethanol": the weakest L6 question, cut to bring the total down to 117.
- L7 "Symbol Pb → Lead": the 4th chemical-symbol question (with the existing Au and the kept Fe and K), and level 7 was too high.
- L7 "Venus or Mercury: which spins more slowly?": Venus already has 3 existing questions, including "spins backwards".
- L8 "Stronger surface gravity: Neptune / Earth": Neptune already has 2 existing questions, and the gap is small (11.2 vs 9.8 m/s²), which makes it a weak quiz fact.
- L6 (was L8) "Length of the Earth's equator, 40 thousand km": with the kept Al-Biruni question and the existing Eratosthenes question, it would be the 3rd question on the size of the Earth.

## Fixed
- L1 steam: the distractor "Crystal" is not a state of matter, so it became "Plasma".
- L3 prime number: reworded to "divisible only by 1 and itself".
- L3 Pangaea: the mythical distractors Atlantis and Lemuria were replaced with the real supercontinents Pannotia and Columbia (kept Rodinia).
- L5 geyser: reworded to "What do we call…".
- L6 tungsten: "highest melting point of all" was ambiguous, because carbon is higher. Changed to "Which metal has the highest melting point?"
- L6 Rutherford: reworded to "Which physicist's gold-foil experiment showed…". Geiger and Marsden ran the experiment; Rutherford interpreted it.
- L7 kilogram: "defined using the Planck constant" was ambiguous, because the kelvin and candela depend on h indirectly through the kilogram. Reworded to "defined by fixing the value of the Planck constant".

## Re-levelled
- 31-day months, slider: L1 → L2.
- Pythagorean theorem: L4 → L3.
- The Moon always shows the same face: L3 → L4.
- Meteorite vs meteor: L6 → L4.
- Euclid's "Elements": L6 → L5.
- Titan orbits Saturn: L7 → L6.
- Boyle's law: L8 → L6.
- Pauli exclusion principle: L8 → L7.
- Kepler's first law, true/false: L8 → L7.

## New (7)
- L1 mcq: a scientist who studies stars and planets → Astronomer.
- L5 tf: "Marble is an igneous rock formed from cooled lava" → false (marble is metamorphic, formed from limestone).
- L6 slider: boiling point of liquid nitrogen → −196 °C (range −273 to 0).
- L8 mcq: first woman to win the Fields Medal, 2014 → Maryam Mirzakhani (distractors Viazovska, Uhlenbeck, Daubechies).
- L8 mcq: the atomic mass unit is 1/12 of the mass of which isotope → Carbon-12.
- L8 mcq (2 options): the earthquake waves that cannot cross the liquid outer core → S waves, not P waves.
- L8 mcq: the Abel Prize is named after a mathematician from which country → Norway.

## Checked and kept as is (notes)
- Osmium is described as "usually cited" as the densest element, because iridium is close.
- Al-Biruni measured the Earth's radius from a mountain at Nandana.
- Aryabhata (Aryabhatiya, 499 CE) taught that the Earth rotates.
- Yukawa won Japan's first Nobel Prize, in 1949.
- Phobos completes an orbit in 7.7 h, while Mars spins once in 24.6 h.
- Helium was found in the Sun's spectrum in 1868 and on Earth in 1895.
- Chang'e 4 made the first far-side landing (January 2019).
- About 69% of the Earth's fresh water is frozen in ice.
- The escape velocity is 11.2 km/s, which rounds to 11.
