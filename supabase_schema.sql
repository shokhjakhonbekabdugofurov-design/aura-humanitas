-- AURA HUMANITAS — PHASE 1
-- Run in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  university text,
  field text,
  email text,
  role text not null default 'author' check (role in ('admin','author','reader')),
  subscription_status text not null default 'inactive' check (subscription_status in ('inactive','active','expired')),
  subscription_expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  year integer not null,
  volume text not null,
  issue_number integer not null,
  month text not null,
  publication_date date,
  status text not null default 'draft' check (status in ('draft','published')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(year, issue_number)
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author_name text not null,
  university text,
  field text not null,
  abstract text,
  keywords text[] default '{}',
  pages text,
  doi text,
  issue_id uuid references public.issues(id) on delete set null,
  pdf_path text not null,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.issues enable row level security;
alter table public.articles enable row level security;

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path=public
as $$ select role from public.profiles where id=auth.uid() $$;

create policy "Users read own profile" on public.profiles
for select to authenticated using (id=auth.uid());

create policy "Admins read profiles" on public.profiles
for select to authenticated using (public.current_user_role()='admin');

create policy "Users update own profile" on public.profiles
for update to authenticated using (id=auth.uid()) with check (id=auth.uid());

create policy "Published issues visible" on public.issues
for select to anon,authenticated
using (status='published' or public.current_user_role()='admin');

create policy "Admins insert issues" on public.issues
for insert to authenticated with check (public.current_user_role()='admin');

create policy "Admins update issues" on public.issues
for update to authenticated using (public.current_user_role()='admin')
with check (public.current_user_role()='admin');

create policy "Admins delete issues" on public.issues
for delete to authenticated using (public.current_user_role()='admin');

create policy "Published articles visible" on public.articles
for select to anon,authenticated
using (published=true or public.current_user_role()='admin');

create policy "Admins insert articles" on public.articles
for insert to authenticated with check (public.current_user_role()='admin');

create policy "Admins update articles" on public.articles
for update to authenticated using (public.current_user_role()='admin')
with check (public.current_user_role()='admin');

create policy "Admins delete articles" on public.articles
for delete to authenticated using (public.current_user_role()='admin');

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  insert into public.profiles(id,full_name,university,field,email,role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    coalesce(new.raw_user_meta_data->>'university',''),
    coalesce(new.raw_user_meta_data->>'field',''),
    new.email,'author'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users for each row execute procedure public.handle_new_user();

-- Create a PRIVATE Storage bucket named: article-pdfs
create policy "Admins upload PDFs" on storage.objects
for insert to authenticated
with check (bucket_id='article-pdfs' and public.current_user_role()='admin');

create policy "Admins update PDFs" on storage.objects
for update to authenticated
using (bucket_id='article-pdfs' and public.current_user_role()='admin');

create policy "Admins delete PDFs" on storage.objects
for delete to authenticated
using (bucket_id='article-pdfs' and public.current_user_role()='admin');
