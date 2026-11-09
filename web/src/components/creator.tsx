"use client";

import { AnimatePresence, motion, useInView } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { submitCreatorApplication, type CreatorApplication, type SubmitResult } from "@/lib/creatorApplications";
import { IconCheck } from "./icons";

const draftTitle = "Pourquoi les Romains construisaient-ils des routes droites ?";

/** Faux éditeur dont le titre se tape tout seul quand il apparaît. */
export function EditorMock() {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-15% 0px" });
  const [typed, setTyped] = useState(draftTitle.length);

  useEffect(() => {
    if (!inView || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    setTyped(0);
    let n = 0;
    const t = setInterval(() => {
      n += 1;
      setTyped(n);
      if (n >= draftTitle.length) clearInterval(t);
    }, 38);
    return () => clearInterval(t);
  }, [inView]);

  const finished = typed >= draftTitle.length;
  return (
    <div ref={ref} className="overflow-hidden rounded-[22px] bg-paper shadow-[0_30px_60px_-30px_rgba(22,38,61,0.45)] ring-1 ring-line">
      <div className="flex items-center gap-1.5 border-b border-line px-4 py-3">
        <span className="h-2.5 w-2.5 rounded-full bg-coral/70" />
        <span className="h-2.5 w-2.5 rounded-full bg-saffron/80" />
        <span className="h-2.5 w-2.5 rounded-full bg-sage/70" />
        <span className="ml-3 text-[12px] font-semibold text-ink-3">Brouillon · enregistré</span>
      </div>
      <div className="p-6">
        <p className="eyebrow">Histoire · Partie 1 sur 5</p>
        <p className="mt-2 min-h-[3.4em] text-[22px] font-extrabold leading-snug tracking-tight">
          {draftTitle.slice(0, typed)}
          {!finished && <span className="ml-0.5 inline-block h-[1em] w-[2px] translate-y-[3px] animate-pulse bg-navy" />}
        </p>
        <div className="mt-4 space-y-2.5">
          {[100, 94, 97, 60].map((w, i) => (
            <motion.div key={i} className="h-2.5 rounded-full bg-sand" initial={false} animate={{ width: finished ? `${w}%` : "0%" }} transition={{ delay: i * 0.12, duration: 0.6 }} />
          ))}
        </div>
        <motion.div initial={false} animate={{ opacity: finished ? 1 : 0, y: finished ? 0 : 10 }} transition={{ delay: 0.6 }} className="mt-5 rounded-xl bg-saffron-soft p-4">
          <p className="text-[13px] font-extrabold text-navy">Le savais-tu ?</p>
          <p className="mt-1 font-serif text-[15px] leading-snug text-ink-2">Le réseau routier romain a compté plus de 80 000 km de voies pavées.</p>
        </motion.div>
        <div className="mt-5 flex items-center justify-between text-[13px] font-semibold text-ink-2">
          <span className="tabular-nums">{finished ? 642 : Math.round((typed / draftTitle.length) * 40)} mots</span>
          <span className="rounded-lg bg-navy px-3 py-1.5 text-white">Envoyer en relecture</span>
        </div>
      </div>
    </div>
  );
}

const subjectsList = ["Histoire", "Sciences", "Comprendre le monde", "Littérature", "Mythologie", "Art", "Philosophie", "Autre"];
const languages = ["Français", "Anglais", "Espagnol", "Allemand", "Italien", "Portugais", "Autre"];

const field = "h-12 w-full rounded-xl bg-paper px-4 text-[15px] outline-none ring-1 ring-line transition focus:ring-2 focus:ring-navy";
const labelCls = "mb-1.5 block text-[14px] font-bold";

/** Formulaire de candidature. L'envoi passe par submitCreatorApplication (à relier à Supabase). */
export function CreatorForm() {
  const [subjects, setSubjects] = useState<string[]>([]);
  const [pitch, setPitch] = useState("");
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<SubmitResult | null>(null);
  const [error, setError] = useState("");

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    if (subjects.length === 0) {
      setError("Choisissez au moins un domaine.");
      return;
    }
    setError("");
    const app: CreatorApplication = {
      first_name: String(f.get("first_name") ?? "").trim(),
      last_name: String(f.get("last_name") ?? "").trim(),
      email: String(f.get("email") ?? "").trim(),
      title: String(f.get("title") ?? "").trim(),
      institution: String(f.get("institution") ?? "").trim(),
      country: String(f.get("country") ?? "").trim(),
      subjects,
      profile_url: String(f.get("profile_url") ?? "").trim(),
      course_title: String(f.get("course_title") ?? "").trim(),
      course_pitch: pitch.trim(),
      writing_language: String(f.get("writing_language") ?? ""),
      accepts_terms: f.get("accepts_terms") === "on",
    };
    setSending(true);
    setResult(await submitCreatorApplication(app));
    setSending(false);
  }

  if (result?.ok) {
    return (
      <motion.div initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} className="rounded-[24px] bg-sage-soft p-8 text-center">
        <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-sage text-white">
          <IconCheck className="h-7 w-7" />
        </span>
        <p className="mt-4 text-[24px] font-extrabold">Candidature envoyée</p>
        <p className="mt-2 font-serif text-[18px] text-ink-2">L&apos;équipe éditoriale vous répond sous une semaine, par e-mail.</p>
      </motion.div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-6 rounded-[24px] bg-cream p-6 sm:p-9" noValidate={false}>
      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label htmlFor="first_name" className={labelCls}>Prénom</label>
          <input id="first_name" name="first_name" required autoComplete="given-name" className={field} />
        </div>
        <div>
          <label htmlFor="last_name" className={labelCls}>Nom</label>
          <input id="last_name" name="last_name" required autoComplete="family-name" className={field} />
        </div>
        <div className="sm:col-span-2">
          <label htmlFor="email" className={labelCls}>E-mail professionnel</label>
          <input id="email" name="email" type="email" required autoComplete="email" placeholder="prenom.nom@universite.fr" className={field} />
        </div>
        <div>
          <label htmlFor="title" className={labelCls}>Titre ou fonction</label>
          <input id="title" name="title" required placeholder="Maîtresse de conférences en histoire" className={field} />
        </div>
        <div>
          <label htmlFor="institution" className={labelCls}>Établissement</label>
          <input id="institution" name="institution" placeholder="Université, lycée, laboratoire…" className={field} />
        </div>
        <div>
          <label htmlFor="country" className={labelCls}>Pays</label>
          <input id="country" name="country" autoComplete="country-name" className={field} />
        </div>
        <div>
          <label htmlFor="profile_url" className={labelCls}>Profil ou publications</label>
          <input id="profile_url" name="profile_url" type="url" placeholder="ORCID, Google Scholar, LinkedIn…" className={field} />
        </div>
      </div>

      <fieldset>
        <legend className={labelCls}>Vos domaines</legend>
        <div className="flex flex-wrap gap-2">
          {subjectsList.map((s) => {
            const on = subjects.includes(s);
            return (
              <motion.button
                key={s}
                type="button"
                whileTap={{ scale: 0.95 }}
                aria-pressed={on}
                onClick={() => setSubjects((cur) => (on ? cur.filter((x) => x !== s) : [...cur, s]))}
                className={`inline-flex h-10 items-center gap-1.5 rounded-full px-4 text-[14px] font-bold transition-colors ${on ? "bg-navy text-white" : "bg-paper text-ink-2 ring-1 ring-line hover:text-ink"}`}
              >
                {on && <IconCheck className="h-4 w-4" />}
                {s}
              </motion.button>
            );
          })}
        </div>
      </fieldset>

      <div>
        <label htmlFor="course_title" className={labelCls}>Le premier cours que vous aimeriez écrire</label>
        <input id="course_title" name="course_title" required placeholder="Pourquoi les Romains construisaient-ils des routes droites ?" className={field} />
      </div>
      <div>
        <label htmlFor="course_pitch" className={labelCls}>En quelques lignes, ce que le lecteur va apprendre</label>
        <textarea
          id="course_pitch"
          name="course_pitch"
          required
          maxLength={600}
          rows={4}
          value={pitch}
          onChange={(e) => setPitch(e.target.value)}
          className="w-full rounded-xl bg-paper px-4 py-3 text-[15px] leading-relaxed outline-none ring-1 ring-line transition focus:ring-2 focus:ring-navy"
        />
        <p className="mt-1 text-right text-[12px] tabular-nums text-ink-3">{pitch.length} / 600</p>
      </div>
      <div className="sm:w-1/2">
        <label htmlFor="writing_language" className={labelCls}>Langue d&apos;écriture</label>
        <select id="writing_language" name="writing_language" className={field} defaultValue="Français">
          {languages.map((l) => (
            <option key={l}>{l}</option>
          ))}
        </select>
      </div>
      <label className="flex items-start gap-3 text-[14px] text-ink-2">
        <input type="checkbox" name="accepts_terms" required className="mt-1 h-4 w-4 accent-[var(--color-navy)]" />
        J&apos;accepte que Sophia me recontacte au sujet de ma candidature et conserve ces informations le temps de l&apos;étudier.
      </label>

      {error && <p className="text-[14px] font-semibold text-coral">{error}</p>}
      <AnimatePresence>
        {result && !result.ok && (
          <motion.p initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} className="rounded-xl bg-saffron-soft px-4 py-3 text-[14px] font-semibold text-ink" role="status">
            {result.message}
          </motion.p>
        )}
      </AnimatePresence>

      <motion.button
        type="submit"
        disabled={sending}
        whileHover={{ y: -2 }}
        whileTap={{ scale: 0.97 }}
        className="inline-flex h-14 items-center justify-center rounded-xl bg-navy px-8 text-base font-bold text-white shadow-[0_8px_20px_-8px_rgba(26,58,107,0.6)] disabled:opacity-60"
      >
        {sending ? "Envoi…" : "Envoyer ma candidature"}
      </motion.button>
    </form>
  );
}
