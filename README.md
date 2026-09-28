# ECORECOVERY Bale WMS – GitHub Pages + Supabase

Independent browser-based edition. Does not use Render or Python. **Do not upload your existing SQLite database to GitHub.** Existing SQLite records are NOT automatically migrated. This release starts with a new Supabase database; migrate separately before production use.

## Setup
1. Create a Supabase project at https://supabase.com/dashboard and keep its database password private.
2. SQL Editor → New query → paste all of `schema.sql` → Run **once on a new project**.
3. Authentication → Providers → Email: disable public sign-ups. Authentication → Users → Add user (email/password), confirm the email if required. Only trusted staff should have accounts; all signed-in users currently have the same permissions, including deletion.
4. Project Settings → API: copy the Project URL and **publishable/anon key**. Never use `service_role` or database password in the web app.
5. Create a GitHub repository (private is fine), upload **index.html, app.js, style.css, schema.sql, README.md** to the repository root. Settings → Pages → Build and deployment → Deploy from a branch → `main` / `(root)` → Save. Wait for the Pages HTTPS URL.
6. Open the HTTPS URL, enter Supabase Project URL and public key, then sign in with the staff account. Each browser saves the public configuration locally. Add suppliers under Settings.

## Printing and scanning
- The label is 100×100 mm and includes QR (fixed bale code), supplier, intake date, LOT, and weight. Browser Print prints via the device's configured printer; set Zebra ZD220 label size 100×100 mm and scaling 100%. **Direct USB/raw ZPL printing from the hosted website is not implemented.** Use the PC connected to the printer for browser printing, or implement a local print bridge later.
- HID Zebra scanner works as a keyboard: pair it in HID mode, focus the Scan input, scan the QR; Enter triggers lookup if the scanner sends Enter. Otherwise press Search. Camera uses `BarcodeDetector` if supported by the browser; it requires HTTPS and permission. Browser support varies; use HID or manual entry if unavailable.
- QR contains only the immutable bale code. Visible label text contains other fields. This avoids stale data when status changes.

## Data, limitations, and safety
- Supabase is the shared online database. Back it up before real use. Deletion is permanent. The receipt's original total and quantity remain the original intake values if individual bales are deleted.
- RLS restricts tables to authenticated users; all authenticated users have full access. For production, add staff roles, admin-only deletion, audit/backups and operational security. No public signup.
- This first browser edition loads up to 10,000 bales; larger inventory needs paginated queries. The CSV uses semicolon separators and UTF-8 BOM for common Greek Excel settings; use Excel Data → From Text/CSV if delimiter detection differs.
- Supabase email/password authentication and CDN JavaScript require internet. Test with non-production data before use.
