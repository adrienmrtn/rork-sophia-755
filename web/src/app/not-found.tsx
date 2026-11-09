export default function NotFound() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-cream px-4 text-center">
      <p className="eyebrow">Erreur 404</p>
      <h1 className="mt-3 text-[36px] font-extrabold tracking-tight">Cette page n&apos;existe pas</h1>
      <p className="mt-2 font-serif text-[19px] text-ink-2">Elle a peut-être changé d&apos;adresse.</p>
      <a href="/" className="mt-6 inline-flex h-12 items-center rounded-xl bg-navy px-6 font-bold text-white">
        Retour à l&apos;accueil
      </a>
    </main>
  );
}
