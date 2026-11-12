# Review — literature, lane a (before 1850, worldwide)

Draft: 125 questions. Final: 117 (L1 14, L2 14, L3 15, L4 15, L5 15, L6 14, L7 15, L8 15).
95 kept unchanged, 7 fixed or reworded, 3 re-levelled only, 20 dropped, 12 new.
Validated with python3: mcq 2/4 distinct options, tf bool, sliders int with min<value<max and value not at mid-range, no question >110 chars, no option >30 chars.

Cross-batch check: compared with draft_mythology_a/b, final_mythology_a/b, existing_mythology.txt and draft/final_literature_b.
final_mythology_a dropped Grendel, both Pied Piper items and the Tristan potion. Those facts are therefore asked only here, so I kept them.

## Dropped (20)

Duplicates of mythology (existing or this batch):
- L1 "King Arthur's legendary sword" (Excalibur): exact duplicate of existing_mythology.
- L2 "Which wizard is the adviser of King Arthur" (Merlin): exact duplicate of existing_mythology.
- L2 "Which was written first? Beowulf / Hamlet": Beowulf is already asked twice in the batch (Grendel here, the dragon in final_mythology_a). Hamlet is also already in existing_literature.
- L1 William Tell's apple: Tell is already in final_mythology_a (tf on Austria) and here in the Schiller drama question. Dropped to keep at most 2.
- L2 Mulan goes to war for her father: same fact as final_mythology_b.
- L7 Kebra Nagast, the Queen of Sheba meets Solomon: same fact as final_mythology_b (Sheba visits David → false).
- L7 Nibelungenlied, Siegfried's heel: same fact as final_mythology_a (linden leaf, spot on his back).
- L8 Popol Vuh is Aztec (false): existing_mythology already asks that it is the K'iche' Maya book.
- L4 Bhagavad Gita is part of the Mahabharata: existing_mythology already has "The Bhagavad Gita is part of the Ramayana → False".

Prosody:
- L7 "How many syllables does a classical Japanese tanka have?" (31): the units are morae (on), not syllables, so the question is false in Japanese. A rewording to "lines" is not safe either, because tanka are traditionally written as a single line in Japanese.

Repetition (max 2 per person/work, counting existing):
- L7 "Who lived earlier? Kalidasa / Li Bai": Li Bai would be asked 3 times (existing Tang question, the moon legend, this one).
- L6 "What was Voltaire's real name?": Voltaire is already asked 3 times in existing (portrait, Candide ×2).
- L1 "Shakespeare's Hamlet is a prince of Denmark": Hamlet is in existing, and Shakespeare already has many questions in existing and in this draft.
- L3 slider, year the Globe opened: second Globe question, and too many Shakespeare items.
- L1 Perrault's "Cinderella", pumpkin into a coach: this would be the 3rd Cinderella question and Perrault's 3rd mention.
- L2 Pride and Prejudice, Elizabeth marries Darcy: Austen is already asked 3 times in existing.
- L5 slider, year Wuthering Heights was published: Emily Brontë is also in the Heathcliff question and the pen-names tf.
- L6 slider, year The Last of the Mohicans was published: second question on that work, and a dull date. The "Who wrote" mcq is kept.

Weak:
- L2 slider, how many bears does Goldilocks meet: the answer is in the tale's title in most languages.
- L1 "What is a playwright?": the word gives the answer in many languages (e.g. Japanese 劇作家, "play-writer").

## Fixed / reworded (7)

- L6 → L7 "Who was born earlier? Sor Juana Inés de la Cruz / Voltaire": Voltaire's quota was full. I replaced him with Jean Racine (b. 1639). Racine is now the correct answer, because Sor Juana was born in 1648 (some sources say 1651). The new pair is harder, so it moves up to L7.
- L6 Li Bai's death: the correct option "Grasping at the moon in water" stood out by length and form. Rewritten as "the poet Li Bai drowned while trying to embrace what?" with parallel options: The Moon's reflection / A floating lantern / A golden carp / A lotus flower.
- L4 "Who wrote 'Ivanhoe' (1819)?": removed the date. The novel came out in December 1819, but the title page says 1820.
- L7 Don Juan: "is credited" → "is traditionally credited". Tirso de Molina's authorship of "El burlador de Sevilla" is disputed (some attribute it to Andrés de Claramonte).
- L3 → L2 Bluebeard: removed "Perrault's" (Perrault's quota). Re-levelled to L2, because the beard colour is in the title in nearly every language.
- L3 Munchausen: "boastful baron of German tales" → "boastful baron of literature". The tales were first published in English, by Raspe.
- L5 Antigone: "In Sophocles' play" → "In the Greek tragedy" (Sophocles is already at 2 in existing).

## Re-levelled only (3 more; the 2 fixes above also changed level)

- "Sleeping Beauty", spindle: L2 → L1.
- "The voice that tells the story" (narrator): L2 → L1.
- Mozart "Marriage of Figaro" / Beaumarchais tf: L5 → L6.

## Checked and kept, items with known problems

- French alexandrine, 12 syllables: kept. The question is about French verse and states a French count, so it is true in any language. There are no English-metre questions in the draft.
- Publication dates, all checked: Utopia 1516; Perrault 1697; Encyclopédie vol. 1 1751; Princesse de Clèves 1678; Lazarillo 1554 (four editions known from that year); Schiller "William Tell" 1804; Pan Tadeusz 1834; Kalevala 50 poems (1849 edition); Man'yōshū about 4,500 poems; Three Kingdoms 120 chapters (Mao Zonggang edition); Decameron 100 tales; Lusiads 10 cantos; Keats died aged 25.
- Authorship: Machiavelli's Prince was published after his death (1532), so the tf is correctly false. Lyrical Ballads was a joint work of Wordsworth and Coleridge. Chrétien de Troyes is the consensus first literary Grail. The Nutcracker is from Hoffmann (via Dumas).

## New questions (12)

All are pre-1850 and outside mythology. I checked each against existing_*, every v5 draft and every final for the same fact.
- L1 mcq: Rumpelstiltskin spins straw into gold.
- L1 tf (true): the Beast is a prince under a spell.
- L2 tf (false): the Bremen Town Musicians perform in Bremen. They never reach the city.
- L2 mcq: in "The Frog Prince", the princess drops a golden ball into a well.
- L2 mcq: Momotarō is found inside a peach. Mythology b asks a different fact about him (his animal helpers).
- L2 mcq: the youngest of the seven young goats hides in the clock case. The distractors are where its siblings hide, so they are certainly wrong for the youngest.
- L3 tf (false): the Panchatantra comes from ancient China. It is Indian.
- L5 mcq: the Butterfly Lovers (Liang Shanbo and Zhu Yingtai) become butterflies.
- L6 mcq: Ivan Krylov is Russia's most celebrated fabulist.
- L7 mcq: the Mu'allaqat are pre-Islamic Arabic odes.
- L7 tf (true): Kabir is traditionally said to have been a weaver.
- L8 mcq: Pu Songling's "Strange Tales from a Chinese Studio" are mostly about ghosts and fox spirits.

I wrote 3 more replacements and then removed them when restoring the 4 mythology-overlap items. The cut ones are: the boy who cried wolf (too many Aesop fables already), "elegy" (weak definition question) and the brave little tailor (level balance).
