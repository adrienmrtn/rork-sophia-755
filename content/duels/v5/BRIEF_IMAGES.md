# Image questions (batch v5)

In a duel, an image question shows a picture (portrait 4:5 frame, 640×800) and 2–4 answers.
Read content/duels/v4/v4_BRIEF_WRITER.md and content/duels/v5/BRIEF_V5.md first (quality rules,
translatability). Existing image subjects: content/duels/v5/existing_images.md — never the same
painting, monument, person or flag again.

## Steps
1. Choose your images on Wikimedia Commons. **Only public domain or CC0** files (old paintings,
   pre-1900 photos, NASA/US-government works, PD-art reproductions; check the file page). Prefer
   high-resolution, clean, recognisable images (no watermarks, no frames with text, no collages).
   You can query the Commons API with curl, ALWAYS with a User-Agent header, e.g.
   `curl -s -A "SophiaQuizContentBuilder/1.0 (educational quiz app)" "https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srsearch=<terms>&format=json"`
   and `…&prop=imageinfo&iiprop=extmetadata&titles=File:<name>` for the licence. Be gentle (no
   more than ~1 request per second).
2. Write your manifest `content/duels/v5/images_<NAME>.json`:
   `{"<key>": {"file": "<exact Commons file name without File:>", "fit": "contain" | "cover", "focus": "top" | "center", "crop": [l,t,r,b] (optional, fractions 0–1, applied before cover), "name": "<Title, artist, date>"}}`
   - paintings, drawings, prints, maps: `"fit": "contain"` (shown whole on a blurred background);
   - portraits: `"fit": "cover", "focus": "top"` (face visible); monuments/landscapes/animals: `cover`
     (+ `crop` if the subject is off-centre);
   - flags: key `"flags/<iso2 code lower-case>"` with `{"flag": true, "name": "<country>"}`.
   Keys: lower-case snake_case, prefixed with your prefix (given in your task).
3. Run `python3 scripts/duels_v5_images.py <NAME>` (downloads, checks licence, writes the 640×800
   file under content/duels/v5/upload/duels/images|flags/). Fix every ERREUR (pick another file).
4. **Look at every output image** with the Read tool. The subject must be clearly visible and
   recognisable in the frame, nothing important cut off, no text in the image that gives the
   answer (a signature, a caption, a name plate). Adjust fit/focus/crop and re-run for that key
   (`python3 scripts/duels_v5_images.py <NAME> <key>`; delete content/duels/v5/images_raw/<key>.jpg
   first if you changed the file).
5. Write the questions to `content/duels/v5/draft_images_<NAME>.json` (JSON array, one per line):
   `{"level": 4, "kind": "image", "subject": "art", "question": "Who painted this?", "image": "<key>", "options": ["CORRECT", "wrong", "wrong", "wrong"]}`
   Flags: `"image": "flags/np"`. One question per image. Subject = the subject of the content
   (history, science, literature, art, mythology, world). The question must need the picture.
   Vary the questions ("Which city is this?", "Which animal is this?", "Which planet is this?",
   "Which hero is shown here?", "What is this instrument called?", "Who is this scientist?",
   "Which civilisation made this?"…). Spread levels 1–8. Distractors certainly wrong, plausible,
   parallel. First option = correct.
