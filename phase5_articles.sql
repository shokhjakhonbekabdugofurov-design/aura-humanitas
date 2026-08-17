-- AURA HUMANITAS — PHASE 5
-- Articles workflow. Run after previous schema/phase SQL.

create index if not exists articles_created_at_idx
on public.articles(created_at desc);

create index if not exists articles_issue_field_idx
on public.articles(issue_id, field);

-- The existing journal-pdfs bucket is reused for article PDFs.
-- Admin upload/update/delete/select policies were created in Phase 3.
