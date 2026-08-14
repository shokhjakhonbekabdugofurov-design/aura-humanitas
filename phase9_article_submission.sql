create table if not exists public.article_submissions (
 id uuid primary key default gen_random_uuid(),
 submission_code text not null unique,
 full_name text not null, email text not null, university text not null,
 country text not null, field text not null, article_title text not null,
 abstract text not null, keywords text not null, article_type text not null,
 manuscript_path text not null, manuscript_filename text not null,
 word_count integer, checks jsonb not null default '{}'::jsonb,
 status text not null default 'Submitted'
  check (status in ('Submitted','Under Editorial Review','Accepted','Revision Required','Rejected')),
 editorial_note text, created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists article_submissions_status_idx on public.article_submissions(status,created_at desc);
alter table public.article_submissions enable row level security;
drop policy if exists "Anyone can submit manuscripts" on public.article_submissions;
create policy "Anyone can submit manuscripts" on public.article_submissions for insert to anon,authenticated with check (true);
drop policy if exists "Admins manage submissions" on public.article_submissions;
create policy "Admins manage submissions" on public.article_submissions for all to authenticated using (public.current_user_role()='admin') with check (public.current_user_role()='admin');
insert into storage.buckets(id,name,public) values('article-submissions','article-submissions',false)
on conflict(id) do update set public=false;
drop policy if exists "Submitters upload DOCX manuscripts" on storage.objects;
create policy "Submitters upload DOCX manuscripts" on storage.objects for insert to anon,authenticated
with check(bucket_id='article-submissions' and storage.extension(name)='docx' and (storage.foldername(name))[1]='manuscripts');
drop policy if exists "Admins manage submitted manuscripts" on storage.objects;
create policy "Admins manage submitted manuscripts" on storage.objects for all to authenticated
using(bucket_id='article-submissions' and public.current_user_role()='admin')
with check(bucket_id='article-submissions' and public.current_user_role()='admin');
