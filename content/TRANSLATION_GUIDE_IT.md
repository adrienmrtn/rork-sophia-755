# Traduzione dei corsi — dal francese all'italiano

Il francese (`content/courses/fr/`) è la fonte. Questo documento è la
specifica di `content/courses/it/`. Va integro a chi scrive la
traduzione, e `scripts/check_course_translation.py --lang it` applica
le regole in modo meccanico.

Le stesse regole valgono per le altre lingue; cambiano solo numeri,
virgolette e nomi propri.

## 1. Cosa vogliamo

Non consegniamo una traduzione. Consegniamo l'**edizione italiana** del
corso: il testo che un redattore madrelingua avrebbe scritto dalle
stesse note. Il lettore non deve accorgersi che l'originale era francese.

In quest'ordine:

1. **Corretto.** Senza distorcere, inventare o omettere fatti.
2. **Fluido.** Italiano idiomatico. Si legge a voce alta senza inciampare.
3. **Semplice.** Frasi corte. Parole comuni. Un adolescente curioso deve
   stare dietro. Meglio "mostrò" che "dimostrò", "usò" che "utilizzò".
4. **Fedele alla forma.** Quasi lo stesso numero di frasi, lo stesso
   ordine delle idee, la stessa lunghezza con il 20 per cento di
   margine, perché il layout regga.

Registro: **italiano standard**. Niente dialetto, niente burocratese,
niente periodi a incastro. Trattamento informale in **tu**, non il *Lei*
da saggio. Ortografia dell'italiano contemporaneo: accenti giusti
(`è`, `perché`, `più`), apostrofo dattilografico `'` (mai `’`).

Ricostruisci le frasi a piacere. Il francese incatena periodi lunghi
con il punto e virgola e racconta al presente; la saggistica italiana
per ragazzi preferisce il passato remoto o il passato prossimo per la
storia, salvo quando il francese usa il presente di proposito, corto,
come effetto.

## 2. La struttura resta in piedi

Si traducono solo i campi di testo. Tutto il resto lo strumento copia
dallo scheletro francese e non si tocca: `id`, `subject`, `subcategory`,
`type`, `asset`, `image`, `ratio`, `free`.

| Campo | Che cos'è | Nota |
| --- | --- | --- |
| `title` | Titolo su scheda e hero | Corto. Titolo canonico dell'opera pubblicata in Italia, se il corso parla di un'opera. |
| `subtitle` | Riga sotto il titolo | Un anno o un intervallo (`1945`, `1945-1975`) resta uguale. |
| `description` | Blurb di due frasi | Deve reggersi da solo. |
| `hero.hook` | Una frase esca | Pubblicità, non prosa. |
| `sections[].title` | Titolo di sezione | Sintagma nominale, senza punto finale. |
| `paragraph.text` | Testo continuo | Il grosso del lavoro. |
| `image.caption` | Didascalia | Una clausola; punto solo se è frase intera. |
| `funFact.text` | Box | Leggero, parlato. |
| `takeaway.text` | Chiusura | Quello che deve restare. |
| `quote.text` | Citazione | Vedi §6. |
| `quote.attribution` | Chi l'ha detto | Vedi §6. |
| `timeline.events[].date` | `1789`, `giugno 1940`, `intorno al 450 a.C.` | I numeri restano. I mesi si traducono. `a.C.` / `d.C.`, mai `av. J.-C.`. |
| `timeline.events[].title` | Etichetta | Cortissima, senza punto. |
| `timeline.events[].detail` | Una frase | |

## 3. Marcatura inline

Tre marche devono sopravvivere:

- `**grassetto**` — date, numeri, nomi delle persone e delle opere di
  cui parla il paragrafo.
- `*corsivo*` — titolo d'opera nella prosa.
- `[[termine]]` — voce di glossario. Un tocco apre la definizione.

Regole:

- Le marche vanno a coppie. Un numero dispari di `**` è un errore.
- Nessuna marca avvolge spazio o punteggiatura: `**1945**,` è giusto,
  `**1945,**` e `** 1945 **` sono sbagliati.
- Il grassetto marca l'equivalente italiano, non gli stessi caratteri.
  Francese `**30 000 mots**` diventa `**30.000 parole**`.
- Niente grassetto che il francese non abbia. Niente frase intera in
  grassetto.

## 4. Termini di glossario — la regola più importante

Ogni `[[...]]` francese diventa esattamente un `[[...]]` italiano,
**nella frase, nello stesso punto dell'argomento**.

Mai parcheggiare il termine in fondo al paragrafo. Mai lasciare il
buco aperto. È lo stesso errore:

> Sbagliato: `indebolita soprattutto da : i crociati cristiani
> saccheggiarono la città. [[Il sacco di Costantinopoli]]`
>
> Giusto: `indebolita soprattutto da [[il sacco di Costantinopoli
> durante la Quarta crociata (1204)]], quando i crociati cristiani
> occidentali saccheggiarono la città.`

Il testo del termine non è libero. Deve essere una chiave registrata
per quel corso in `ios/Sophia/Resources/Locales/glossary.it.json`. Una
chiave sconosciuta compare come testo morto. Il brief di
`scripts/make_translation_briefs.py` elenca le chiavi ammesse; usane
una carattere per carattere, maiuscole comprese.

La frase deve restare grammaticale **col termine innestato**:

