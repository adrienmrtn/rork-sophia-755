import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { SUPABASE_KEY, SUPABASE_URL } from "@/lib/env";

/** Rafraîchit la session Supabase à chaque requête et garde /studio et /admin aux connectés. */
export async function proxy(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  const protectedArea = pathname.startsWith("/studio") || pathname.startsWith("/admin");
  // Visiteur sans cookie de session : rien à rafraîchir, on ne touche pas à Supabase.
  const hasSession = request.cookies.getAll().some((c) => c.name.startsWith("sb-"));
  if (!hasSession) {
    if (!protectedArea) return NextResponse.next({ request });
    const url = request.nextUrl.clone();
    url.pathname = "/join";
    url.search = `?next=${encodeURIComponent(pathname + search)}`;
    return NextResponse.redirect(url);
  }
  let response = NextResponse.next({ request });
  const supabase = createServerClient(SUPABASE_URL, SUPABASE_KEY, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(list) {
        for (const { name, value } of list) request.cookies.set(name, value);
        response = NextResponse.next({ request });
        for (const { name, value, options } of list) response.cookies.set(name, value, options);
      },
    },
  });
  // Vérifie le jeton (localement quand les clés de signature le permettent) et le rafraîchit s'il expire.
  const { data } = await supabase.auth.getClaims();
  const user = data?.claims?.sub ?? null;
  if (protectedArea && !user) {
    const url = request.nextUrl.clone();
    url.pathname = "/join";
    url.search = `?next=${encodeURIComponent(pathname + search)}`;
    return NextResponse.redirect(url);
  }
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|art/|authors/|app/|.*\\.(?:png|jpg|jpeg|webp|svg|ico|txt|xml)$).*)"],
};
