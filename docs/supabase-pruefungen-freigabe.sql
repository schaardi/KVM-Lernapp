-- Original-IHK-Prüfungen nur mit Freigabe
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen, und zwar nach
-- docs/supabase-profile.sql (Admins und Protokoll der Verwaltung). Die Datei
-- lässt sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Die Original-Prüfungen – Aufgaben, amtliche Lösungshinweise und
--   Bildanlagen – stehen nicht im Repository. Sie liegen nur im privaten
--   Storage-Bucket „pruefungen“:
--     pruefungen.json   {"pruefungen": [Prüfungen im Format von data/cases.js],
--                        "anlagen":    {"<Schlüssel>": {"f": Datei, "w", "h", "t": Titel}}}
--     anlagen/<Datei>   die Bilder zu den Anlagen
-- * Lesen dürfen nur freigegebene Personen und Admins. Die Freigabe fragt man
--   in der App an (Seite „Prüfungen“); ein Admin gibt in der Verwaltung frei,
--   lehnt ab oder nimmt sie zurück. Jede Entscheidung steht im Protokoll der
--   Verwaltung.
-- * Hochladen, Ersetzen und Löschen im Bucket dürfen nur Admins – in der App
--   (Verwaltung › Prüfungen) oder im Supabase-Dashboard unter Storage.
-- * Die Tabelle ist für Clients gesperrt; alles läuft über die Funktionen
--   unten. Den Bucket schützen die Storage-Policies am Ende.
-- * Wer sein Konto löscht, verliert die Freigabe (on delete cascade).
--
-- Vorab freigeben, ohne dass die Person angefragt hat (im SQL-Editor):
--   insert into public.pruefungen_freigaben (user_id, status, entschieden)
--   select id, 'frei', now() from auth.users where email = 'name@example.com'
--   on conflict (user_id) do update set status = 'frei', entschieden = now();
-- ----------------------------------------------------------------------------

create table if not exists public.pruefungen_freigaben (
  user_id     uuid        primary key references auth.users(id) on delete cascade,
  status      text        not null default 'angefragt'
                          check (status in ('angefragt', 'frei', 'abgelehnt')),
  nachricht   text        not null default '' check (length(nachricht) <= 300),
  angefragt   timestamptz,                                   -- letzte Anfrage
  entschieden timestamptz,                                   -- letzte Entscheidung
  von         uuid        references auth.users(id) on delete set null   -- durch (Admin)
);
create index if not exists pruefungen_freigaben_status_idx on public.pruefungen_freigaben (status);
create index if not exists pruefungen_freigaben_von_idx on public.pruefungen_freigaben (von);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.pruefungen_freigaben enable row level security;
revoke all on table public.pruefungen_freigaben from anon, authenticated;

-- Privater Bucket für die Prüfungsdaten. War er schon da (etwa im Dashboard
-- angelegt), wird er hier privat gestellt.
insert into storage.buckets (id, name, public, file_size_limit)
values ('pruefungen', 'pruefungen', false, 20971520)
on conflict (id) do update set public = false;

-- ----------------------------------------------------------------------------
-- Zugang
-- ----------------------------------------------------------------------------

-- Darf die angemeldete Person die Prüfungen lesen? Admin oder freigegeben.
-- Auch für angemeldete Personen aufrufbar (die Storage-Policy braucht das) –
-- verrät nur den eigenen Zugang.
create or replace function public.pruefungen_zugang()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and (
    exists (select 1 from public.admins a where a.user_id = auth.uid())
    or exists (select 1 from public.pruefungen_freigaben f
               where f.user_id = auth.uid() and f.status = 'frei'));
$$;

-- Stand für die App: Freigabe und, mit Freigabe, wann pruefungen.json zuletzt
-- hochgeladen wurde (stand) – daran erkennt die App, ob ihre Kopie aktuell ist.
-- Admins erfahren zusätzlich, wie viele Anfragen offen sind.
create or replace function public.pruefungen_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ich   uuid := auth.uid();
  v_admin boolean;
  f       record;
  v_frei  boolean;
