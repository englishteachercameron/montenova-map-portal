-- Run in Supabase SQL Editor. Do not publish real student information in GitHub.
create table if not exists public.map_results (
 id bigint generated always as identity primary key,
 student_id text not null,
 student_name text not null,
 grade text not null,
 subject text not null,
 term text not null,
 school_year text not null,
 rit numeric not null,
 percentile integer,
 test_date date,
 growth numeric,
 unique (student_id, subject, term, school_year)
);
create index if not exists map_results_student_idx on public.map_results(student_id);
create table if not exists public.parent_students (
 parent_email text not null,
 student_id text not null,
 primary key (parent_email, student_id),
 constraint parent_email_lowercase check (parent_email = lower(parent_email))
);
create index if not exists parent_students_student_idx on public.parent_students(student_id);
create table if not exists public.portal_admins (
 user_id uuid primary key references auth.users(id) on delete cascade
);
revoke all on public.portal_admins from anon, authenticated;
-- Keep administrator grants server-side only. The function can be called by authenticated users.
create or replace function public.is_portal_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.portal_admins a where a.user_id = (select auth.uid()));
$$;
revoke all on function public.is_portal_admin() from public;
grant execute on function public.is_portal_admin() to authenticated;
alter table public.map_results enable row level security;
alter table public.parent_students enable row level security;
alter table public.portal_admins enable row level security;
-- Email access is only safe with Supabase 'Confirm email' enabled and verified identity providers.
create policy "Parents see only linked results" on public.map_results for select to authenticated
using (public.is_portal_admin() or exists (
 select 1 from public.parent_students ps
 where ps.student_id = map_results.student_id
 and ps.parent_email = lower((select auth.jwt()->>'email'))
));
create policy "Admins insert results" on public.map_results for insert to authenticated with check (public.is_portal_admin());
create policy "Admins update results" on public.map_results for update to authenticated using (public.is_portal_admin()) with check (public.is_portal_admin());
create policy "Admins delete results" on public.map_results for delete to authenticated using (public.is_portal_admin());
create policy "Parents see their student links" on public.parent_students for select to authenticated
using (public.is_portal_admin() or parent_email = lower((select auth.jwt()->>'email')));
create policy "Admins insert links" on public.parent_students for insert to authenticated with check (public.is_portal_admin());
create policy "Admins update links" on public.parent_students for update to authenticated using (public.is_portal_admin()) with check (public.is_portal_admin());
create policy "Admins delete links" on public.parent_students for delete to authenticated using (public.is_portal_admin());
-- After creating an administrator account, run this in SQL Editor, replacing the email:
-- insert into public.portal_admins(user_id)
-- select id from auth.users where lower(email) = 'admin@your-school.edu'
-- on conflict do nothing;
