-- شغّل هذا الملف في Supabase SQL Editor بعد إنشاء مستخدم التطبيق.
-- التطبيق يستخدم Publishable/anon key + Supabase Auth.
-- لا يحتاج مفتاح إداري.

alter table public.transactions enable row level security;
alter table public.merchants enable row level security;
alter table public.merchant_ledger enable row level security;

-- المبيعات: التطبيق للقراءة فقط.
drop policy if exists "android_read_transactions" on public.transactions;
create policy "android_read_transactions"
on public.transactions
for select
to authenticated
using (true);

-- التجار: قراءة وإضافة.
drop policy if exists "android_read_merchants" on public.merchants;
create policy "android_read_merchants"
on public.merchants
for select
to authenticated
using (true);

drop policy if exists "android_insert_merchants" on public.merchants;
create policy "android_insert_merchants"
on public.merchants
for insert
to authenticated
with check (true);

-- دفتر التجار: قراءة / إضافة / تعديل / حذف.
drop policy if exists "android_read_merchant_ledger" on public.merchant_ledger;
create policy "android_read_merchant_ledger"
on public.merchant_ledger
for select
to authenticated
using (true);

drop policy if exists "android_insert_merchant_ledger" on public.merchant_ledger;
create policy "android_insert_merchant_ledger"
on public.merchant_ledger
for insert
to authenticated
with check (true);

drop policy if exists "android_update_merchant_ledger" on public.merchant_ledger;
create policy "android_update_merchant_ledger"
on public.merchant_ledger
for update
to authenticated
using (true)
with check (true);

drop policy if exists "android_delete_merchant_ledger" on public.merchant_ledger;
create policy "android_delete_merchant_ledger"
on public.merchant_ledger
for delete
to authenticated
using (true);
