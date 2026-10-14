# Montenova MAP Growth Family Portal

An English-language parent portal with a separate staff import section. GitHub Pages hosts only the static site. Supabase hosts and protects the underlying assessment records.

## Read this first

**This is a starting implementation, not a security-certified production system.** Do not upload identifiable student data or invite families until your school's authorized technical/privacy lead has checked the authentication setup, row-level security (RLS), administration, data protection obligations, and functionality with test accounts. The demo uses only fictional records. In particular, confirm that unverified users cannot sign in, and independently test two different parent accounts and an administrator account. Do not store student data, parent-link CSVs with real addresses, or any private key in GitHub.

## A. Preview the design

1. Open `index.html` in Chrome/Safari, with internet access to load the Supabase and CSV libraries.
2. Choose **Preview with fictional student data**.
3. Select the sample student and choose **Print / Save PDF**.

## B. Create your Supabase database

1. Create a project at https://supabase.com/ . Choose a suitable data-hosting region according to school policy.
2. Open **SQL Editor** and run the complete `schema.sql` file.
3. Under **Authentication > Providers > Email**, require email verification (**Confirm email**). Disable public self-signup if you prefer the school to provision/invite all family accounts. Configure email delivery appropriately.
4. In **Authentication > URL Configuration**, add your actual GitHub Pages URL as the Site URL / allowed redirect URL (including the relevant path). Configure password recovery flow before launching; the prototype includes a reset-request button but not a custom password update form. You may need a dedicated recovery page or Supabase-hosted flow.
5. Create and confirm a school administrator's Supabase Auth account through the Authentication dashboard or the sign-up flow.
6. In the SQL Editor, grant admin status by replacing the email here:

```sql
insert into public.portal_admins (user_id)
select id from auth.users where lower(email) = 'admin@montenova.example'
on conflict do nothing;
```

7. Create verified parent accounts with the exact email addresses appearing in your parent links CSV. Never give a parent access to a child before authorization is verified by the school.
8. **Test access separation:** Parent A must see only child A; Parent B must see only child B; unauthorized Parent C must see no data. Try direct REST queries, not just the UI.

## C. Publish with GitHub Pages

1. Go to https://github.com/new and create a **public** repository such as `montenova-map-portal` (public repo contains site code only, never real scores).
2. Upload `index.html` and optionally `README.md` and `schema.sql` using **Add file > Upload files**, then commit. Do not upload either real CSV file.
3. Go to **Settings > Pages > Build and deployment**. Choose **Deploy from a branch**, **main**, **/(root)**, and **Save**.
4. Once published, the URL will be like `https://YOUR-USERNAME.github.io/montenova-map-portal/`.
5. In `index.html`, replace the two empty values inside `CONFIG` with the project's **public Supabase URL** and **publishable/anon key**, and commit the change. The key is deliberately public; never use a `service_role` or secret key. RLS policies are essential.
6. Check that the GitHub Pages URL is in the Supabase Auth redirect allowlist. Visit the public page and test school-approved logins.

A GitHub Pages URL is public even if you share it only with school families. Privacy comes from authentication and Supabase RLS, *not* from hiding the URL.

## D. Bulk-import from Excel

**Recommended first release:** One school-controlled Excel workbook, with two sheets exported as UTF-8 CSV files:

- `sample_map_results.csv` gives the **exact** result headers. Each row is one student + subject + season + school year. Put all terms and grades together in one file. `student_id, student_name, grade, subject, term, school_year, rit` are mandatory. `percentile, test_date, growth` are optional. Keep one stable unique student ID across subjects and seasons.
- `sample_parent_links.csv` gives the **exact** parent-access headers. Each row grants one email access to one student ID. For siblings, repeat the parent email; for two guardians, add a row for each guardian. **This file controls which child's private results a family can see.** Verify it meticulously.

In the admin login, use **Import results CSV** and **Import parent links CSV**. The import runs in batches of 200 records and supports re-imports; results upsert by student_id + subject + term + school_year. CSV files must be under 15,000 rows each; split larger ones.

**Important:** The existing NWEA *Combined Data Statistics* file does not necessarily use these column headers or data shape. Before importing it, map its exported columns to this normalized template in Excel or Power Query. Do not assume the importer recognizes native NWEA formats automatically. Grade/name matching alone is unsafe: use immutable, school-approved student IDs.

## E. What parents see

- Only student records permitted by the verified account's email in the `parent_students` table, enforced server-side by RLS.
- Subject-specific RIT histories and a simple trend chart.
- Achievement percentiles if imported.
- A basic latest-minus-earliest RIT change (not official NWEA conditional growth percentile or projected growth).
- Print / Save PDF through the browser.

## Production checklist

- Obtain school authorization and a privacy/legal review, including school data-protection notices and processor contracts relevant to Mexico and the school's policies.
- Ensure records are retained and deleted according to policy; implement account deactivation and access-removal procedures.
- Configure a custom domain, HTTPS, controlled parent invitations, verified email, MFA for staff, account recovery, backups, and audit logs as appropriate.
- Add a restricted invitation and account-lifecycle workflow before wider rollout. The prototype's self-service signup behavior is controlled by your Supabase Auth settings.
- Review who can mass-export/administer results, and periodically test all RLS policies. Prevent parent-link mistakes through a double-check process.
- Validate the actual MAP export format and NWEA permissions/usage requirements before using real reports.
- Consider restricting school staff to a dedicated administrative domain/interface and adding more granular administrator roles.
- Be aware that external CDN scripts load in the browser; self-host pinned library versions if required by school security policy.
