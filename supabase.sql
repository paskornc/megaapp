-- ตารางซิงก์ของ "สมุดลูกหนี้"
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query → วางทั้งหมดนี้ → Run

create table if not exists public.recs (
  uid        uuid        not null default auth.uid(),
  tbl        text        not null,
  id         text        not null,
  body       jsonb,                     -- null = ถูกลบ (tombstone)
  updated_at timestamptz not null default now(),
  primary key (uid, tbl, id)
);

create index if not exists recs_uid_updated_idx on public.recs (uid, updated_at);

-- ให้ updated_at เปลี่ยนเองทุกครั้งที่มีการแก้ เพื่อให้อีกเครื่องดึงเฉพาะแถวที่เปลี่ยน
create or replace function public.recs_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists recs_touch_trg on public.recs;
create trigger recs_touch_trg before update on public.recs
for each row execute function public.recs_touch();

-- ความปลอดภัย: แต่ละคนเห็น/แก้ได้เฉพาะแถวของตัวเอง
alter table public.recs enable row level security;

drop policy if exists recs_own on public.recs;
create policy recs_own on public.recs
  for all
  using (auth.uid() = uid)
  with check (auth.uid() = uid);

grant select, insert, update, delete on public.recs to authenticated;
