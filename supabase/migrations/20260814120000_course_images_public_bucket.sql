-- Public cover JPEGs for Android (and any future web client).
-- Upload with: python3 scripts/upload_course_images_to_supabase.py
-- Service role bypasses RLS; anon/authenticated may only read.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'course-images',
  'course-images',
  true,
  2000000,
  array['image/jpeg']::text[]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "course_images_public_read" on storage.objects;
create policy "course_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'course-images');
