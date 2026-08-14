AURA HUMANITAS — PHASE 3

IMPORTANT:
The public journal interface (index.html) has NOT been redesigned.
Phase 3 adds the backend publication workflow and separate article reader/admin
pages. The existing design can now be connected to live database content.

NEW:
1. phase3.sql
   - issues table
   - articles table
   - private journal-pdfs storage bucket
   - admin-only article/issue management policies
   - signed PDF download function requiring an active subscription

2. admin/index.html
   - Admin dashboard
   - Create monthly issues
   - Upload PDF articles
   - Store article metadata
   - Draft/publish controls
   - Subscription request approval

3. article/index.html
   - Article detail page
   - Abstract, author, university, field, keywords, pages, DOI
   - Login requirement
   - Active-subscription requirement
   - Short-lived signed PDF URL

4. phase3_public_integration.js
   - Safe integration helper for the existing public interface.
   - It does not change your current CSS/design.

SETUP:
1. Open Supabase SQL Editor.
2. Run supabase_schema.sql.
3. Run phase2_additions.sql.
4. Run phase3.sql.
5. Ensure config.js contains ONLY your Supabase URL and publishable/anon key.
6. Never put a service_role key in browser code.
7. Make sure your admin profile has role='admin'.
8. Sign in at auth/index.html.
9. Open admin/index.html.
10. Create the monthly issue first.
11. Upload a PDF article and assign it to the issue.
12. Publish the issue and article.
13. Use article/index.html?id=ARTICLE_UUID to test article access.

SUBSCRIPTION:
Phase 2/3 uses a manual approval workflow. An author/reader requests a subscription.
The admin approves it, which changes profiles.subscription_status to active.
The PDF function checks this state before issuing a signed URL.

PUBLIC INTERFACE:
Do NOT replace the existing homepage markup just to make it dynamic.
The next integration step should target the exact existing cards/sections and inject
live article data while preserving the existing visual structure and CSS.

SECURITY:
- PDF bucket is private.
- Browser users cannot list/download PDFs directly.
- Only admins can upload/update/delete PDFs.
- Readers get a short-lived signed URL only after authentication + active subscription.
- RLS protects issues and articles.
