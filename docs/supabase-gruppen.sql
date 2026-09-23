-- Lerngruppen: private Rangliste für einen Meisterkurs, beitreten per Code
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen – NACH docs/supabase-rangliste.sql,
-- denn Gruppen zeigen Spitznamen und Kennzahlen aus der Rangliste. Die Datei
-- lässt sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Nur wer der Rangliste beigetreten ist, kann eine Gruppe gründen oder ihr
--   beitreten. Sichtbar ist in der Gruppe dasselbe wie in der Rangliste:
--   Spitzname, Prüfungsreife, Antworten dieser Woche, Lerntage in Folge.
-- * Beitritt nur mit dem 6-stelligen Code (ohne 0/O/1/I). Fehlversuche sind
--   gebremst (eine halbe Sekunde je Versuch).
-- * Höchstens 5 Gruppen je Person und 200 Mitglieder je Gruppe.
-- * Wer die Rangliste verlässt oder sein Konto löscht, verlässt auch alle
--   Gruppen. Die letzte Person einer Gruppe nimmt sie mit.
-- * Tabellen sind für Clients gesperrt; alles läuft über die Funktionen unten.
-- ----------------------------------------------------------------------------

create table if not exists public.gruppen (
  id         uuid        primary key default gen_random_uuid(),
  code       text        not null unique check (code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  name       text        not null check (length(name) between 3 and 40),
  owner      uuid        references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.gruppen_mitglieder (
  gruppe  uuid        not null references public.gruppen(id) on delete cascade,
  user_id uuid        not null references auth.users(id) on delete cascade,
  seit    timestamptz not null default now(),
  primary key (gruppe, user_id)
);
create index if not exists gruppen_mitglieder_user_idx on public.gruppen_mitglieder (user_id);
-- Fremdschlüssel auf auth.users: beim Löschen eines Kontos ohne Tabellen-Scan.
create index if not exists gruppen_owner_idx on public.gruppen (owner);

alter table public.gruppen enable row level security;
alter table public.gruppen_mitglieder enable row level security;
revoke all on table public.gruppen, public.gruppen_mitglieder from anon, authenticated;

-- Gruppe ohne Mitglieder löschen, sonst geht die Leitung an das dienstälteste
-- Mitglied, wenn die bisherige Leitung gegangen ist.
create or replace function public.gruppe_aufraeumen(p_gruppe uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.gruppen_mitglieder where gruppe = p_gruppe) then
    delete from public.gruppen where id = p_gruppe;
  else
    update public.gruppen g set owner = (
      select m.user_id from public.gruppen_mitglieder m where m.gruppe = p_gruppe order by m.seit, m.user_id limit 1)
    where g.id = p_gruppe
      and (g.owner is null or not exists (
        select 1 from public.gruppen_mitglieder m where m.gruppe = p_gruppe and m.user_id = g.owner));
  end if;
end;
$$;

-- Nach jedem Weggang aufräumen – egal ob durch Verlassen, Austritt aus der
-- Rangliste oder Kontolöschung (die Löschkaskaden laufen in beliebiger Folge).
create or replace function public.gruppen_mitglied_weg()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.gruppe_aufraeumen(old.gruppe);
  return old;
end;
$$;
drop trigger if exists gruppen_mitglied_weg on public.gruppen_mitglieder;
create trigger gruppen_mitglied_weg after delete on public.gruppen_mitglieder
  for each row execute function public.gruppen_mitglied_weg();

-- Wer die Rangliste verlässt (oder sein Konto löscht), verlässt alle Gruppen.
create or replace function public.gruppen_nach_austritt()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.gruppen_mitglieder where user_id = old.user_id;
  return old;
end;
$$;
drop trigger if exists gruppen_nach_austritt on public.rangliste;
create trigger gruppen_nach_austritt after delete on public.rangliste
  for each row execute function public.gruppen_nach_austritt();

-- Vorbedingung für alles: angemeldet und in der Rangliste.
create or replace function public.gruppen_pruefen()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  if not exists (select 1 from public.rangliste where user_id = auth.uid()) then
    raise exception 'erst der Rangliste beitreten' using errcode = 'P0003';
  end if;
end;
$$;

-- Gruppe gründen: Code wird ausgewürfelt, die Gründerin ist Mitglied und Leitung.
create or replace function public.gruppe_gruenden(p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_code text;
  v_id   uuid;
begin
  perform public.gruppen_pruefen();
  if length(v_name) < 3 or length(v_name) > 40 then
    raise exception 'Name 3–40 Zeichen' using errcode = '23514';
  end if;
  if (select count(*) from public.gruppen_mitglieder where user_id = auth.uid()) >= 5 then
    raise exception 'höchstens 5 Gruppen' using errcode = 'P0004';
  end if;
  loop
    select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
             get_byte(uuid_send(gen_random_uuid()), 0) % 32 + 1, 1), '')
      into v_code from generate_series(1, 6);
    exit when not exists (select 1 from public.gruppen where code = v_code);
  end loop;
  insert into public.gruppen (code, name, owner) values (v_code, v_name, auth.uid()) returning id into v_id;
  insert into public.gruppen_mitglieder (gruppe, user_id) values (v_id, auth.uid());
  return jsonb_build_object('id', v_id, 'code', v_code, 'name', v_name);
end;
$$;

-- Beitreten mit Code (Groß-/Kleinschreibung und Leerzeichen egal).
create or replace function public.gruppe_beitreten(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_g    public.gruppen%rowtype;
begin
  perform public.gruppen_pruefen();
  select * into v_g from public.gruppen where code = v_code;
  if not found then
    perform pg_sleep(0.5);
    raise exception 'Gruppe nicht gefunden' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.gruppen_mitglieder where gruppe = v_g.id and user_id = auth.uid()) then
    return jsonb_build_object('id', v_g.id, 'code', v_g.code, 'name', v_g.name);
  end if;
  if (select count(*) from public.gruppen_mitglieder where user_id = auth.uid()) >= 5 then
    raise exception 'höchstens 5 Gruppen' using errcode = 'P0004';
  end if;
  if (select count(*) from public.gruppen_mitglieder where gruppe = v_g.id) >= 200 then
    raise exception 'Gruppe voll' using errcode = 'P0005';
  end if;
  insert into public.gruppen_mitglieder (gruppe, user_id) values (v_g.id, auth.uid());
  return jsonb_build_object('id', v_g.id, 'code', v_g.code, 'name', v_g.name);
end;
$$;

-- Gruppe verlassen.
create or replace function public.gruppe_verlassen(p_gruppe uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  delete from public.gruppen_mitglieder where gruppe = p_gruppe and user_id = auth.uid();
end;
$$;

-- Eigene Gruppen mit Mitgliederzahl.
create or replace function public.gruppen_meine()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', g.id, 'code', g.code, 'name', g.name,
           'mitglieder', (select count(*) from public.gruppen_mitglieder m2
                          join public.rangliste r on r.user_id = m2.user_id
                          where m2.gruppe = g.id),
           'leitung', g.owner = auth.uid())
         order by m.seit), '[]'::jsonb)
  from public.gruppen_mitglieder m join public.gruppen g on g.id = m.gruppe
  where m.user_id = auth.uid();
