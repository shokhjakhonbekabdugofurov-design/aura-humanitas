
-- AURA HUMANITAS — PHASE 2 ADDITIONS
-- Run AFTER supabase_schema.sql.

create table if not exists public.subscription_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  note text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

alter table public.subscription_requests enable row level security;

create policy "Users can create own subscription request"
on public.subscription_requests
for insert to authenticated
with check (user_id = auth.uid());

create policy "Users can view own subscription requests"
on public.subscription_requests
for select to authenticated
using (user_id = auth.uid());

create policy "Admins can view subscription requests"
on public.subscription_requests
for select to authenticated
using (public.current_user_role() = 'admin');

create policy "Admins can update subscription requests"
on public.subscription_requests
for update to authenticated
using (public.current_user_role() = 'admin')
with check (public.current_user_role() = 'admin');

-- NOTE:
-- The subscription request is intentionally NOT an automatic paid subscription.
-- Phase 3 will connect the approved subscription state to protected PDF downloads.
