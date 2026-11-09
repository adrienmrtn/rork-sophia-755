import { redirect } from "next/navigation";
import { getStudioSession } from "@/lib/studio/account";

export const dynamic = "force-dynamic";

/** L'espace équipe : réservé aux comptes de studio_admins. */
export default async function AdminLayout({ children }: LayoutProps<"/admin">) {
  const session = await getStudioSession();
  if (!session) redirect("/join?next=/admin");
  if (!session.isAdmin) redirect("/studio");
  return <div className="flex min-h-full flex-1 flex-col bg-paper">{children}</div>;
}
