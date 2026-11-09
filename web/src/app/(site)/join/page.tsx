import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { CheckIcon, Eyebrow, container } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { t } from "@/lib/copy/en";
import { JoinForm } from "./JoinForm";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { title: "Create an author account", robots: { index: false } };

export default async function JoinPage({ searchParams }: PageProps<"/join">) {
  const params = await searchParams;
  const nextParam = typeof params.next === "string" && params.next.startsWith("/") ? params.next : "/studio";
  const mode = params.mode === "signin" ? "signin" : "create";
  const error = typeof params.error === "string" ? params.error : null;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (user) redirect(nextParam);

  const j = t.join;
  return (
    <div className="flex min-h-full flex-col bg-paper">
      <header className="border-b border-line bg-white">
        <div className={`${container} flex items-center justify-between py-3.5`}>
          <Link href="/" aria-label="Sophia, home" className="flex items-center">
            <Image src="/brand/sophia-logo.png" alt="Sophia" width={1192} height={334} className="h-[34px] w-auto" />
          </Link>
          <span className="text-[14px] font-bold text-ink-2">EN</span>
        </div>
      </header>
      <main className={`${container} flex flex-1 flex-wrap items-center justify-center gap-x-20 gap-y-12 py-14`}>
        <section className="flex min-w-0 max-w-[520px] flex-[1_1_400px] flex-col gap-5">
          <Eyebrow>{j.eyebrow}</Eyebrow>
          <h1 className="text-[40px] font-extrabold leading-[1.08] tracking-[-1.2px]">{j.title}</h1>
          <p className="text-[17px] leading-[1.55] text-ink-3">{j.lead}</p>
          <ul className="flex flex-col gap-3 text-[15px] font-semibold text-ink-2">
            {j.points.map((p) => (
              <li key={p} className="flex items-start gap-2.5">
                <CheckIcon className="mt-0.5 shrink-0 text-green-2" /> {p}
              </li>
            ))}
          </ul>
          <Image src="/art/poster_ecrire.webp" alt="" width={1365} height={1024} className="mt-2 aspect-[4/3] w-full max-w-[420px] rounded-card object-cover" />
        </section>
        <JoinForm next={nextParam} initialMode={mode} initialError={error} />
      </main>
    </div>
  );
}
