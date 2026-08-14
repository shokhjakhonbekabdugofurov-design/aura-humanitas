-- AURA HUMANITAS — FINAL FIXES
-- Run this file in Supabase SQL Editor AFTER the existing journal SQL files.
-- Interface colors/design are not affected by this migration.

-- 1. Journal is active from 2026.
-- Keep 2026 issues and remove published/unpublished issues from earlier years.
alter table public.issues
  add column if not exists year integer;

alter table public.issues
  add column if not exists month integer;

update public.issues
set
  year = extract(year from issue_date)::integer,
  month = extract(month from issue_date)::integer
where issue_date is not null
  and (year is null or month is null);

delete from public.issues
where coalesce(
  year,
  case when issue_date is not null then extract(year from issue_date)::integer end
) < 2026;

-- New monthly issues may be created without manually entering year/month.
alter table public.issues
  alter column year drop not null;

alter table public.issues
  alter column month drop not null;

-- 2. Keep article-submission metadata flexible.
-- No word-count or file-size validation is required by the journal submission form.
alter table public.article_submissions
  alter column word_count drop not null;

-- Ensure the manuscript submission table remains available for the public form.
create index if not exists article_submissions_created_at_idx
  on public.article_submissions(created_at desc);

-- 3. Required public submission storage.
insert into storage.buckets(id,name,public)
values ('article-submissions','article-submissions',false)
on conflict (id) do update set public=false;

drop policy if exists "Submitters upload DOCX manuscripts" on storage.objects;

create policy "Submitters upload DOCX manuscripts"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id='article-submissions'
  and storage.extension(name)='docx'
  and (storage.foldername(name))[1]='manuscripts'
);

drop policy if exists "Admins manage submitted manuscripts" on storage.objects;

create policy "Admins manage submitted manuscripts"
on storage.objects for all
to authenticated
using (
  bucket_id='article-submissions'
  and public.current_user_role()='admin'
)
with check (
  bucket_id='article-submissions'
  and public.current_user_role()='admin'
);
