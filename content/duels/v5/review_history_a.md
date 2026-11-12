# Review — history, lane A (prehistory to 1500, worldwide)

Draft: 125 questions. Final: **117**. 100 kept unchanged, 5 fixed, 20 dropped, 12 new.
Per level: L1 15 · L2 15 · L3 15 · L4 15 · L5 14 · L6 14 · L7 15 · L8 14.
Kinds: 75 mcq, 24 tf (12 true / 12 false), 18 slider. Validated with python3. Each mcq has 2 or 4 distinct options. Each tf answer is a bool. Each slider uses integers with min < value < max, has a unit, and its value is not exactly mid-range.

Besides `existing_history.txt`, I checked for duplicates in the other subjects' existing files and in the v5 drafts and finals. Several draft items were already covered in art, literature, science or world.

## Dropped (20)

| Lvl | Question (draft) | Reason |
|---|---|---|
| 1 | Ancient Olympic Games were held in Rome (tf) | Near-duplicate of existing L1 "Which ancient people held the first Olympic Games? → Greeks". |
| 1 | The ancient Greeks worshipped many gods (tf) | Trivial and mythology territory. Level surplus. |
| 1 | Giant statue at Giza with lion body → Great Sphinx | Duplicate of existing_art L1 (Sphinx = lion body + human head) and existing_mythology. |
| 1 | Navigation tool invented in China → compass | Same fact as final_science_b L3 ("direction-finding instrument first developed in China"). |
| 2 | Polynesians crossed which ocean → Pacific | Give-away. Polynesia was over-represented (navigation, sweet potato, Māori). |
| 2 | Vikings crossed which ocean → Atlantic | Easy. The Norse/Viking theme was over-represented (6 draft items + existing). |
| 2 | Board game born in India in the 6th century → chess | The origin and date of chess are disputed ("6th century" is too precise). Also duplicates final_world_b L5 (chaturanga originated in India). |
| 3 | Joan of Arc's age at death (slider 19) | Her birth date is only approximate (c. 1412). Joan's death is already in existing L1 (burned at the stake 1431). |
| 3 | Island of the moai → Easter Island | Duplicate of existing_art L4 (moai) and draft_world_a (Easter Island moai). |
| 3 | "The Art of War" attributed to → Sun Tzu | Duplicate of existing_literature L4. |
| 4 | Modern country of ancient Troy → Turkey | Too close to legend (Trojan War). The site identification is better left to mythology/archaeology. |
| 4 | Moorish palace-fortress of Granada → Alhambra | Duplicate of existing_art L5 and L7 portrait. |
| 4 | Country of the Nazca Lines → Peru | Duplicate of draft_art_a L3 (same question). |
| 5 | Where the Magyars settled → Hungary | The answer is a give-away in Hungarian (magyar = Hungarian), a translation problem. Magyars are also in the L8 Lechfeld slider. |
| 5 | Stoic emperor who wrote "Meditations" → Marcus Aurelius | Duplicate of existing_world L5 (same question) and existing_literature L7. |
| 6 | Height of the Leaning Tower of Pisa (slider) | Architecture/number trivia, not history. Pisa is already in existing_art and the images. |
| 6 | Author of the "Canon of Medicine" → Avicenna | Duplicate of existing_science L8 (same question). |
| 6 | Great Zimbabwe built by ancestors of the Shona (tf) | Would be the 3rd Great Zimbabwe item (existing_history L5 + draft_art_a L6). |
| 7 | 5th-century Indian astronomer, Earth turns on its axis → Aryabhata | Duplicate of final_science_a L8 (same fact). |
| 8 | Ethiopian king who had the churches carved out of rock → Lalibela | The attribution is traditional, and archaeology dates some churches differently. It would also be the 3rd Lalibela item (image + draft_art_a L5). |

## Fixed (5)

- **L1 papyrus**: correct option changed from "A kind of paper" to "Sheets to write on". Papyrus is not true paper. The old option contradicted the L1 tf "Paper was first invented in China". In many languages the old answer was also given away by the papyrus/paper word link.
- **L2 Athens democracy**: removed the "first developed" claim. Earlier popular governments are attested (e.g. Chios). It now reads "In which Greek city-state did Cleisthenes introduce democracy around 508 BC?".
- **L6 Ghana Empire**: removed "had its capital at Koumbi Saleh". That identification is probable but not certain. It now reads "…older than Mali, was famed among Arab writers for its gold?".
- **L8 Olga of Kyiv**: the four revenges on the Drevlians come from the semi-legendary account in the Primary Chronicle. The question now uses her documented baptism in Constantinople and her 10th-century regency.
- **L7 Tamar**: distractor "Olga" replaced with "Zoe". Olga is now the answer of another question.

Checked and kept as written: "Paper was first invented in China" (true: papyrus and parchment are not paper), "Chinese printed with movable type before Gutenberg" (Bi Sheng, 1040s), and the Diamond Sutra of 868 as the oldest known *dated* printed book. Each of these claims is mainstream and worded carefully. "On how many hills was Rome built" keeps "according to tradition".

## New (12)

| Lvl | Question | Answer |
|---|---|---|
| 1 | Armoured warriors on horseback who served lords in medieval Europe | Knights |
| 1 | Water-filled ditch around many medieval castles | A moat |
| 1 | The ancient Romans built paved roads across their empire (tf) | True |
| 2 | In early medieval Europe, where were most books copied by hand? | Monasteries |
| 2 | Most educated people in medieval Europe believed the Earth was flat (tf) | False |
| 3 | Germanic people who gave their name to France | The Franks |
| 3 | Language mainly used by the Byzantine court around 1000 | Greek |
| 4 | City where the popes resided 1309–1377 | Avignon |
| 4 | Florentine banking family, leading Renaissance patrons | The Medici |
| 6 | Holy Roman Emperor drowned in Anatolia during the Third Crusade | Frederick Barbarossa |
| 6 | General who led the first Muslim landing in Iberia, 711 | Tariq ibn Ziyad |
| 7 | Chinese monk who returned from India in 645 with Buddhist texts | Xuanzang |

I checked every new item against the existing files of all subjects and against the v5 drafts. None duplicates an existing question.

## Repetition notes (≤ 2 per topic, existing questions counted)

Pairs that stay at 2: Pompeii/Vesuvius (existing + Herculaneum), Cleopatra, Ashurbanipal (comparison + library), Attila, Richard I (Lionheart + Eleanor), Timbuktu (existing + Sankore), Carthage (existing Tyre + vs Alexandria), Constantine (existing Edict + 330), Granada (1492 only, after the Alhambra drop), Barbarossa (comparison + new), Norse in North America (Leif Erikson + L'Anse aux Meadows), and Kyiv (Olga + 1240 sack).
