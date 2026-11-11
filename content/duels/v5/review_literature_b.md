# Review — literature, lane b (v5)

Draft: 125 questions. Final: 117 (117 kept from the draft, 16 of them fixed; 8 dropped; 0 new).
Per level: L1 15, L2 15, L3 15, L4 15, L5 15, L6 14, L7 14, L8 14.
Kinds: 78 mcq, 24 tf (12 true, 12 false), 15 slider. Validated with python3: field checks per kind, distinct options, slider integers with min < value < max and value off mid-range, lengths, no duplicates. Checked against existing_literature.txt (no duplicate; max 2 per person/work counting existing) and against draft_literature_a.json (no overlap).

## Dropped (8)
- **L1 "What are Japanese comics called?" → Manga**: a question about a word. In Japanese (漫画 = comics) it makes no sense. Manga stays covered by the right-to-left tf and Dragon Ball / Tezuka.
- **L2 Stuart Little is a mouse**: second E. B. White question, and the weakest title across languages. Also cut to balance levels.
- **L3 Nobel Prize presented in Stockholm**, **L4 slider: first Nobel in Literature 1901**, **L5 Saramago, Nobel 1998**, **L7 slider: Solzhenitsyn's Nobel year 1970**: too much Nobel. The draft had 11 Nobel items and the existing file already has about 10 ("first Asian/Latin American/sub-Saharan laureate", Tolstoy and Borges never won, and so on). Kept 7 that are stable historical facts: Sartre declined; Morrison was the first Black woman (1993); Pamuk was the first Turkish laureate (2006); Mann won before Hesse; Ishiguro was born in Nagasaki; Coetzee was born in South Africa, not Australia; and a woman first won in 1909. The 1901 slider was also redundant with the 1909 slider.
- **L6 slider: "The Second Sex" 1949**: second Beauvoir item, its value was close to mid-range, and L6 already had 5 year sliders.
- **L8 slider: "Lolita" 1955**: redundant with the L8 tf "Lolita was first published in the US" (false: Paris, 1955).

## Fixed (16)
- **L1 Smurfs colour → houses shaped like mushrooms**: the Hungarian name for the Smurfs ("Hupikék törpikék", which means "light-blue dwarfs") gives the colour away. Now asks about their mushroom houses, which works whatever the Smurfs are called locally.
- **L1 Peanuts / Snoopy**: removed the strip title. In Swedish the strip is called "Snobben", which is Snoopy's local name, so the title gave the answer away. "Charles Schulz's comic strip" + Charlie Brown + Snoopy all work when localised (e.g. Finnish Jaska Jokunen / Ressu).
- **L2 Charlotte's Web**: the old question was "what animal is Charlotte? → spider", and titles give it away (English "Web", Spanish "La telaraña de Carlota"). It now asks what animal Wilbur is (a pig).
- **L2 Obelix**: "as a baby" → "as a small child". The comics show him as a little boy.
- **L3 Dragon Ball**: "searches for seven magic balls" hinted at the title (ドラゴンボール, Dragon Ball). It now describes Son Goku as a boy with a monkey's tail.
- **L4 Magic realism**: "calmly told magic" contained the answer word. Reworded to "tells supernatural events as if they were ordinary".
- **L6 Mafalda tf**: "created by a Spanish cartoonist" was not clearly false. Quino was Argentine but also took Spanish nationality in 1990. Changed to "a Brazilian cartoonist", which is clearly false.
- **Sliders widened or moved off the middle** (value now 10% or more of the range away from mid-range):
  - Anne Frank: 6–25 → 5–30
  - Peanuts 1950: 1880–2010 → 1870–2000
  - Lord of the Flies 1954: 1880–2010 → 1870–2010
  - Great Gatsby 1925: 1880–1990 → 1880–2000
  - Time Machine 1895: 1800–1960 → 1790–1950
  - Dune 1965: 1900–2010 → 1890–2010
  - Anne of Green Gables 1908: 1850–1990 → 1850–2000
  - A Madman's Diary 1918: 1860–2000 → 1860–2010
  - Flowers of Evil 1857: 1780–1950 → 1790–1960

## Checked and kept (notes)
- **Comic and superhero dates**: the only "first appearance" items are Superman (1938) before Spider-Man (1962), which is a huge gap, and the Peanuts slider (2 Oct 1950, well documented). Kryptonite, Gotham, Lucky Luke and Hergé being Belgian rely on no disputed dates.
- **Localised names**: Astérix, Obelix, Willy Wonka, Mary Poppins (Maija Poppanen), Long John Silver, Moomins, Doraemon, Son Goku (Sangoku) and Behemoth all still work when translated, because the question never depends on the spelling of a name.
- **Titles**: all kept titles have established translations: Nils, Call of the Wild, Charlie and the Chocolate Factory, Matilda/BFG, Catcher in the Rye, Handmaid's Tale, Half of a Yellow Sun, So Long a Letter (original French), Season of Migration to the North (original Arabic), Rayuela, Persepolis, Maus.
- **Manga right-to-left (tf, L3)**: kept. Japanese players will know it, but it is a fair L3 fact for everyone.
- **Rimbaud slider (16)**: Le Bateau ivre was written in summer 1871 and Rimbaud turned 17 in October 1871, so 16 is the standard figure. The slider tolerates ±1 anyway.
- **Heart of Darkness → Congo**: the river is not named in the text, but encyclopedias agree it is the Congo.
- **Repetition**: works with 2 items in this draft or counting the existing file: Narnia, Tarzan, Bond, Tintin/Hergé, Superman, Smurfs, Astérix, Peanuts, Gatsby, Call of the Wild, Simenon, Anne of Green Gables, Uncle Tom's Cabin, Dune, Persepolis, Moomins/Jansson, Lord of the Flies, Rimbaud, Lu Xun (+ existing Ah Q), Proust (+ existing), Zhivago (+ existing), Ulysses (+ existing), Master and Margarita (+ existing), Baudelaire (+ existing), Anne Frank (+ existing). None has more than 2.
