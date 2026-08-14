-- AURA HUMANITAS — PHASE 4
-- Monthly Issues file-upload additions. Run AFTER your existing Phase 3 SQL.

alter table public.issues add column if not exists cover_path text;
alter table public.issues add column if not exists full_issue_pdf_path text;
alter table public.issues add column if not exists issue_date date;
alter table public.issues add column if not exists title text;
alter table public.issues add column if not exists description text;
alter table public.issues add column if not exists published boolean not null default false;

-- Keep the private journal-pdfs bucket used by the admin upload system.
insert into storage.buckets (id,name,public)
values ('journal-pdfs','journal-pdfs',false)
on conflict (id) do update set public=false;

-- Admin upload/update/delete policies for issue cover images and full-issue PDFs.
drop policy if exists "Admins upload journal issue files" on storage.objects;
create policy "Admins upload journal issue files"
on storage.objects for insert to authenticated
with check (bucket_id='journal-pdfs' and public.current_user_role()='admin');

drop policy if exists "Admins update journal issue files" on storage.objects;
create policy "Admins update journal issue files"
on storage.objects for update to authenticated
using (bucket_id='journal-pdfs' and public.current_user_role()='admin')
with check (bucket_id='journal-pdfs' and public.current_user_role()='admin');

drop policy if exists "Admins delete journal issue files" on storage.objects;
create policy "Admins delete journal issue files"
on storage.objects for delete to authenticated
using (bucket_id='journal-pdfs' and public.current_user_role()='admin');
