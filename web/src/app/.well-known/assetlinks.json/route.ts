import { ANDROID_APP_FINGERPRINTS, ANDROID_PACKAGE } from "@/lib/env";

/** Le fichier d'association d'Android : il autorise l'app à ouvrir les pages de cours et
 *  d'auteurs du site (liens d'app). Android le lit à l'installation de l'app, sans redirection
 *  et en JSON. Sans empreinte de certificat déclarée, le fichier est vide et les liens restent
 *  dans le navigateur. Voir docs/partage.md. */
export const dynamic = "force-static";

export function GET() {
  const statements =
    ANDROID_APP_FINGERPRINTS.length === 0
      ? []
      : [
          {
            relation: ["delegate_permission/common.handle_all_urls"],
            target: {
              namespace: "android_app",
              package_name: ANDROID_PACKAGE,
              sha256_cert_fingerprints: ANDROID_APP_FINGERPRINTS,
            },
          },
        ];
  return Response.json(statements, { headers: { "Cache-Control": "public, max-age=3600" } });
}
