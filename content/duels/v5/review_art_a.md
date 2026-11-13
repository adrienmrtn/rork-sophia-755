# Review: art, lane a (visual arts, architecture, photography, fashion), v5

Draft: 125 questions. Final: 117 questions. 106 come from the draft (9 of them fixed), 19 were dropped and 11 are new.
Per level: L1 15, L2 15, L3 15, L4 15, L5 15, L6 14, L7 14, L8 14.
Kinds: 80 mcq, 21 tf (11 true, 10 false), 16 slider. The file was validated with python3. The checks were: count, levels, mcq with 2 or 4 distinct options, tf answer is a bool, sliders use integers with min < value < max, the value is not at mid-range and sits on the step grid, question length ≤ 110, options ≤ 30, and no duplicates.

Cross-lane check: I compared the draft with final_world_b, final_art_b, draft_history_a, draft_history_b, draft_world_a and draft_mythology_b, and with existing_art and existing_history. There is no final_history_b yet.

## Dropped (19)

### Same fact in another lane or in the existing questions
- **L4 Kintsugi, "gold"**: final_world_b L6 already asks about kintsugi. The answer is also given away in Japanese and Chinese, because 金継ぎ contains 金 (gold).
- **L5 Lalibela, the country (Ethiopia)**: draft_history_a L8 asks "Which Ethiopian king had churches carved out of solid rock", so the same fact is covered there.
- **L4 Teotihuacan, the country (Mexico)**: existing_history L6 already pairs the Pyramid of the Sun with Teotihuacan, and the question restated that.
- **L3 Nazca Lines, the country**: same question as draft_history_a L4.
- **L2 Petra, the country**: same question as draft_world_a L4.
- **L1 Great Wall, the country**: same question as draft_world_a L1.
- **L2 Venice (canals)**: same question as draft_world_a L1 (canals and gondolas).
- **L6 Louvre opened in 1793**: the Louvre is already in three existing questions (its city, the Mona Lisa theft and Pei's pyramid).
- **L4 Empire State Building, number of floors**: two existing questions already cover it (King Kong, and the Chrysler comparison).

### Give-away or translation problem
- **L2 Pentagon, number of sides**: the name says "five" in every language.
- **L1 Watercolour thinned with oil (false)**: the name gives it away (Aquarell, acuarela, 水彩).
- **L2 Collage ("made by gluing")**: in French, coller means "to glue".
- **L2 Mural ("painted on a wall")**: in Spanish and Italian, muro means "wall", and French says "peinture murale".
- **L1 Self-portrait (definition)**: in every language the word itself is the definition.
- **L5 Arabesque typical of Islamic art (true)**: the word points to the answer. The word also appears in final_art_b as a ballet option.

### Overload or a clash with another question
- **L5 Ukiyo-e carved in wood**: the L4 true/false question says "Japanese woodblock prints", which gives this answer away. Ukiyo-e is also covered in the existing questions (its meaning, Hokusai, Hiroshige, Utamaro).
- **L4 Art Deco before Art Nouveau (false)**: a 3rd question on Art Nouveau. The L5 Art Nouveau question and the L8 Horta question are kept.
- **L7 Goya's Black Paintings**: a 3rd question on Goya. The existing questions already have Las Meninas (Goya as a false answer) and an image of the Third of May.
- **L8 Judith Leyster was a Dutch Golden Age painter (true)**: the weakest L8 question. Dropping it balances the levels.

## Fixed (9)
- **L1 Venus de Milo arms**: as a slider, the value 0 equalled the minimum, which breaks the min < value < max rule. It is now a true/false question: "has lost both its arms" (true).
- **L1 Big Ben**: the name belongs to the bell, not the tower. The question now says "the clock tower popularly known as Big Ben".
- **L3 Pointillism**: "small dots" gave the name away (point / 点描). The question now asks which technique Georges Seurat used. Seurat appears in 2 questions in total.
- **L4 Icon**: "sacred image" gave the word away in Greek (εικόνα means "image"). The question now says "painted wooden panels of Christ and the saints".
- **L6 Sfumato**: "Italian term" and "smoky" pointed to the answer (fumo means "smoke"). The question now says "gradual blending of tones with no sharp outlines". It does not mention Leonardo, who is already overloaded in the existing questions.
- **L7 Encaustic**: "hot wax" hinted at the Greek enkaustikos ("burnt in"). The question now says "pigments mixed with beeswax".
- **L7 Cueva de las Manos**: the name means "Cave of the Hands" in Spanish, so the old question ("famous for what?") gave itself away. It now asks for the country (Argentina).
- **L7 Bayeux Tapestry length**: the value is changed from 70 to 68 m (68.38 m).
- **L6 Dior New Look**: the slider minimum is changed from 1900 to 1880, so that 1947 is not near mid-range.

## New (11)
- L1 Landscape (painting genre)
- L1 Caricature
- L2 Kilt, Scotland
- L2 Camera lens
- L2 Matryoshka dolls fit inside each other
- L2 Great Pyramid once covered in white limestone (true). It is the 2nd art question on the pyramid.
- L4 Gargoyles drain rainwater
- L4 Borobudur, Indonesia. The existing questions have Borobudur only in an "older?" comparison.
- L4 Atomium, Brussels
- L5 Ishtar Gate, Babylon. draft_history_a asks only which country Babylon is in.
- L5 Yves Saint Laurent, "Le Smoking" (1966)

## Checked and kept (notes)
- **Great Zimbabwe, built without mortar**: kept. draft_history_a asks a different fact (the Shona built it).
- **Nefertiti, Amarna bust**: kept. draft_history_a asks about her as Akhenaten's wife, which is a different fact. The verifier for the history lane may want to reconsider it.
- **Pisa, built as a bell tower**: kept. draft_history_a has a different fact (its height).
- **Isfahan, Naqsh-e Jahan**: kept. draft_history_b asks a different fact (Abbas I's capital).
- **Benin**: the lost-wax question is kept, and it is the 2nd art question with the existing Benin–Nigeria question. draft_history_a also asks "Kingdom of Benin, which country", which is close to existing_art L7. That is for the history verifier.
- **Dates and attributions checked**:
  - Golden Gate Bridge 1937; Brooklyn Bridge 1883; Guggenheim Bilbao 1997.
  - New Look 1947; daguerreotype 1839; Crystal Palace 1851; Le Smoking 1966.
  - Black Square 1915; Die Brücke in Dresden, 1905; Gauguin in Tahiti from 1891.
  - Süleymaniye (1557) completed before St Paul's (1710).
  - Dürer (1471) born before Caravaggio (1571); Titian (c. 1488) born before Rubens (1577).
  - Futurism (1909) came before Surrealism (1924).
  - Donatello's bronze David; Anguissola at the court of Philip II; Huizong reigned 1100–1126.
  - Hamzanama commissioned by Akbar; Pakal's mask found at Palenque; Horta worked in Brussels.
  - Hilma af Klint's abstract work (1906) came before Kandinsky's (around 1911).
  - Pantheon dome 43 m; Ryōan-ji has 15 stones; 8 Impressionist exhibitions; Mount Rushmore took 14 years (1927–41).
- **Japanese and Chinese terms**: kimono, Ryōan-ji and the celadon question (answer: Korea) do not give their answers away. On the Han jade suits (玉衣), the translator should not use the term 玉衣 in the question.
