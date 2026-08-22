# Tradução de cursos — francês para português

O francês (`content/courses/fr/`) é a fonte. Este documento é a
especificação de `content/courses/pt/`. Vai intacto para quem escreve a
tradução, e o `scripts/check_course_translation.py --lang pt` aplica as
regras de forma mecânica.

As mesmas regras valem para as outras línguas; só mudam números, aspas e
nomes próprios.

## 1. O que queremos

Não entregamos uma tradução. Entregamos a **edição brasileira** do curso:
o texto que um redator nativo teria escrito a partir das mesmas notas. O
leitor não pode perceber que o original era francês.

Nesta ordem:

1. **Correto.** Sem distorcer, inventar ou omitir fatos.
2. **Fluente.** Português idiomático. Dá para ler em voz alta sem tropeçar.
3. **Simples.** Frases curtas. Palavras comuns. Um adolescente curioso
   precisa acompanhar. Prefira "mostrou" a "demonstrou", "usou" a
   "utilizou".
4. **Fiel à forma.** Quase o mesmo número de frases, a mesma ordem das
   ideias, o mesmo comprimento com 20 por cento de folga, para o layout
   aguentar.

Registro: **português brasileiro padrão**. Sem europeísmo (`facto`,
`acção`, `telemóvel`, `autocarro`). Sem sotaque regional escrito. Tratamento
informal em **você**, nunca o *tu* ou o *vós* europeus. Ortografia do
Acordo de 1990: `ideia`, `assembleia`, `veem`, `voo`.

Reconstrua as frases à vontade. O francês encadeia períodos longos com
ponto e vírgula e narra no presente; o texto didático brasileiro prefere o
pretérito para história, salvo quando o francês usa o presente de propósito,
curto, como efeito.

## 2. A estrutura fica de pé

Só os campos de texto se traduzem. Todo o resto o ferramenta copia do
esqueleto francês e não se mexe: `id`, `subject`, `subcategory`, `type`,
`asset`, `image`, `ratio`, `free`.

| Campo | O que é | Nota |
| --- | --- | --- |
| `title` | Título no cartão e no hero | Curto. Título canônico da obra publicada no Brasil, se o curso trata de uma obra. |
| `subtitle` | Linha sob o título | Um ano ou intervalo (`1945`, `1945-1975`) fica igual. |
| `description` | Blurb de duas frases | Precisa se sustentar sozinho. |
| `hero.hook` | Uma frase isca | Publicidade, não prosa. |
| `sections[].title` | Título de seção | Sintagma nominal, sem ponto final. |
| `paragraph.text` | Texto corrido | O grosso do trabalho. |
| `image.caption` | Legenda | Uma cláusula; ponto só se for frase completa. |
| `funFact.text` | Box | Leve, falado. |
| `takeaway.text` | Fecho | O que precisa ficar. |
| `quote.text` | Citação | Ver §6. |
| `quote.attribution` | Quem disse | Ver §6. |
| `timeline.events[].date` | `1789`, `junho de 1940`, `por volta de 450 a.C.` | Números ficam. Meses se traduzem. `a.C.` / `d.C.`, nunca `av. J.-C.`. |
| `timeline.events[].title` | Rótulo | Muito curto, sem ponto. |
| `timeline.events[].detail` | Uma frase | |

## 3. Marcação inline

Três marcas têm de sobreviver:

- `**negrito**` — datas, números, nomes das pessoas e obras de que o
  parágrafo trata.
- `*itálico*` — título de obra dentro da prosa.
- `[[termo]]` — entrada de glossário. Um toque abre a definição.

Regras:

- As marcas vêm em pares. Número ímpar de `**` é erro.
- Nenhuma marca envolve espaço ou pontuação: `**1945**,` está certo,
  `**1945,**` e `** 1945 **` estão errados.
- O negrito marca o equivalente português, não os mesmos caracteres.
  Francês `**30 000 mots**` vira `**30.000 palavras**`.
- Sem negrito que o francês não tenha. Sem frase inteira em negrito.

## 4. Termos de glossário — a regra mais importante

Cada `[[...]]` francês vira exatamente um `[[...]]` português, **na frase,
no mesmo lugar do argumento**.

Nunca jogue o termo no fim do parágrafo. Nunca deixe o buraco aberto.
Este é o mesmo erro:

> Errado: `enfraquecida sobretudo por : cruzados cristãos saquearam a cidade. [[O saque de Constantinopla]]`
>
> Certo: `enfraquecida sobretudo por [[o saque de Constantinopla durante a Quarta Cruzada (1204)]], quando cruzados cristãos ocidentais saquearam a cidade.`

O texto do termo não é livre. Tem de ser uma chave registrada para aquele
curso em `ios/Sophia/Resources/Locales/glossary.pt.json`. Uma chave
desconhecida aparece como texto morto. O brief de
`scripts/make_translation_briefs.py` lista as chaves permitidas; use uma
delas caractere por caractere, inclusive maiúsculas.

A frase precisa ficar gramatical **com o termo encaixado**:

- A chave muitas vezes já traz o artigo: `[[A umma]]`, `[[A alegoria da
  Revolução Russa]]`. Então `Ele fundou [[A umma]]`, nunca `Ele fundou a
  [[A umma]]`.
- Se a chave não tem artigo, o artigo fica fora: `um gesto
  [[abolicionista]]`, `uma [[oreade]]`. Gênero e número têm de combinar
  com a chave.
