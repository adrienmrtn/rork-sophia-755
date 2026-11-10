import { NextResponse, type NextRequest } from "next/server";
import { courseNumber } from "@/lib/catalog/slugs";

/** `/c/<identifiant du cours>` : le lien court que l'app partage quand elle n'a que l'identifiant.
 *  Il mène à la fiche du cours (qui se redirige vers son adresse lisible), ou à l'exploration
 *  quand l'identifiant ne porte pas de numéro. */
export async function GET(request: NextRequest, ctx: RouteContext<"/c/[id]">) {
  const { id } = await ctx.params;
  const number = courseNumber(id);
  return NextResponse.redirect(new URL(number === null ? "/courses" : `/courses/${number}`, request.url), { status: 307 });
}