- La chiave spesso porta già l'articolo: `[[La umma]]`, `[[L'allegoria
  della Rivoluzione russa]]`. Allora `Fondò [[La umma]]`, mai `Fondò
  la [[La umma]]`.
- Se la chiave non ha articolo, l'articolo sta fuori: `un gesto
  [[abolizionista]]`, `una [[oreade]]`. Genere e numero devono
  combinare con la chiave.
- Mai mettere `il` / `la` davanti a un nome proprio che non prende
  articolo, se la chiave non lo porta. `durante la [[Seconda guerra
  mondiale]]` (la chiave è `Seconda guerra mondiale`) o `mentre
  [[Seconda guerra mondiale]] era ancora in corso`, a seconda della
  chiave. Mai `durante lo [[Seconda guerra mondiale]]`.
- Non flettere sopra la parentesi: `[[proletariato]]s` è sbagliato.
  Riscrivi.
- Se la chiave non ci sta, ricostruisci la frase. Non cambiare la
  chiave.

## 5. Nomi propri

La traduzione automatica legge i nomi come nomi comuni. Regole dure:

**Non tradurre mai un nome di persona.** Degas resta Degas, non
"Disgasare". Corneille resta Corneille, non "Cornacchia". Le Corbusier
resta Le Corbusier.

**La forma italiana consolidata**, quando esiste:
`Christophe Colomb` → `Cristoforo Colombo`, `Guillaume le Conquérant`
→ `Guglielmo il Conquistatore`, `Londres` → `Londra`, `Pékin` →
`Pechino`, `Aix-la-Chapelle` → `Aquisgrana`.

**I titoli d'opera portano il titolo pubblicato in Italia**, non un
calco letterale:

| Francese | Italiano |
| --- | --- |
| *Impression, soleil levant* | *Impressione, levar del sole* |
| *La Ferme des animaux* | *La fattoria degli animali* |
| *Le Rouge et le Noir* | *Il rosso e il nero* |
| *À la recherche du temps perdu* | *Alla ricerca del tempo perduto* |
| *Le Déjeuner sur l'herbe* | *Colazione sull'erba* |
| *Les Demoiselles d'Avignon* | *Les Demoiselles d'Avignon* (resta) |
| *Les Fleurs du Mal* | *I fiori del male* |
| *Les Misérables* | *I Miserabili* |
| *Le Petit Prince* | *Il piccolo principe* |
| *L'Étranger* | *Lo straniero* |
| *Le Mythe de Sisyphe* | *Il mito di Sisifo* |
| *Le Père Goriot* | *Papà Goriot* |

Se non c'è un titolo fisso in italiano, tieni l'originale e glossalo
tra parentesi alla prima menzione.

**I personaggi della letteratura tradotta portano il nome
dell'edizione italiana standard**:

| Opera | Francese | Italiano |
| --- | --- | --- |
| *La fattoria degli animali* | Malabar | Gondrano |
| *La fattoria degli animali* | Brille-Babil | Clarinetto |
| *La fattoria degli animali* | Boule de neige | Palla di Neve |
| *La fattoria degli animali* | Vieux Major | Vecchio Maggiore |
| *Il piccolo principe* | Bésixdouze | asteroide B-612 |
| *1984* | novlangue | neolingua |
| *1984* | doublepensée | bispensiero |

Il registro sta in `scripts/proper_nouns.json`. Aggiungi lì, non
riparare lo stesso nome due volte.

## 6. Citazioni

Una citazione non è un esercizio di traduzione. Se esiste un enunciato
canonico pubblicato in italiano, usa quello. Altrimenti traduci corto
e chiaro.

- Virgolette curve `“ ”`. Niente caporali francesi `« »`.
- Il punto della frase citata sta dentro la virgoletta di chiusura:
  `“Tutti gli animali sono uguali.”`
- `quote.attribution` è `Autore, Opera`. Se il francese mette un
  parlante dopo un trattino, virgola o parentesi:
  `Victor Hugo, I Miserabili (monsignor Bienvenu)`.

## 7. Punteggiatura e tipografia

Controllo meccanico, senza eccezioni.

- **Niente lineetta `—`, niente semilineetta `–`.** Riscrivi con
  virgola, due punti, parentesi o punto. Intervalli numerici con
  trattino: `1945-1975`.
- Niente caporali `« »`, niente caratteri a larghezza zero, niente
  spazio inseparabile.
- L'apostrofo è il dritto `'` (U+0027), come nei file francesi.
  Non `’`.
- Mai uno spazio prima di `, . ; : ! ?`. Mai due spazi di seguito.
- Uno spazio dopo i due punti o il punto e virgola, e tutti e due
  con parsimonia: la prosa didattica italiana preferisce il punto.
- Niente resto francese. `siècle`, `dans`, `l'`, `d'un` in un
  paragrafo italiano è un errore, e anche un toponimo francese non
  tradotto in mezzo a una frase italiana.

## 8. Numeri, date, unità

- Migliaia: punto. `30 000` → `30.000`. Mai spazio, mai virgola.
- Decimale: virgola. `3,5 %` → `3,5%`. Niente spazio prima di `%`.
- Secoli con numerali romani dopo la parola: `XVe siècle` →
  `secolo XV`. Mai `XVe` da solo, mai `15. secolo`.
- Ere: `a.C.` e `d.C.`: `450 a.C.`, `622 d.C.`.
- Date: `24 febbraio 2022`. Uno schema per corso.
- Niente conversioni. Il metrico resta metrico.
- `Mds`/`Md` → `miliardi`. `M` → `milioni`, per esteso.

## 9. Controllo

```bash
python scripts/check_course_translation.py --lang it
python scripts/check_course_translation.py --lang it course_102_*
```

Il validatore segnala, per corso: deriva di struttura, marche
scompaiate, conteggio del glossario, chiavi non registrate, termini
parcheggiati in fondo al paragrafo, articolo doppio, caratteri
proibiti, spaziatura, resti francesi e numeri non localizzati. Un
passaggio pulito è un obbligo, non un suggerimento.
