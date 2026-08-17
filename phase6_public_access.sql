-- AURA HUMANITAS — PHASE 6
-- Public article/issue access with subscription-gated signed downloads.

create or replace function public.get_article_download_url(p_article_id uuid)
returns text
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_path text;
  v_active boolean := false;
  v_admin boolean := false;
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

  select (role = 'admin') into v_admin
  from public.profiles
  where id = auth.uid();

  select (
    subscription_status = 'active'
    and (subscription_expires_at is null or subscription_expires_at > now())
  ) into v_active
  from public.profiles
  where id = auth.uid();

  if coalesce(v_admin,false) = false and coalesce(v_active,false) = false then
    raise exception 'SUBSCRIPTION_REQUIRED';
  end if;

  select storage.create_signed_url('journal-pdfs', v_path, 300)
  into v_url;

  return v_url;
end;
$$;

create or replace function public.get_issue_download_url(p_issue_id uuid)
returns text
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  v_path text;
  v_active boolean := false;
  v_admin boolean := false;
  v_url text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select full_issue_pdf_path into v_path
  from public.issues
  where id = p_issue_id
    and published = true;

  if v_path is null then
    raise exception 'ISSUE_NOT_AVAILABLE';
  end if;

  select (role = 'admin') into v_admin
  from public.profiles
  where id = auth.uid();

  select (
    subscription_status = 'active'
    and (subscription_expires_at is null or subscription_expires_at > now())
  ) into v_active
  from public.profiles
  where id = auth.uid();

  if coalesce(v_admin,false) = false and coalesce(v_active,false) = false then
    raise exception 'SUBSCRIPTION_REQUIRED';
  end if;

  select storage.create_signed_url('journal-issues', v_path, 300)
  into v_url;

  return v_url;
end;
$$;

revoke all on function public.get_article_download_url(uuid) from public;
grant execute on function public.get_article_download_url(uuid) to authenticated;

revoke all on function public.get_issue_download_url(uuid) from public;
grant execute on function public.get_issue_download_url(uuid) to authenticated;
