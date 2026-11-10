import { IOS_APP_ID } from "@/lib/env";

/** Le fichier d'association d'Apple : il autorise l'app iOS à ouvrir les pages de cours et
 *  d'auteurs du site (liens universels). iOS le lit à l'installation de l'app, sans redirection
 *  et en JSON ; les autres pages du site restent dans le navigateur. Voir docs/partage.md. */
export const dynamic = "force-static";

export function GET() {
  return Response.json(
    {
      applinks: {
        details: [
          {
            appIDs: [IOS_APP_ID],
            components: [
              { "/": "/courses/?*", comment: "A course page: /courses/150-why-does-the-sky-swirl" },
              { "/": "/c/?*", comment: "Short course link: /c/<course id>" },
              { "/": "/authors/?*", comment: "An author page: /authors/<slug>" },
            ],
          },
        ],
      },
    },
    { headers: { "Cache-Control": "public, max-age=3600" } },
  );
}
