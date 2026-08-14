Phase 6 fix: live_public.js was querying legacy columns publication_date/year/month that do not exist in the current issues table.
It now uses the actual Phase 3/4 columns: id, volume, issue_number, issue_date, title, description, cover_path, full_issue_pdf_path, published.
No database schema change is required for this fix.
