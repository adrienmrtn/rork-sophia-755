import type { ReactNode } from "react";
import { renderInline } from "@/lib/catalog/inline";

/** Un rendu Markdown minimal et sûr pour nos propres documents (contrat, guide) : titres, listes,
 *  paragraphes, gras et italique. Rien d'autre, pas d'HTML. */
export function renderMarkdown(md: string): ReactNode {
  const lines = md.replace(/\r\n/g, "\n").split("\n");
  const out: ReactNode[] = [];
  let para: string[] = [];
  let list: string[] = [];
  let key = 0;
  const flushPara = () => {
    if (para.length) {
      out.push(<p key={key++} className="mb-4">{renderInline(para.join(" "))}</p>);
      para = [];
    }
  };
  const flushList = () => {
    if (list.length) {
      out.push(
        <ul key={key++} className="mb-4 list-disc pl-6">
          {list.map((item, i) => (
            <li key={i} className="mb-1">{renderInline(item)}</li>
          ))}
        </ul>,
      );
      list = [];
    }
  };
  for (const raw of lines) {
    const line = raw.trimEnd();
    if (!line.trim()) {
      flushPara();
      flushList();
      continue;
    }
    const h = /^(#{1,3})\s+(.*)$/.exec(line);
    if (h) {
      flushPara();
      flushList();
      const level = h[1].length;
      const text = h[2];
      if (level === 1) out.push(<h1 key={key++} className="mt-2 mb-4 text-[32px] font-extrabold tracking-[-0.8px] text-ink">{text}</h1>);
      else if (level === 2) out.push(<h2 key={key++} className="mt-8 mb-3 text-[22px] font-extrabold tracking-[-0.4px] text-ink">{text}</h2>);
      else out.push(<h3 key={key++} className="mt-6 mb-2 text-[18px] font-bold text-ink">{text}</h3>);
      continue;
    }
    const li = /^[-*]\s+(.*)$/.exec(line);
    if (li) {
      flushPara();
      list.push(li[1]);
      continue;
    }
    flushList();
    para.push(line.trim());
  }
  flushPara();
  flushList();
  return <>{out}</>;
}
