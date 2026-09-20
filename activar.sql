-- Pega SOLO esto en SQL Editor y dale Run.
-- Arregla "Conectando..." sin Nube activa.

create extension if not exists pgcrypto;

create table if not exists reventa_state (
  id int primary key default 1 check (id = 1),
  pin_hash text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table reventa_state enable row level security;
revoke all on table reventa_state from public, anon, authenticated;

create or replace function reventa_setup(p_pin text)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if length(trim(coalesce(p_pin,''))) < 4 then raise exception 'PIN_CORTO'; end if;
  if exists (select 1 from reventa_state where id = 1) then raise exception 'YA_EXISTE'; end if;
  insert into reventa_state (id, pin_hash, data) values (1, crypt(p_pin, gen_salt('bf')), '{}'::jsonb);
  return jsonb_build_object('ok', true);
end; $$;

create or replace function reventa_pull(p_pin text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare r reventa_state;
begin
  select * into r from reventa_state where id = 1;
  if not found then raise exception 'SIN_NUBE'; end if;
  if r.pin_hash <> crypt(p_pin, r.pin_hash) then raise exception 'PIN_MAL'; end if;
  return jsonb_build_object('data', r.data, 'updated_at', r.updated_at);
end; $$;

create or replace function reventa_push(p_pin text, p_data jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare ts timestamptz;
begin
  if length(trim(coalesce(p_pin,''))) < 4 then raise exception 'PIN_CORTO'; end if;
  if not exists (select 1 from reventa_state where id = 1) then
    insert into reventa_state (id, pin_hash, data)
    values (1, crypt(p_pin, gen_salt('bf')), coalesce(p_data,'{}'::jsonb))
    returning updated_at into ts;
    return jsonb_build_object('ok', true, 'updated_at', ts);
  end if;
  update reventa_state
    set data = coalesce(p_data,'{}'::jsonb), updated_at = now()
    where id = 1 and pin_hash = crypt(p_pin, pin_hash)
    returning updated_at into ts;
  if ts is null then raise exception 'PIN_MAL'; end if;
  return jsonb_build_object('ok', true, 'updated_at', ts);
end; $$;

notify pgrst, 'reload schema';

grant execute on function reventa_setup(text) to anon, authenticated;
grant execute on function reventa_pull(text) to anon, authenticated;
grant execute on function reventa_push(text, jsonb) to anon, authenticated;
