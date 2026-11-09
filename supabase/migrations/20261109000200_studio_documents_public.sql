-- Le contrat créateur et le guide d'écriture sont lisibles sans compte : la page publique
-- sophia-culture.com/legal/creator-agreement les affiche (rôle anon). Rien d'autre ne s'ouvre.

grant select on public.studio_documents to anon;

drop policy if exists studio_documents_public_read on public.studio_documents;
create policy studio_documents_public_read on public.studio_documents
  for select to anon using (true);
