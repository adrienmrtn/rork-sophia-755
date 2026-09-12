-- Public narration MP3s, one per course and language.
-- Upload with: python3 scripts/upload_course_audio_to_supabase.py
-- Service role bypasses RLS; anon/authenticated may only read.
--
-- Deliberately public, like `course-images`: the app reads with the publishable
-- key and no session. The consequence is that the freemium gate on audio is a
-- client-side rule, not an enforced one — anyone reading the network traffic can
-- fetch any object. Move to a private bucket + signed URLs if that becomes a
-- revenue problem.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'course-audio',
  'course-audio',
  true,
  52428800,
  array['audio/mpeg']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "course_audio_public_read" on storage.objects;
create policy "course_audio_public_read"
on storage.objects
for select
to public
using (bucket_id = 'course-audio');
