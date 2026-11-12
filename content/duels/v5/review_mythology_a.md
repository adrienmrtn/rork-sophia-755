# Review — mythology, lane a (European traditions and folklore)

Draft: 125 questions. Final: 117 (95 kept from the draft, 6 of them reworded; 30 dropped; 22 new).
Levels: L1 15 · L2 15 · L3 15 · L4 15 · L5 15 · L6 14 · L7 14 · L8 14. Kinds: 85 mcq, 22 tf, 10 slider.
Validated with python3 (unique questions, mcq with 4 distinct options, tf bool, slider integers with
min < value < max, value not at mid-range, unit and step present).

## Dropped (30)

### Level 1: not mythology, or duplicate
- **Flag of Wales (red dragon)**: this is vexillology, not mythology.
- **Loch Ness**: this is modern cryptozoology and geography, not mythology.
- **Homer, Iliad and Odyssey**: the exact same question is in existing_literature (L1).
- **Black cat as a witch's companion**: a second L1 witch cliché next to the broomstick question. Dropped to make room for more topics.
- **Poseidon's trident**: the existing file already has 2 questions about Poseidon (sea-god TF, Neptune). This would be a third.

### Max-2 rule (counting existing questions)
- **Kalevala: Lönnrot 1835 slider**: the Kalevala would reach 3 questions (existing Ilmarinen/Sampo + kantele + this one). I cut this one, a bare date; the kantele question stays.
- **Argonauts: the ship Argo, the dove at the Clashing Rocks, and the author of the Argonautica**: the existing file already has 2 Argonaut questions (Golden Fleece, Medea). All 3 dropped.
- **Hesiod/Theogony: the Muses on Helicon, the Hundred-Handed TF, the slider on the Hundred-Handed's 50 heads, the slider on 3,000 Oceanids**: the existing file already has 2 Theogony questions (Chaos, 12 Titans), and the Muses already have 3 (9 Muses, Clio, Mnemosyne). Works and Days (5 ages) is a separate work, so it stays.
- **Minerva = Athena**: Athena already has 2 existing questions (born from Zeus's head, owl), and the olive-tree contest stays. Juno = Hera kept instead, since Hera has only 1 existing question.
- **Lyre as Apollo's emblem**: Apollo already has 2 existing questions, and the lyre also already has one (Hermes made the first lyre).
- **Thor's chariot pulled by goats (TF)**: Thor is far above 2 in the existing file. The Thor episodes kept are the dwarves who made the hammer and the Utgard-Loki story.
- **Zeus as a swan with Leda**: same form as the Europa question ("in what form did Zeus…"). Zeus is already saturated.

### Duplicates across subjects
- **Ovid wrote the Metamorphoses**: identical to existing_literature L6.
- **Roland dies at Roncevaux**: same fact as existing_literature L7 (he dies in the Pyrenees). The Roland horn TF stays.
- **Faust sells his soul to the devil**: existing_literature already has 2 Faust questions, one of them the pact with the devil.
- **Pied Piper TF (the town refused to pay him)**: the same statement is in draft_literature_a (L1 TF).
- **Tristan and Iseult love potion**: the same fact is in draft_literature_a (L5 TF).
- **Grendel attacks Hrothgar's hall**: the same fact is in draft_literature_a (L3, "which monster does Beowulf fight first → Grendel"). The Beowulf dragon TF stays.
- **Antigone buries her brother**: the same fact is in draft_literature_a (L5).
  - *Coordinator note*: if the literature verifier drops its versions of the last four, they could be restored here.

### Sliders whose figure varies, or whose source is not named
- **Pied Piper, 130 children**: the question does not name a source, and the number varies between versions. Dropped.
- **Saint Ursula, 11,000 virgins**: the number varies and is disputed (it may come from a misreading of "XI M"), and the question names no source. Dropped.
- Kept, but reworded to name the source where the figure is canonical: Atlantis, Draupnir and Lir (see "Reworded" below).

### Baltic and Slavic names that give the answer away
- **Saulė is the thunder deity (TF)**: Saulė means "sun" in Lithuanian, so the answer is obvious there.
- **Eglė marries a grass snake**: in Lithuanian, the tale's title ("Eglė žalčių karalienė", "queen of the grass snakes") gives the answer.
- **Lāčplēsis gets his strength from bear's ears**: the name means "bear-slayer" in Latvian.
- **Leshy is a sea spirit (TF)**: "les" means "forest" in Slavic languages, so the answer is obvious there.
- Checked and kept: Kalevipoeg TF (the name means "son of Kalev" and does not reveal Estonia vs Latvia), Koschei, Baba Yaga, the Firebird, Svantevit.

## Reworded (6)
- **Helios**: "which Titan" → "which god" (Helios is the son of Titans; calling him a Titan is loose).
- **Pleiades (7)**: removed "daughters of Atlas". Atlas already has 2 existing questions.
- **Vestals (6)**: no longer names Vesta, because it would give away the L4 question "which goddess's flame…".
- **Atlantis (9,000)**: now names the source, Plato's *Critias*, where 9,000 years is the canonical figure for the war with Atlantis.
- **Draupnir (8)**: now names Snorri's Prose Edda as the source. The figure of 8 is also the one in Skírnismál.
- **Children of Lir (900)**: now names the Irish tale. It no longer says "as swans", which would give away the L5 question.

## New (22)
Every new question was checked against existing_mythology and the other subjects' files: no duplicates, and no topic goes above 2.
- **L1**: Ares (war); werewolf (silver bullet); Norse giants as the gods' enemies; Cupid.
- **L2**: Morpheus (dreams); Chiron taught Achilles (TF); the Chimera (2nd question with the existing Bellerophon one).
- **L3**: Eris and the golden apple (2nd question with the existing Paris one); the changeling.
- **L4**: the Aesir; the Roman augurs (the flight of birds).
- **L5**: the rusalki (water).
- **L6**: the kelpie; Hel; the Saturnalia.
- **L8**: the Ankou (Brittany: 2nd question with Ys); Orion blinded by Oenopion; Epona; Alcestis; Lia Fáil (TF); Oenomaus and Pelops; Thökk refusing to weep for Baldr.

## Points I checked and kept
- **William Tell / Austria (TF, false)**: a good trap, because Tell fought *against* Habsburg rule.
- **Athena's olive tree**: the distractor "a horse" is Poseidon's gift in some versions, not Athena's, so it is still certainly wrong.
- **Morgan le Fay as Arthur's half-sister**: this is the mainstream (Malory) version.
- **Twelve peers of Charlemagne**: the number is stable even though the names on the list vary.
- **Siegfried's linden leaf (TF)**: draft_literature_a has a related trap ("vulnerable spot is his heel", false). These are close but not the same question. Flagged for the coordinator.
