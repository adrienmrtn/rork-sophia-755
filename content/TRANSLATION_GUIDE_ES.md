# Guía de traducción de cursos — del francés al español

El francés (`content/courses/fr/`) es la fuente. Este documento es la
especificación para producir `content/courses/es/`. Se entrega tal cual a
quien (persona o modelo) redacte la traducción, y es lo que
`scripts/check_course_translation.py --lang es` comprueba de forma mecánica.

Las mismas reglas valen para las otras lenguas; solo cambian las secciones
de números, comillas y nombres propios.

## 1. Qué buscamos

No estamos produciendo una traducción. Estamos produciendo la **edición
española** del curso: el texto que un redactor nativo habría escrito a
partir de las mismas notas. El lector no debe poder adivinar que el
original era francés.

Por orden de prioridad:

1. **Correcto.** Sin desviación factual, sin inventar, sin omitir.
2. **Fluido.** Español idiomático. Se lee en voz alta sin tropiezos.
3. **Simple.** Frases cortas. Palabras comunes. Un adolescente curioso
   debe seguirlo. Prefiere "mostró" a "evidenció", "usó" a "utilizó".
4. **Fiel en la forma.** El mismo número de frases más o menos una, el
   mismo orden de ideas, la misma longitud con un margen de un 20%, para
   que el diseño de la app se mantenga.

El registro es **español internacional** (el de una app leída en España y
en América): `computadora` o `ordenador` según el contexto científico,
nunca `vosotros` ni voseo, nunca localismos (`coche`/`carro` se evitan
cuando se puede decir `auto` o reformular). Ortografía RAE: tildes,
`solo` sin tilde adverbial, `guion` sin tilde.

Reescribe con libertad a nivel de frase. El francés encadena oraciones
largas con punto y coma y narra en presente; el español de divulgación
prefiere el pretérito para la narración histórica, salvo cuando el
francés usa el presente a propósito, en un pasaje corto, por efecto.

## 2. La estructura está congelada

Solo se traducen los campos de texto. Todo lo demás lo copia la
herramienta a partir del esqueleto francés y no se toca: `id`, `subject`,
`subcategory`, `type`, `asset`, `image`, `ratio`, `free`.

| Campo | Qué es | Notas |
| --- | --- | --- |
| `title` | título de la ficha y del héroe | Corto. Título canónico de la obra en español cuando el curso trata de una. |
| `subtitle` | línea bajo el título | Un año o un intervalo (`1945`, `1945-1975`) se copia tal cual. |
| `description` | blurb de dos frases | Debe valer por sí solo. |
| `hero.hook` | una frase de gancho | Es copy, no prosa. |
| `sections[].title` | titular de sección | Sintagma nominal, sin punto final. |
| `paragraph.text` | el cuerpo | Lo esencial del trabajo. |
| `image.caption` | pie de foto | Una cláusula, sin punto salvo que sea una frase completa. |
| `funFact.text` | recuadro | Ligero, conversacional. |
| `takeaway.text` | cierre | Lo que hay que recordar. |
| `quote.text` | cita | Ver §6. |
| `quote.attribution` | quién lo dijo | Ver §6. |
| `timeline.events[].date` | `1789`, `junio de 1940`, `c. 450 a. C.` | Los números se quedan. Se traducen los meses. `a. C.` / `d. C.`, nunca `av. J.-C.`. |
| `timeline.events[].title` | etiqueta | Muy corta, sin punto. |
| `timeline.events[].detail` | una frase | |

## 3. Marcado interno

Tres marcas deben sobrevivir:

- `**negrita**` — fechas, cifras, nombres de las personas y las obras de
  las que habla el párrafo.
- `*cursiva*` — títulos de obras citados en la prosa.
- `[[Término]]` — entrada de glosario. Al tocarla se abre la definición.

Reglas:

- Las marcas van equilibradas. Un número impar de `**` es un error.
- Ninguna marca envuelve espacio o puntuación: `**1945**,` está bien,
  `**1945,**` y `** 1945 **` no.
- Se pone en negrita el equivalente español de lo que el francés
  enfatizó, no los mismos caracteres. Si el francés marca
  `**30 000 mots**`, el español marca `**30.000 palabras**`.
- No se añade negrita que no esté en el francés. No se marca una frase
  entera.

## 4. Términos de glosario — la regla más importante

Cada `[[...]]` del francés produce exactamente un `[[...]]` en español,
**dentro de la frase, en el mismo lugar del argumento**.

Nunca se aparca un término al final del párrafo. Nunca se deja el hueco
que ocupaba. Son el mismo fallo:

> Mal: `debilitado sobre todo por : los cruzados cristianos saquearon la ciudad. [[El saqueo de Constantinopla]]`
>
> Bien: `debilitado sobre todo por [[el saqueo de Constantinopla durante la Cuarta Cruzada (1204)]], cuando los cruzados cristianos de Occidente saquearon la ciudad.`

El texto del término no es libre. Debe ser una de las claves registradas
para ese curso en `ios/Sophia/Resources/Locales/glossary.es.json`. Una
clave que no exista se renderiza como texto plano, sin subrayado. El
brief de `scripts/make_translation_briefs.py` lista las claves
permitidas; se usa una de ellas carácter por carácter, mayúsculas
incluidas.

La frase debe ser gramatical **con el término ya insertado**:

