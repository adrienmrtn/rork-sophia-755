import { NextResponse, type NextRequest } from "next/server";
import type { EmailOtpType } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";

/** Retour de Google, Apple, du lien magique ou de la confirmation d'email : on pose la session
 *  et on envoie vers le Studio (ou la page demandée). */
export async function GET(request: NextRequest) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const tokenHash = url.searchParams.get("token_hash");
  const type = url.searchParams.get("type") as EmailOtpType | null;
  const nextParam = url.searchParams.get("next") ?? "/studio";
  const next = nextParam.startsWith("/") ? nextParam : "/studio";
  const supabase = await createClient();
  let error: string | null = null;
  if (code) {
    const res = await supabase.auth.exchangeCodeForSession(code);
    error = res.error?.message ?? null;
  } else if (tokenHash && type) {
    const res = await supabase.auth.verifyOtp({ token_hash: tokenHash, type });
    error = res.error?.message ?? null;
  } else {
    error = "missing_code";
  }
  if (error) {
    return NextResponse.redirect(new URL(`/join?error=${encodeURIComponent(error)}`, url.origin));
  }
  return NextResponse.redirect(new URL(next, url.origin));
}