$$;

-- Rangliste einer Gruppe – nur für ihre Mitglieder. Alle Mitglieder stehen
-- drin, auch ohne Antworten in dieser Woche (Antworten anderer Wochen zählen 0).
create or replace function public.gruppe_stand(p_gruppe uuid, p_woche text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with dabei as (
    select 1 from public.gruppen_mitglieder where gruppe = p_gruppe and user_id = auth.uid()
  ),
  liste as (
    select r.name, r.reife, r.serie, r.user_id,
           case when r.woche = p_woche then r.antworten else 0 end as antworten
    from public.gruppen_mitglieder m join public.rangliste r on r.user_id = m.user_id
    where m.gruppe = p_gruppe and exists (select 1 from dabei)
  )
  select case when not exists (select 1 from dabei) then null else jsonb_build_object(
    'id', g.id, 'name', g.name, 'code', g.code, 'leitung', g.owner = auth.uid(),
    'mitglieder', (select count(*) from liste),
    'liste', coalesce((
      select jsonb_agg(jsonb_build_object(
               'platz', platz, 'name', name, 'antworten', antworten, 'reife', reife,
               'serie', serie, 'ich', user_id = auth.uid())
             order by platz, name)
      from (select l.*, rank() over (order by antworten desc) as platz from liste l) t
    ), '[]'::jsonb)) end
  from public.gruppen g where g.id = p_gruppe;
$$;

-- Rechte: nur angemeldete Personen, Hilfsfunktionen gar nicht von außen.
revoke all on function public.gruppe_aufraeumen(uuid)          from public, anon, authenticated;
revoke all on function public.gruppen_nach_austritt()           from public, anon, authenticated;
revoke all on function public.gruppen_mitglied_weg()            from public, anon, authenticated;
revoke all on function public.gruppen_pruefen()                 from public, anon, authenticated;
revoke all on function public.gruppe_gruenden(text)             from public, anon, authenticated;
revoke all on function public.gruppe_beitreten(text)            from public, anon, authenticated;
revoke all on function public.gruppe_verlassen(uuid)            from public, anon, authenticated;
revoke all on function public.gruppen_meine()                   from public, anon, authenticated;
revoke all on function public.gruppe_stand(uuid, text)          from public, anon, authenticated;
grant execute on function public.gruppe_gruenden(text)          to authenticated;
grant execute on function public.gruppe_beitreten(text)         to authenticated;
grant execute on function public.gruppe_verlassen(uuid)         to authenticated;
grant execute on function public.gruppen_meine()                to authenticated;
grant execute on function public.gruppe_stand(uuid, text)       to authenticated;