- La clave a menudo lleva su artículo: `[[La umma]]`, `[[La alegoría de
  la Revolución rusa]]`. Entonces se escribe `Fundó [[La umma]]`, nunca
  `Fundó la [[La umma]]`.
- Si la clave no lleva artículo, se pone fuera de los corchetes el que
  corresponda: `un gesto [[abolicionista]]`, `una [[oréade]]`.
- Nunca `el` delante de un nombre propio que no lo lleva:
  `durante [[la Segunda Guerra Mundial]]` si la clave ya incluye el
  artículo; `durante la [[Segunda Guerra Mundial]]` si no lo incluye.
  Nunca `durante el [[Segunda Guerra Mundial]]`.
- No se pluraliza ni se posesiviza a través del corchete:
  `[[proletariado]]s` está mal. Se reformula.
- Si la clave no cabe de forma natural, se reestructura la frase. No se
  cambia la clave.

## 5. Nombres propios

La traducción automática destroza los nombres. Reglas duras:

**Nunca se traduce un nombre de persona.** Degas es Degas, no "Desgas".
Corneille es Corneille, no "Cuervo". Le Corbusier es Le Corbusier.

**Se usa la forma española establecida** cuando existe:
`Christophe Colomb` → `Cristóbal Colón`, `Guillaume le Conquérant` →
`Guillermo el Conquistador`, `Londres` → `Londres`, `Pékin` → `Pekín`,
`Aix-la-Chapelle` → `Aquisgrán`.

**Los títulos de obras llevan su título publicado en español**, no un
calco:

| Francés | Español |
| --- | --- |
| *Impression, soleil levant* | *Impresión, sol naciente* |
| *La Ferme des animaux* | *Rebelión en la granja* |
| *Le Rouge et le Noir* | *Rojo y negro* |
| *À la recherche du temps perdu* | *En busca del tiempo perdido* |
| *Le Déjeuner sur l'herbe* | *El almuerzo campestre* |
| *Les Demoiselles d'Avignon* | *Las señoritas de Aviñón* |
| *Les Fleurs du Mal* | *Las flores del mal* |
| *Les Misérables* | *Los miserables* |
| *Le Petit Prince* | *El principito* |

Si una obra no tiene título español asentado, se deja el original y se
glosa una vez, entre paréntesis, en la primera mención.

**Los personajes de la literatura traducida llevan el nombre de la
edición española de referencia**:

| Obra | Francés | Español |
| --- | --- | --- |
| *Rebelión en la granja* | Malabar | Bóxer |
| *Rebelión en la granja* | Brille-Babil | Gruñón |
| *Rebelión en la granja* | Boule de neige | Bola de Nieve |
| *Rebelión en la granja* | Vieux Major | el Mayor |
| *El principito* | Bésixdouze | asteroide B-612 |
| *1984* | novlangue | neolengua |
| *1984* | doublepensée | doblepensar |

El registro automático está en `scripts/proper_nouns.json`. Se añade ahí
en vez de corregir el mismo nombre dos veces.

## 6. Citas

Una cita no se traduce a ojo. Si existe un texto canónico en español, se
usa. Si no, se traduce en claro y corto.

- Comillas curvas `“ ”`. Nunca guillemets franceses `« »`.
- La puntuación de una frase completa va dentro de la comilla de cierre:
  `“Todos los animales son iguales.”`
- `quote.attribution` es `Autor, Obra`. Si el francés añade un hablante
  detrás de un rayo, se usa una coma o un paréntesis:
  `Victor Hugo, Los miserables (monseñor Bienvenu)`.

## 7. Puntuación y tipografía

Se comprueban de forma mecánica y no hay excepción.

- **Ningún raya `—` ni semirraya `–`.** Se reformula con coma, dos
  puntos, paréntesis o punto. Un intervalo numérico lleva un guion
  simple: `1945-1975`.
- Sin guillemets `« »`, sin espacios de ancho cero, sin espacios
  inseparables.
- El apóstrofo es el recto `'` (U+0027), como en los ficheros franceses.
  No `’`.
- Nunca un espacio antes de `, . ; : ! ?`. Nunca dos espacios seguidos.
- Un espacio después de dos puntos o punto y coma, y se usan poco: el
  español de divulgación prefiere el punto.
- Ninguna palabra francesa suelta. `siècle`, `dans`, `qui`, `l'`,
  `d'un` en un párrafo español son un defecto, y también lo es un
  topónimo francés dejado sin traducir dentro de una frase española.

## 8. Números, fechas y unidades

- Separador de miles: un punto. `30 000` → `30.000`. Nunca un espacio,
  nunca una coma.
- Separador decimal: una coma. `3,5 %` → `3,5%`. Sin espacio antes de
  `%`.
- Los siglos van en romano detrás de la palabra: `XVe siècle` →
  `siglo XV`.
- Las eras son `a. C.` y `d. C.`: `450 a. C.`, `622 d. C.`.
- Las fechas se leen `24 de febrero de 2022`. Un criterio por curso.
- No se convierte nada. Lo métrico se queda métrico.
- `Mds`/`Md` → `mil millones`. `M` → `millones`, escrito.

## 9. Cómo comprobar

```bash
python scripts/check_course_translation.py --lang es
python scripts/check_course_translation.py --lang es course_102_*
```

Informa, por curso: deriva estructural, marcas desequilibradas, recuento
de glosario, claves no registradas, términos aparcados al final, artículos
dobles, caracteres prohibidos, espacios, restos franceses y números no
localizados. Una pasada limpia es un requisito, no una sugerencia.
