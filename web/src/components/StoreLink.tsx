"use client";

import type { ReactNode } from "react";

/** Un bouton de store. Avec `resumeUrl`, le clic copie d'abord cette adresse dans le
 *  presse-papiers : c'est le seul relais entre la page et l'app tout juste installée, qui y
 *  retrouve le cours à ouvrir à la fin de l'onboarding (docs/partage.md). Sans presse-papiers
 *  (navigateur ancien, refus), le lien s'ouvre simplement. */
export function StoreLink({ href, resumeUrl, className, children, ...rest }: { href: string; resumeUrl?: string; className?: string; children: ReactNode; "aria-label"?: string }) {
  return (
    <a
      href={href}
      className={className}
      onClick={() => {
        if (!resumeUrl) return;
        try {
          void navigator.clipboard?.writeText(resumeUrl).catch(() => {});
        } catch {
          /* presse-papiers indisponible : rien à reprendre, le lien s'ouvre quand même */
        }
      }}
      {...rest}
    >
      {children}
    </a>
  );
}
