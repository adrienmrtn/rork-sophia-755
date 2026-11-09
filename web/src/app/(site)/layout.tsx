import { SiteFooter } from "@/components/SiteChrome";

/** Les pages publiques : chaque page pose son en-tête (pour l'onglet actif), le pied est commun. */
export default function SiteLayout({ children }: LayoutProps<"/">) {
  return (
    <>
      <div className="flex-1">{children}</div>
      <SiteFooter />
    </>
  );
}
