import { redirect } from "next/navigation";
import { getStudioSession } from "@/lib/studio/account";

export const dynamic = "force-dynamic";

/** L'espace auteur : connecté obligatoirement (le proxy redirige déjà, ceci est la ceinture). */
export default async function StudioLayout({ children }: LayoutProps<"/studio">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/studio");
  return <div className="flex min-h-full flex-1 flex-col bg-paper">{children}</div>;
}
