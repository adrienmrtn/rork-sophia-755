# Review: image questions, batch v5 (draft_images_a + draft_images_b)

Independent check of all 100 draft image questions. I opened every output image (640x800) and zoomed in where text could appear. For each question I checked the fact, the distractors, the level, translatability, and duplicates against the 179 existing image questions in questions_en.json (no subject is repeated).

Result: 98 kept (89 unchanged, 9 fixed), 2 dropped. Every "image" key has its file (checked with python3).

## Dropped (2)
- **v5a_myth_durga** (L5): the print has a Devanagari caption at the bottom, "महिषासुरमर्दिनी" (Mahishasuramardini, "slayer of Mahishasura"), which is Durga's epithet. That gives the answer away in Hindi and to anyone who can read the script. To rescue it: re-crop the bottom ~8% (`crop [0,0,1,0.92]`) and re-run the image script.
- **v5b_monument_trevi** (L2): an old print caption "…NTANA DI TR…" ("Fontana di Trevi") is visible at the bottom left. It names the monument (so the city) and shows Italian text, which rules out Vienna. To rescue it: re-crop the bottom ~10% and re-run.

## Fixed (9)
- **v5a_harriet_tubman**: the question "Who is this woman, who led enslaved people to freedom?" can be answered without the picture. Now "Who is this American abolitionist?"
- **v5a_empress_cixi**: "Who is this Chinese ruler?" was weak, because the Korean Empress Myeongseong was ruled out by the word "Chinese" and Soong Ching-ling was never a ruler. Now "Who is this woman, who ruled China for decades?" (options unchanged; Wu Zetian is still the strong distractor).
- **v5a_myth_bastet**: the question asks for a goddess but the distractor was Anubis (a male god), so it was ruled out by grammar. Replaced it with Maat. I avoided Sekhmet because she is too close to Bastet.
- **v5a_myth_valkyrie**: "Which figure from Norse myth…" gave the answer away, because the other three options are Greek. Now "Which kind of mythical figure is shown riding into battle here?"
- **v5b_science_axolotl**: the wording "lakes near Mexico City" was imprecise, since the remaining wild population lives in the Xochimilco canals, inside the city. Now "survives only in the canals of which city?"
- **v5b_nature_old_faithful**: level 8 → 3. Yellowstone is famous for its geysers, and the other options have none.
- **v5b_monument_karnak**: level 8 → 7. The hypostyle hall is fairly well known.
- **v5b_monument_st_peters**: level 6 → 5.
- **v5b_science_pillars_creation**: level 7 → 6. It is an iconic image.

## Checked and accepted, with notes
- v5a_sargent_madame_x: the signature "John S. Sargent 1884" sits bottom right, dark on dark. Even at full 640px it is barely legible when zoomed, so I accepted it as a minor risk. Re-crop it if you want zero risk.
- v5a_ingres_odalisque: the signature on the cushion edge cannot be read at 640px.
- The signatures in v5a_rousseau_surprised, v5a_myth_valkyrie, v5a_roberts_shearing_rams and v5a_sorolla_seashore do not give away the answer to the question asked, or cannot be read.
- v5b_science_space_shuttle: the orbiter carries "Discovery / United States". The shape already gives the answer and the text does not name the vehicle type, so accepted.
- v5b_science_hubble: the NASA logo does not separate Hubble from the other NASA telescopes in the options.
- v5b_monument_temple_of_heaven: the small Chinese plaque does not name the city.
- v5a_myth_sisyphus: Atlas is a strong but certainly wrong distractor (this is Titian's Sisyphus pushing a rock in the underworld).
- v5a_qingming_scroll: the correct option is longer than 30 characters, but it is the work's standard title and has standard translations.
- Duplicates: none of the 98 subjects (people, paintings, monuments, flags, objects) matches an existing image question. "Winged Victory of Samothrace" and "Early Spring" appear only as distractors.