- Nunca ponha `o` / `a` diante de um nome próprio que não leva artigo, se
  a chave também não leva. `durante a [[Segunda Guerra Mundial]]` (a chave
  é `Segunda Guerra Mundial`) ou `enquanto [[Segunda Guerra Mundial]]
  ainda durava`, conforme a chave. Nunca `durante o [[Segunda Guerra
  Mundial]]`.
- Não flexione por cima do colchete: `[[proletariado]]s` está errado.
  Reescreva.
- Se a chave não cabe, reconstrua a frase. Não mude a chave.

## 5. Nomes próprios

A tradução automática lê nomes como substantivos comuns. Regras duras:

**Nunca traduza um nome de pessoa.** Degas continua Degas, não "Desgaseificar".
Corneille continua Corneille, não "Corneja". Le Corbusier continua Le
Corbusier.

**A forma estabelecida em português**, quando existe:
`Christophe Colomb` → `Cristóvão Colombo`, `Guillaume le Conquérant` →
`Guilherme, o Conquistador`, `Londres` → `Londres`, `Pékin` → `Pequim`,
`Aix-la-Chapelle` → `Aquisgrano`.

**Títulos de obras levam o título publicado no Brasil**, não um calque
literal:

| Francês | Português |
| --- | --- |
| *Impression, soleil levant* | *Impressão, nascer do sol* |
| *La Ferme des animaux* | *A Revolução dos Bichos* |
| *Le Rouge et le Noir* | *O Vermelho e o Negro* |
| *À la recherche du temps perdu* | *Em Busca do Tempo Perdido* |
| *Le Déjeuner sur l'herbe* | *O Almoço sobre a Relva* |
| *Les Demoiselles d'Avignon* | *Les Demoiselles d'Avignon* (fica) |
| *Les Fleurs du Mal* | *As Flores do Mal* |
| *Les Misérables* | *Os Miseráveis* |
| *Le Petit Prince* | *O Pequeno Príncipe* |
| *L'Étranger* | *O Estrangeiro* |
| *Le Mythe de Sisyphe* | *O Mito de Sísifo* |
| *Le Père Goriot* | *Pai Goriot* |

Se não houver título fixo em português, mantenha o original e glossarie
entre parênteses na primeira menção.

**Personagens da literatura traduzida levam o nome da edição brasileira
padrão**:

| Obra | Francês | Português |
| --- | --- | --- |
| *A Revolução dos Bichos* | Malabar | Sansão |
| *A Revolução dos Bichos* | Brille-Babil | Garganta |
| *A Revolução dos Bichos* | Boule de neige | Bola de Neve |
| *A Revolução dos Bichos* | Vieux Major | Velho Major |
| *O Pequeno Príncipe* | Bésixdouze | asteroide B-612 |
| *1984* | novlangue | novilíngua |
| *1984* | doublepensée | duplipensar |

O registro fica em `scripts/proper_nouns.json`. Acrescente lá, não
conserte o mesmo nome duas vezes.

## 6. Citações

Uma citação não é exercício de tradução. Se existe um enunciado canônico
publicado em português, use-o. Senão, traduza curto e claro.

- Aspas curvas `“ ”`. Sem aspas francesas `« »`.
- O ponto final da frase citada fica dentro da aspa de fecho:
  `“Todos os animais são iguais.”`
- `quote.attribution` é `Autor, Obra`. Se o francês põe um falante depois
  de um travessão, vírgula ou parêntese:
  `Victor Hugo, Os Miseráveis (Monsenhor Bienvenu)`.

## 7. Pontuação e tipografia

Checagem mecânica, sem exceção.

- **Sem travessão `—`, sem meio-travessão `–`.** Reescreva com vírgula,
  dois-pontos, parêntese ou ponto. Intervalos numéricos com hífen:
  `1945-1975`.
- Sem aspas francesas `« »`, sem caracteres de largura zero, sem espaço
  inseparável.
- O apóstrofo é o reto `'` (U+0027), como nos arquivos franceses.
  Não `’`.
- Nunca um espaço antes de `, . ; : ! ?`. Nunca dois espaços seguidos.
- Um espaço depois de dois-pontos ou ponto e vírgula, e os dois com
  parcimônia: a prosa didática brasileira prefere o ponto.
- Sem resto francês. `siècle`, `dans`, `qui`, `l'`, `d'un` num parágrafo
  português é erro, e também um topônimo francês sem traduzir no meio de
  uma frase portuguesa.

## 8. Números, datas, unidades

- Milhares: ponto. `30 000` → `30.000`. Nunca espaço, nunca vírgula.
- Decimal: vírgula. `3,5 %` → `3,5%`. Sem espaço antes de `%`.
- Séculos em algarismos romanos depois da palavra: `XVe siècle` →
  `século XV`. Nunca `XVe` solto, nunca `15. século`.
- Eras: `a.C.` e `d.C.`: `450 a.C.`, `622 d.C.`.
- Datas: `24 de fevereiro de 2022`. Um esquema por curso.
- Nada de converter. Métrico continua métrico.
- `Mds`/`Md` → `bilhões`. `M` → `milhões`, por extenso.

## 9. Conferência

```bash
python scripts/check_course_translation.py --lang pt
python scripts/check_course_translation.py --lang pt course_102_*
```

O validador aponta, por curso: deriva de estrutura, marcas desemparelhadas,
contagem de glossário, chaves não registradas, termos jogados no fim do
parágrafo, artigo duplo, caracteres proibidos, espaçamento, restos
franceses e números sem localizar. Uma passagem limpa é obrigação, não
sugestão.
