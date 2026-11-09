import type { ReactNode } from "react";

/** Les marques du texte d'un cours : `**gras**`, `*italique*`, `[[terme du glossaire]]`. */
const TOKEN = /(\*\*[^*]+\*\*|\*[^*\n]+\*|\[\[[^\]]+\]\])/g;

export function plainText(text: string): string {
  return text.replace(/\*\*/g, "").replace(/\*/g, "").replace(/\[\[|\]\]/g, "");
}

export function countWords(text: string): number {
  return plainText(text)
    .split(/\s+/)
    .filter((w) => /[\p{L}\p{N}]/u.test(w)).length;
}

/** Rend une ligne de cours en React, avec un lien vers l'entrée du glossaire pour chaque `[[terme]]`. */
export function renderInline(text: string, glossaryHref?: (term: string) => string): ReactNode[] {
  const out: ReactNode[] = [];
  let last = 0;
  let key = 0;
  for (const m of text.matchAll(TOKEN)) {
    const index = m.index ?? 0;
    if (index > last) out.push(text.slice(last, index));
    const tok = m[0];
    if (tok.startsWith("**")) out.push(<strong key={key++}>{renderInline(tok.slice(2, -2), glossaryHref)}</strong>);
    else if (tok.startsWith("[[")) {
      const term = tok.slice(2, -2).trim();
      out.push(
        glossaryHref ? (
          <a key={key++} className="term" href={glossaryHref(term)}>
            {term}
          </a>
        ) : (
          <span key={key++} className="term">
            {term}
          </span>
        ),
      );
    } else out.push(<em key={key++}>{renderInline(tok.slice(1, -1), glossaryHref)}</em>);
    last = index + tok.length;
  }
  if (last < text.length) out.push(text.slice(last));
  return out;
}
