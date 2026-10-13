# Edição portuguesa (Portugal) — `pt-PT`

O português sai em duas edições:

- `pt` — **português do Brasil**, especificado em `TRANSLATION_GUIDE_PT.md`.
- `pt-PT` — **português de Portugal**, este documento.

A edição portuguesa não se traduz do francês: **adapta-se da edição
brasileira**, frase a frase, mudando só o que a variante exige. Mesmo número de
frases, mesma ordem das ideias, mesmos factos, mesma marcação. Tudo o que o
guia brasileiro diz sobre estrutura, marcação (`**negrito**`, `*itálico*`,
`[[termo]]`), nomes próprios, números e pontuação vale aqui, com as diferenças
abaixo. O `scripts/check_course_translation.py --lang pt-PT` aplica as regras
mecânicas.

## 1. Registo

Português europeu padrão, Acordo Ortográfico de 1990 tal como se aplica em
Portugal: o texto que uma boa editora de divulgação científica de Lisboa
publicaria. Um leitor português não pode perceber que existiu uma edição
brasileira.

- Trata-se o leitor por **tu**: `Sabias que…?`, `o teu curso`, `Toca aqui`.
  Nunca `você`.
- Ação em curso: **estar a + infinitivo** (`estava a lutar`, `continua a
  crescer`). Nunca o gerúndio progressivo brasileiro.
- Pronome átono depois do verbo nas orações afirmativas (`tornou-se rei`,
  `a cidade rendeu-se`); antes do verbo depois de negação, de `que`, de
  conjunções subordinativas, de advérbios como `já`, `ainda`, `também`, `só`,
  `sempre` e de quantificadores (`não se rendeu`, `já se sabia`).
- Artigo antes do possessivo: `a sua obra`, `o teu progresso`.
- `Porque é que…?` / `porquê?`, nunca `Por que…?` no sentido de *why*.

## 2. Ortografia e vocabulário

| Brasil | Portugal |
| --- | --- |
| econômico, fenômeno, gênero, prêmio, Antônio | económico, fenómeno, género, prémio, António |
| fato, contato, recepção, aspecto, perspectiva | facto, contacto, receção, aspeto, perspetiva |
| registro, planejamento, cotidiano | registo, planeamento, quotidiano |
| dezesseis, dezessete, dezenove | dezasseis, dezassete, dezanove |
| tela (ecrã), celular, ônibus, trem, equipe | ecrã, telemóvel, autocarro, comboio, equipa |
| usuário, arquivo, baixar, salvar, assinatura | utilizador, ficheiro, descarregar, guardar, subscrição |
| esporte, pesquisador | desporto, investigador |
| Irã, Vietnã, Moscou, Nova York, Islã, Iugoslávia | Irão, Vietname, Moscovo, Nova Iorque, Islão, Jugoslávia |
| Stalin, Lenin | Estaline, Lenine |
| Papai Noel, Superman | Pai Natal, Super-Homem |

`tela` continua a ser a tela do pintor.

**Números grandes.** `mil milhões` = 10⁹ e `bilião` = 10¹². O brasileiro
`13,8 bilhões` passa a `13,8 mil milhões`; `10 trilhões` passa a `10 biliões`.

## 3. Títulos de obras

Título da edição portuguesa quando difere do brasileiro:

| Brasil | Portugal |
| --- | --- |
| *A Revolução dos Bichos* | *O Triunfo dos Porcos* |
| *O Pequeno Príncipe* | *O Principezinho* |
| *O Sol é para Todos* | *Mataram a Cotovia* |
| *Pai Goriot* | *O Pai Goriot* |
| *Cidadão Kane* | *O Mundo a Seus Pés* |
| *2001: Uma Odisseia no Espaço* | *2001: Odisseia no Espaço* |

## 4. Citações

Aspas angulares `« »`, como é norma em Portugal. O ponto final da frase
citada fica dentro da aspa de fecho: `«Todos os animais são iguais.»`

## 5. Glossário

O texto dentro de `[[…]]` adapta-se como o resto (`[[fenómeno]]`), e a chave
do glossário `glossary.pt-PT.json` tem de ser exatamente esse texto. Quando se
muda um termo no curso, muda-se a chave.
