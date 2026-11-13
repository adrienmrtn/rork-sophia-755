# Review: mythology, lane b (non-European traditions, Bible/Quran stories, Arabian Nights)

Draft: 125 questions. Final: 117 (112 kept, 16 of them fixed or re-levelled; 13 dropped; 5 replacements written).
Levels: L1 15, L2 15, L3 14, L4 14, L5 15, L6 14, L7 15, L8 15. Kinds: 83 mcq, 20 tf (11 true / 9 false), 14 slider.
Target languages checked for name give-aways: the 29 in content/duels/i18n. Japanese, Arabic, Hebrew and Turkish matter most for this lane. No Chinese, Hindi, Korean or Indonesian.
Checked against existing_mythology.txt. No draft_mythology_a.json is present, so lane a could not be cross-checked; the global dedup step should do it. Egypt and Mesopotamia were treated as part of this lane (non-European).

## Dropped
- **L1 tf "Adam and Eve live in the Garden of Eden".** Too trivial. It would also have made 3 questions on Adam (with the forbidden-tree question and Iblis refusing to bow).
- **L1 tf "The Buddha was born in China".** The Buddha would have had 4 questions (this one, the bodhi tree, the four sights, the Jataka tales). Dropped along with the Jataka question to bring him to 2.
- **L1 tf "Aladdin's genie appears when he rubs a magic carpet".** Same fact as the L1 "lamp" mcq.
- **L3 mcq "In Japanese folklore, what are oni?"** Untranslatable into Japanese. 鬼 is the everyday Japanese word for demon or ogre, so the question becomes "what is a demon?".
- **L4 tf "the tanuki is a shape-shifting raccoon dog".** In Japanese, 狸 is simply the name of the animal, so the statement collapses. It also repeats the form of the existing kitsune true/false question.
- **L4 slider "principal avatars of Vishnu = 10".** Lists differ. The Bhagavata Purana gives 22 or more, and the ten of the Dashavatara vary (Buddha or Balarama, Krishna). This is the standard the previous verifier already applied.
- **L4 mcq Nian (New Year beast).** In Japanese (年獣) the name literally means "year beast", and the question mentions New Year, so it gives the answer away.
- **L6 tf "Tangaroa is the god of forests and birds".** It overlaps with the L7 Tāne question, whose answer is the god of forests. Māori stays at 3 questions on different subjects.
- **L6 mcq "the four Dragon Kings rule over the four seas".** The standard Japanese name 四海竜王 ("Dragon Kings of the Four Seas") contains the answer.
- **L7 mcq Jataka tales.** Buddha repetition (see above).
- **L7 mcq "name of the Chinese phoenix: Fenghuang".** Makes no sense in Japanese, where 鳳凰 (hōō) is the ordinary word for phoenix.
- **L7 mcq "Yemoja, mother goddess of the sea".** Versions differ. In Yorubaland Yemoja is the orisha of the Ogun River, and Olokun is the sea deity. The sea role belongs to the Afro-Cuban and Afro-Brazilian forms (Yemayá, Iemanjá).
- **L7 tf "Eshu is the supreme creator god".** Near-duplicate of the L6 Olodumare question (same fact).

