/**
 * Candidatures « Devenir créateur ».
 *
 * Pas encore branché : l'envoi sera relié au projet Supabase de l'app (table à créer,
 * par exemple `creator_applications`, avec une règle RLS qui n'autorise que l'insertion).
 * Les noms de champs ci-dessous sont pensés pour devenir les colonnes de cette table.
 */
export type CreatorApplication = {
  first_name: string;
  last_name: string;
  email: string;
  title: string;
  institution: string;
  country: string;
  subjects: string[];
  profile_url: string;
  course_title: string;
  course_pitch: string;
  writing_language: string;
  accepts_terms: boolean;
};

export type SubmitResult = { ok: true } | { ok: false; reason: "not_connected" | "error"; message: string };

export async function submitCreatorApplication(application: CreatorApplication): Promise<SubmitResult> {
  void application;
  return {
    ok: false,
    reason: "not_connected",
    message: "Le formulaire est prêt, mais l'envoi n'est pas encore relié à la base de données. Rien n'a été envoyé.",
  };
}
