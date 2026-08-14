
-- AURA HUMANITAS — PHASE 3
-- Run AFTER supabase_schema.sql and phase2_additions.sql.

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  volume text not null,
  issue_number text not null,
  issue_date date not null,
  title text not null,
  description text,
  cover_path text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  unique(volume, issue_number)
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid references public.issues(id) on delete set null,
  title text not null,
  slug text not null unique,
  author_name text not null,
  university text,
  field text not null,
  abstract text,
  keywords text,
  pages text,
  doi text,
  pdf_path text,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists articles_issue_id_idx on public.articles(issue_id);
create index if not exists articles_field_idx on public.articles(field);
create index if not exists articles_published_idx on public.articles(published);
create index if not exists issues_published_idx on public.issues(published, issue_date desc);

alter table public.issues enable row level security;
alter table public.articles enable row level security;

drop policy if exists "Published issues are public" on public.issues;
create policy "Published issues are public"
on public.issues for select
to anon, authenticated
using (published = true or public.current_user_role() = 'admin');

drop policy if exists "Admins manage issues" on public.issues;
create policy "Admins manage issues"
on public.issues for all
to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

drop policy if exists "Published articles are public" on public.articles;
create policy "Published articles are public"
on public.articles for select
to anon, authenticated
using (published = true or public.current_user_role() = 'admin');

drop policy if exists "Admins manage articles" on public.articles;
create policy "Admins manage articles"
on public.articles for all
to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

-- Private bucket. Create it if it does not exist.
insert into storage.buckets (id, name, public)
values ('journal-pdfs', 'journal-pdfs', false)
on conflict (id) do update set public = false;

drop policy if exists "Admins upload journal PDFs" on storage.objects;
create policy "Admins upload journal PDFs"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'journal-pdfs'
  and public.current_user_role() = 'admin'
);

drop policy if exists "Admins update journal PDFs" on storage.objects;
create policy "Admins update journal PDFs"
on storage.objects for update
to authenticated
using (
  bucket_id = 'journal-pdfs'
  and public.current_user_role() = 'admin'
)
with check (
  bucket_id = 'journal-pdfs'
  and public.current_user_role() = 'admin'
);

drop policy if exists "Admins delete journal PDFs" on storage.objects;
create policy "Admins delete journal PDFs"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'journal-pdfs'
  and public.current_user_role() = 'admin'
);

drop policy if exists "Admins view journal PDFs" on storage.objects;
create policy "Admins view journal PDFs"
on storage.objects for select
to authenticated
using (
  bucket_id = 'journal-pdfs'
  and public.current_user_role() = 'admin'
);

-- Returns only a short-lived signed URL after checking:
-- 1) article is published
-- 2) user has an active subscription
create or replace function public.get_article_download_url(p_article_id uuid)
returns text
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_path text;
  v_active boolean;
  v_url text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select pdf_path into v_path
  from public.articles
  where id = p_article_id
    and published = true;

  if v_path is null then
    raise exception 'ARTICLE_NOT_AVAILABLE';
  end if;

  select (
    subscription_status = 'active'
    and (subscription_expires_at is null or subscription_expires_at > now())
  ) into v_active
  from public.profiles
  where id = auth.uid();

  if coalesce(v_active, false) = false then
    raise exception 'SUBSCRIPTION_REQUIRED';
  end if;

  select storage.create_signed_url('journal-pdfs', v_path, 300)
  into v_url;

  return v_url;
end;
$$;

revoke all on function public.get_article_download_url(uuid) from public;
grant execute on function public.get_article_download_url(uuid) to authenticated;