## Fixed
- **L1 Cain/Abel tf:** changed to the swapped-name trap "Abel kills his brother Cain" (false), to rebalance true and false answers.
- **L2 Aztec eagle:** removed "eating a snake". The snake appears only in later versions; early sources show the eagle eating a bird or nothing. The cactus is constant across versions. The question now names Tenochtitlan.
- **L3 Iblis:** "before which man?" became "before whom?". In Hebrew and Arabic, adam/ādam also means "man" or "human", so "which man" points straight at the answer.
- **L3 Ahura Mazda:** "god of wisdom and goodness" became "supreme creator god", because *Mazda* means "wisdom". Distractor Anahita (a goddess, so her gender gave her away) was replaced by Ahriman.
- **L3 Dreaming:** "the time when…" became "the Dreaming tells how ancestral beings shaped the land". Many Aboriginal sources reject treating the Dreaming as only a past era. "Traditions" is now plural.
- **L4 Pangu:** distractor Nüwa (female, and the answer to an existing question) was replaced by Gonggong.
- **L4 roc:** "strong enough to carry off elephants" became "lays an egg that looks like a white dome". The dome egg is a precise scene from the second voyage. The elephant detail is phrased differently across translations, and Marco Polo attributes it to the roc outside the Nights.
- **L5 Izanagi/Izanami:** "In the Kojiki" became "In Japanese myth". The Kojiki would otherwise have had 3 questions.
- **L5 Guanyin:** now called a "bodhisattva of mercy, often shown as a woman" rather than a "goddess", which is more accurate and respectful.
- **L5 Chaac:** distractor Ix Chel (a goddess, eliminated by "god") was replaced by Kukulkan.
- **L6 Olodumare:** distractor Oshun (a goddess, eliminated by "god") was replaced by Eshu.
- **L7 Jimmu:** "According to the Kojiki" became "According to Japanese legend" (Kojiki repetition; the Nihon Shoki agrees).
- **L7 Buraq:** "winged steed" became "heavenly steed". The hadith accounts describe it mainly as a white mount, and wings come mostly from later art.
- **L8 Anansi/Nyame:** distractor Mawu (a goddess, eliminated) was replaced by Amma (Dogon).
- **Re-levelled:** canopic jars moved from L5 to L4 and Budai ("Laughing Buddha") from L8 to L7, to even out the levels.

## Replacements (5)
- L1 mcq: the seed named in the words that open Ali Baba's cave, Sesame. The phrase is established in Arabic, Japanese, Hebrew, Finnish, Turkish and others. Ali Baba now has 2 questions.
- L1 tf: Scheherazade tells stories night after night to escape death (true). The frame story now has 2 questions, with the Shahryar question.
- L1 mcq: Buddhism, the final liberation from rebirth, Nirvana (distractors Karma, Mantra, Dharma).
- L7 mcq: Quran, the prophet sent to Thamud with the she-camel, Salih (distractors Hud, Shu'ayb, Idris).
- L7 mcq: Arabian Nights, the caliph who roams Baghdad in disguise with his vizier Ja'far, Harun al-Rashid. Ja'far makes the answer unique, because al-Ma'mun also appears in a few tales.

## Checked and kept (version-sensitive points)
- **Jade Emperor organises the zodiac race:** some Japanese and Vietnamese versions name the Buddha, but he is not among the options, and the question says "Chinese legend".
- **Methuselah 969:** the same figure in the Masoretic text, the Septuagint and the Vulgate. Only the Samaritan Pentateuch differs (720), which is too marginal to matter.
- **People of the Cave 309 years:** Quran 18:25 says "three hundred years, and added nine".
- **Other figures that are stable across sources:** Jonah 3 days, Jacob's 12 sons, the Eight Immortals, Hou Yi's 9 suns, 4 canopic jars, 4 sights, 4 yugas, the Aztec fifth Sun (5), 9 levels of Mictlan, the Kojiki in 712.
- **Five-clawed imperial dragon:** kept as "in imperial China… traditionally" (the Yuan to Qing rule).
- **Shamash on the Hammurabi stele:** standard identification (Louvre). Marduk is not an option.
- **Living religions:** the Bible/Quran questions are framed "In the Bible/Quran/Genesis/Islamic tradition". The Abraham question leaves the son unnamed, because the Bible names Isaac and the Muslim tradition generally identifies Ishmael. Hindu, Buddhist, Zoroastrian, Yoruba, Māori, Aboriginal and Native American items are phrased as "tradition/belief/stories", with no value judgements.
- **Repetition:** after the fixes no person, work or myth exceeds 2, counting existing questions (Noah, Jonah, Sinbad, Ali Baba, Scheherazade, Solomon, Adam, Krishna, Shiva, Ganesha, Chang'e, Māui, Urashima, Dangun, Amaterasu, Kojiki, Shahnameh, Popol Vuh, Mictlan, Anansi, Ishtar/Inanna, the Rangi–Papa separation: 2 each at most). The Arabian Nights and the Bible are treated as collections, counted per tale or story.
