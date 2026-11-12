# Review — world, lane b (v5)

Draft: 125 questions. Final: 117 (103 kept from the draft, 8 of them fixed; 14 dropped; 6 new).
Per level: L1 15, L2 14, L3 15, L4 15, L5 15, L6 14, L7 14, L8 15.
Kinds: 80 mcq, 22 tf (11 true, 11 false), 15 slider. Validated with python3 (field checks per kind, mid-range check, length, no duplicates).

## Dropped (14)
- **L1 Badminton / shuttlecock**: trivial in some languages. In Chinese (羽毛球) and German (Federball) the shuttlecock and the sport have the same name.
- **L2 Hummus → chickpeas**: in Arabic and Hebrew "hummus" is the word for chickpea, so the question gives away its answer.
- **L2 "sauna" comes from Finnish**: a question about a word (forbidden), and trivial in Finnish.
- **L2 Olympic flame lit in Greece**: Olympics overload (existing: rings, Athens 1896, Chamonix 1924; draft keeps women in 1900). Also not true before 1936.
- **L4 Bicameral parliament**: gives itself away in translation (Zweikammer-, kaksikamarinen, 两院制 all say "two chambers").
- **L4 UN official languages (6)**: UN overload. The existing file already has 3 UN questions (founding, 193 members, HQ), and the draft keeps the Security Council and League vs UN.
- **L5 Arabic alphabet (28)** and **L6 Hebrew alphabet (22)**: free points for Arabic and Hebrew players at L5/L6. Not fair across languages.
- **L7 Stagflation**: the term is a near give-away (stagnation + inflation), and it is the 3rd question on inflation (existing tf plus hyperinflation L4).
- **L7 Ge'ez script not used for Swahili**: a 3rd question on Swahili (existing official-language question plus Niger-Congo L6), and it adds to Ethiopia overload.
- **L7 Hiragana has 46 characters**: trivial for Japanese players at L7. Also unclear, because Japanese call the table gojūon ("50 sounds").
- **L8 Zera Yacob, "Hatata"**: who wrote it is disputed (the Conti Rossini / Giusto d'Urbino forgery thesis). This also removes Ethiopia overload.
- **L8 "ubuntu" comes from Nguni languages**: a question about a word (forbidden), and it repeats the L6 Ubuntu question.
- **L8 Code of Hammurabi, about 282 laws**: the count depends on a modern numbering, the stele has a lacuna, and sources differ. Not a stable count.

## Fixed (8)
- **L1 52-card "standard deck"**: not standard in Spain, Italy or Germany (40, 32 or 48 cards there). Now asks about a "poker deck, without the jokers".
- **L2 Couscous (North Africa)**: moved from L3 to L2 (easy; also balances the levels).
- **L3 Ceviche**: now says "is considered the national dish" (it is official heritage in Peru; Ecuador also claims the dish).
- **L4 Day of the Dead**: "honours deceased family members" gave the name away in every language. Now uses sugar skulls and family altars. The weak distractor Candlemas is replaced by Guelaguetza.
- **L5 I Ching**: "Book of Changes" is the literal Chinese and Japanese name (易經), a give-away. Now asks about divination with 64 hexagrams.
- **L5 Navaratri**: "nine nights" is the literal meaning of the name (a give-away in Hindi). Now "Hindu autumn festival devoted mainly to Durga". Durga Puja is not among the options.
- **L6 Kintsugi**: "with gold" gave the name away in Japanese (金継ぎ). Now "repairs broken pottery so that the cracks stay visible".
- **L7 Legalism**: "strict laws" gave the name away (Legalism / 法家). Now "adopted by the Qin dynasty… harsh punishments create order".

## New (6)
- L4 Vesak → Buddhism.
- L7 Zhuangzi's butterfly dream.
- L7 Heraclitus, "everything flows / same river twice".
- L8 Abu Hanifa (Hanafi school: Turkey, South Asia).
- L8 Thorstein Veblen, "conspicuous consumption" (1899).
- L8 Zhu Xi: his commentaries became the basis of the imperial exams from 1313.

## Checked and kept (notes)
- **Food origins** kept only where clear-cut: tacos, cacao, tea (China), pasta (wheat), potato (South America), tequila (agave), couscous, feta, chili from the Americas, tempura (Portuguese).
- **Religion** questions are neutral and mainstream. "Five pillars" is the standard encyclopedic term. Eid al-Adha is worded "his son", without naming which son.
- **Stable counts only**: chessboard 64, UNSC 5 permanent members, EU flag 12 stars (fixed by design), ICJ 15 judges (Statute), Ramadan at most 30 days, Panini "nearly 4,000" rules (3,959 sūtras).
- **Script questions kept as still fair**: Japanese uses more than one script (L3, easy anyway), Hangul (L4), Devanagari (L5), Brahmi (L7), Arabic right-to-left (L1).
- **Repetition** checked against existing_world.txt: Mecca 2, ICJ 2, Nobel 2, World Cup 2, Aristotle ≤2, Córdoba 2 (Averroes existing + Maimonides), Ubuntu 1.