begin
  if v_ich is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  v_admin := exists (select 1 from public.admins where user_id = v_ich);
  select status, nachricht, angefragt, entschieden into f
    from public.pruefungen_freigaben where user_id = v_ich;
  v_frei := v_admin or coalesce(f.status = 'frei', false);
  return jsonb_build_object(
    'status',      case when v_frei then 'frei' else coalesce(f.status, 'keine') end,
    'admin',       v_admin,
    'nachricht',   coalesce(f.nachricht, ''),
    'angefragt',   f.angefragt,
    'entschieden', f.entschieden,
    'stand',       case when v_frei then
                     (select o.updated_at from storage.objects o
                      where o.bucket_id = 'pruefungen' and o.name = 'pruefungen.json') end,
    'offen',       case when v_admin then
                     (select count(*) from public.pruefungen_freigaben where status = 'angefragt') end);
end;
$$;

-- Freigabe anfragen, mit kurzer Nachricht an die Admins (höchstens 300
-- Zeichen). Wer schon freigegeben ist oder Admin ist, bleibt es; nach einer
-- Ablehnung lässt sich erneut anfragen.
create or replace function public.pruefungen_anfragen(p_nachricht text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ich  uuid := auth.uid();
  v_text text := left(btrim(regexp_replace(coalesce(p_nachricht, ''), '\s+', ' ', 'g')), 300);
begin
  if v_ich is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  if not exists (select 1 from public.admins where user_id = v_ich) then
    insert into public.pruefungen_freigaben as f (user_id, status, nachricht, angefragt)
    values (v_ich, 'angefragt', v_text, now())
    on conflict (user_id) do update
      set status      = 'angefragt',
          nachricht   = excluded.nachricht,
          angefragt   = case when f.status = 'angefragt' then f.angefragt else now() end,
          entschieden = null,
          von         = null
      where f.status <> 'frei';
  end if;
  return public.pruefungen_status();
end;
$$;

-- ----------------------------------------------------------------------------
-- Verwaltung – jede Funktion prüft zuerst, ob ein Admin angemeldet ist.
-- ----------------------------------------------------------------------------

-- Anfragen und Freigaben: offene zuerst, dann freigegebene, dann abgelehnte,
-- jeweils neueste zuerst (höchstens 500). Dazu der Stand der Prüfungsdaten im
-- Bucket.
create or replace function public.admin_pruefungen()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.admin_pruefen();
  return jsonb_build_object(
    'liste', coalesce((
      select jsonb_agg(x.j order by x.rang, x.zeit desc nulls last)
      from (
        select case f.status when 'angefragt' then 0 when 'frei' then 1 else 2 end as rang,
               coalesce(f.entschieden, f.angefragt) as zeit,
               jsonb_build_object(
                 'id',          f.user_id,
                 'status',      f.status,
                 'nachricht',   f.nachricht,
                 'angefragt',   f.angefragt,
                 'entschieden', f.entschieden,
                 'email',       u.email,
                 'name',        coalesce(nullif(u.raw_user_meta_data->>'full_name', ''),
                                         nullif(u.raw_user_meta_data->>'name', ''))) as j
        from public.pruefungen_freigaben f
        join auth.users u on u.id = f.user_id
        order by rang, zeit desc nulls last
        limit 500) x), '[]'::jsonb),
    'zaehler', jsonb_build_object(
      'angefragt', (select count(*) from public.pruefungen_freigaben where status = 'angefragt'),
      'frei',      (select count(*) from public.pruefungen_freigaben where status = 'frei'),
      'abgelehnt', (select count(*) from public.pruefungen_freigaben where status = 'abgelehnt')),
    'datei', (select jsonb_build_object('stand', o.updated_at,
                                        'groesse', nullif(o.metadata->>'size', '')::bigint)
              from storage.objects o
              where o.bucket_id = 'pruefungen' and o.name = 'pruefungen.json'),
    'bilder', (select count(*) from storage.objects o
               where o.bucket_id = 'pruefungen' and o.name like 'anlagen/%'));
end;
$$;

-- Entscheiden: 'frei' gibt frei, 'abgelehnt' lehnt ab bzw. nimmt eine
-- Freigabe zurück, null löscht den Eintrag (die Person kann neu anfragen).
-- Freigeben geht auch ohne Anfrage.
create or replace function public.admin_pruefungen_freigabe(p_user uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_alt text;
begin
  perform public.admin_pruefen();
  if p_status is not null and p_status not in ('frei', 'abgelehnt') then
    raise exception 'unbekannter Status' using errcode = '22023';
  end if;
  if not exists (select 1 from auth.users where id = p_user) then
    raise exception 'Konto nicht gefunden' using errcode = 'P0002';
  end if;
  select status into v_alt from public.pruefungen_freigaben where user_id = p_user;
  if p_status is null then
    delete from public.pruefungen_freigaben where user_id = p_user;
  else
    insert into public.pruefungen_freigaben as f (user_id, status, entschieden, von)
    values (p_user, p_status, now(), auth.uid())
    on conflict (user_id) do update
      set status = excluded.status, entschieden = now(), von = auth.uid();
  end if;
  perform public.admin_merken(
    case p_status when 'frei' then 'pruefungen_frei'
                  when 'abgelehnt' then case when v_alt = 'frei' then 'pruefungen_entzogen'
                                             else 'pruefungen_abgelehnt' end
                  else 'pruefungen_geloescht' end,
    p_user, jsonb_build_object('vorher', coalesce(v_alt, 'keine')));
end;
$$;

-- Rechte: nur angemeldete Personen.
revoke all on function public.pruefungen_zugang()                       from public, anon, authenticated;
revoke all on function public.pruefungen_status()                       from public, anon, authenticated;
revoke all on function public.pruefungen_anfragen(text)                 from public, anon, authenticated;
revoke all on function public.admin_pruefungen()                        from public, anon, authenticated;
revoke all on function public.admin_pruefungen_freigabe(uuid, text)     from public, anon, authenticated;
grant execute on function public.pruefungen_zugang()                    to authenticated;
grant execute on function public.pruefungen_status()                    to authenticated;
grant execute on function public.pruefungen_anfragen(text)              to authenticated;
grant execute on function public.admin_pruefungen()                     to authenticated;
grant execute on function public.admin_pruefungen_freigabe(uuid, text)  to authenticated;

-- ----------------------------------------------------------------------------
-- Storage: Lesen mit Freigabe, Schreiben nur für Admins. Überschreiben
-- (upsert) braucht Lesen, Anlegen und Ändern.
-- ----------------------------------------------------------------------------
drop policy if exists "pruefungen: lesen mit Freigabe" on storage.objects;
create policy "pruefungen: lesen mit Freigabe" on storage.objects
  for select to authenticated
  using (bucket_id = 'pruefungen' and public.pruefungen_zugang());

drop policy if exists "pruefungen: Admins laden hoch" on storage.objects;
create policy "pruefungen: Admins laden hoch" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'pruefungen' and public.ist_admin());

drop policy if exists "pruefungen: Admins ersetzen" on storage.objects;
create policy "pruefungen: Admins ersetzen" on storage.objects
  for update to authenticated
  using (bucket_id = 'pruefungen' and public.ist_admin())
  with check (bucket_id = 'pruefungen' and public.ist_admin());

drop policy if exists "pruefungen: Admins löschen" on storage.objects;
create policy "pruefungen: Admins löschen" on storage.objects
  for delete to authenticated
  using (bucket_id = 'pruefungen' and public.ist_admin());
