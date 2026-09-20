-- Pega esto entero en SQL Editor y dale Run.

grant usage on schema public to anon, authenticated;

create table if not exists reventa_box (
  pin text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table reventa_box enable row level security;

drop policy if exists reventa_box_all on reventa_box;
create policy reventa_box_all on reventa_box
  for all to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update on table reventa_box to anon, authenticated;

notify pgrst, 'reload schema';
