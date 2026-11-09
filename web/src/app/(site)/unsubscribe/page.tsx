import type { Metadata } from "next";
import Link from "next/link";
import { SiteHeader } from "@/components/SiteChrome";
import { container } from "@/components/ui";
import { createAdminClient } from "@/lib/supabase/admin";

export const metadata: Metadata = { title: "Email preferences", robots: { index: false } };
export const dynamic = "force-dynamic";

/** Le lien « ne plus recevoir ces e-mails » des messages « nouveau cours » : le jeton de l'e-mail
 *  coupe les envois pour ce lecteur (notification_unsubscribe). */
export default async function UnsubscribePage({ searchParams }: PageProps<"/unsubscribe">) {
  const sp = await searchParams;
  const token = typeof sp.token === "string" ? sp.token.trim() : "";
  let state: "done" | "unknown" | "error" = "unknown";
  if (/^[0-9a-f-]{36}$/i.test(token)) {
    try {
      const admin = createAdminClient();
      const { data, error } = await admin.rpc("notification_unsubscribe", { p_token: token });
      state = error ? "error" : data ? "done" : "unknown";
    } catch {
      state = "error";
    }
  }
  return (
    <>
      <SiteHeader />
      <main className={`${container} flex flex-col gap-6 pt-16 pb-24`}>
        <h1 className="text-[34px] font-extrabold tracking-[-0.8px]">{state === "done" ? "You will not receive these emails anymore." : state === "error" ? "Something went wrong." : "This link is not valid."}</h1>
        <p className="max-w-[560px] text-[16px] leading-[1.6] text-ink-3">
          {state === "done"
            ? "We will no longer email you when an author you follow publishes a course. You keep your subscriptions in the app."
            : state === "error"
              ? "Please try the link again in a minute, or write to maximilien@vikstudios.com."
              : "The link may have been cut by your email client. Open the email again and tap the link, or write to maximilien@vikstudios.com."}
        </p>
        <Link href="/" className="text-[15px] font-bold text-blue">
          Back to sophia-culture.com
        </Link>
      </main>
    </>
  );
}
