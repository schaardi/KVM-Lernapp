-- KI-Auswertung der Original-Prüfungen (Claude Sonnet 5.5)
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen, und zwar nach
-- docs/supabase-profile.sql (Admins) und docs/supabase-pruefungen-freigabe.sql
-- (Freigabe). Die Datei lässt sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Ausgewertet wird in der Edge Function „pruefung-auswerten“
--   (supabase/functions/pruefung-auswerten). Nur sie kennt den API-Key – als
--   Secret ANTHROPIC_API_KEY – und nur sie ruft Claude auf, immer mit dem
--   Modell claude-sonnet-5-5.
-- * Eine Auswertung ist eine abgegebene Prüfung. Bewertet wird sie Aufgabe für
--   Aufgabe (je ein Aufruf), gezählt wird sie einmal.
-- * Auswerten dürfen alle, die für die Prüfungen freigegeben sind: höchstens
--   ki_tageslimit() Auswertungen je Kalendertag (Europe/Berlin), Admins ohne
--   Limit. Eine Auswertung, bei der keine einzige Aufgabe bewertet wurde,
--   zählt nicht, sobald sie abgelaufen ist (ki_frist(), 30 Minuten).
-- * Gespeichert wird nur, wer wann welche Prüfung hat auswerten lassen, mit
--   Punkten je Aufgabe und Tokens – keine Antworten.
-- * Die Tabelle ist für Clients gesperrt. Beginnen und Eintragen darf nur die
--   Edge Function (service_role); die App fragt ki_status() ab, Admins sehen
--   die Nutzung über admin_ki_auswertungen().
-- * Wer sein Konto löscht, verliert die Einträge (on delete cascade).
-- ----------------------------------------------------------------------------

create table if not exists public.ki_auswertungen (
  id       bigint      generated always as identity primary key,
  user_id  uuid        not null references auth.users(id) on delete cascade,
  pruefung text        not null check (pruefung ~ '^P-[A-Z]+-[0-9]{8}$'),
  -- laeuft: Aufgaben werden bewertet; ok: alle bewertet; teilweise: abgelaufen
  -- mit bewerteten Aufgaben; fehler: abgelaufen ohne eine bewertete Aufgabe
  status   text        not null default 'laeuft'
                       check (status in ('laeuft', 'ok', 'teilweise', 'fehler')),
  anzahl   integer     not null check (anzahl between 1 and 99),  -- Aufgaben der Prüfung
  aufgaben jsonb       not null default '{}'::jsonb,  -- {"Nr.": {"p": Punkte, "m": Höchstpunkte}}
  aufrufe  integer     not null default 0,            -- Aufrufe bei Claude
  modell   text        not null default '',
  eingabe  integer     not null default 0,            -- Eingabe-Tokens
  ausgabe  integer     not null default 0,            -- Ausgabe-Tokens
  punkte   integer,
  max      integer,
  fehler   text        not null default '' check (length(fehler) <= 300),  -- letzter Fehler
  erstellt timestamptz not null default now(),
  fertig   timestamptz
);
create index if not exists ki_auswertungen_user_idx on public.ki_auswertungen (user_id, erstellt desc);
create index if not exists ki_auswertungen_erstellt_idx on public.ki_auswertungen (erstellt desc);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.ki_auswertungen enable row level security;
revoke all on table public.ki_auswertungen from anon, authenticated;

-- Auswertungen je Person und Kalendertag. Zum Ändern einfach neu anlegen.
create or replace function public.ki_tageslimit()
returns integer
language sql
immutable
set search_path = ''
as $$ select 5 $$;

-- So lange darf eine Auswertung laufen.
create or replace function public.ki_frist()
returns interval
language sql
immutable
set search_path = ''
as $$ select interval '30 minutes' $$;

-- Heute gezählte Auswertungen einer Person: fertige, abgelaufene mit
-- bewerteten Aufgaben und laufende.
create or replace function public.ki_heute(p_user uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer from public.ki_auswertungen
  where user_id = p_user
    and (status in ('ok', 'teilweise')
         or (status = 'laeuft' and (aufgaben <> '{}'::jsonb or erstellt > now() - public.ki_frist())))
    and (erstellt at time zone 'Europe/Berlin')::date = (now() at time zone 'Europe/Berlin')::date;
$$;

-- Stand für die App: darf ich auswerten, wie viele heute schon?
create or replace function public.ki_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ich   uuid := auth.uid();
  v_admin boolean;
begin
  if v_ich is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  v_admin := exists (select 1 from public.admins where user_id = v_ich);
  return jsonb_build_object(
    'erlaubt', v_admin or exists (select 1 from public.pruefungen_freigaben
                                  where user_id = v_ich and status = 'frei'),
    'admin',   v_admin,
    'heute',   public.ki_heute(v_ich),
    'limit',   case when v_admin then null else public.ki_tageslimit() end);
end;
$$;

-- ----------------------------------------------------------------------------
-- Nur für die Edge Function (service_role)
-- ----------------------------------------------------------------------------

-- Beginnen: prüft die Freigabe, schließt abgelaufene Auswertungen ab und setzt
-- eine laufende Auswertung derselben Prüfung fort; sonst prüft es das
-- Tageslimit und legt eine neue an. Je Person nacheinander (Sperre), damit
-- gleichzeitige Aufrufe das Limit nicht überlisten.
create or replace function public.ki_beginnen(p_user uuid, p_pruefung text, p_anzahl integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin boolean;
  v_lauf  public.ki_auswertungen%rowtype;
  v_n     integer;
  v_limit integer;
  v_id    bigint;
begin
  if p_user is null or p_pruefung is null or p_pruefung !~ '^P-[A-Z]+-[0-9]{8}$'
     or p_anzahl is null or p_anzahl not between 1 and 99 then
    raise exception 'ungültige Anfrage' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('ki_auswertung:' || p_user::text, 0));
  v_admin := exists (select 1 from public.admins where user_id = p_user);
  if not v_admin and not exists (select 1 from public.pruefungen_freigaben
                                 where user_id = p_user and status = 'frei') then
    return jsonb_build_object('ok', false, 'grund', 'keine_freigabe');
  end if;
  v_limit := case when v_admin then null else public.ki_tageslimit() end;

  update public.ki_auswertungen
     set status = case when aufgaben = '{}'::jsonb then 'fehler' else 'teilweise' end,
         fehler = case when aufgaben = '{}'::jsonb and fehler = '' then 'abgebrochen' else fehler end,
         fertig = now()
   where user_id = p_user and status = 'laeuft' and erstellt < now() - public.ki_frist();

  select * into v_lauf from public.ki_auswertungen
   where user_id = p_user and pruefung = p_pruefung and status = 'laeuft'
   order by erstellt desc limit 1;
  v_n := public.ki_heute(p_user);
  if v_lauf.id is not null then
    return jsonb_build_object('ok', true, 'id', v_lauf.id, 'neu', false,
                              'aufgaben', v_lauf.aufgaben, 'heute', v_n, 'limit', v_limit);
  end if;
  if not v_admin and v_n >= v_limit then
    return jsonb_build_object('ok', false, 'grund', 'limit', 'heute', v_n, 'limit', v_limit);
  end if;
  insert into public.ki_auswertungen (user_id, pruefung, anzahl)
  values (p_user, p_pruefung, p_anzahl)
  returning id into v_id;
  return jsonb_build_object('ok', true, 'id', v_id, 'neu', true,
                            'aufgaben', '{}'::jsonb, 'heute', v_n + 1, 'limit', v_limit);
end;
$$;

-- Vor jedem Aufruf bei Claude: gehört die Auswertung dieser Person und
-- Prüfung, läuft sie noch, gilt die Freigabe noch? Höchstens drei Aufrufe je
-- Aufgabe (Wiederholungen nach Fehlern eingerechnet).
create or replace function public.ki_aufruf(p_id bigint, p_user uuid, p_pruefung text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lauf public.ki_auswertungen%rowtype;
begin
  if p_id is null or p_user is null or p_pruefung is null then
    raise exception 'ungültige Anfrage' using errcode = '22023';
  end if;
  select * into v_lauf from public.ki_auswertungen
   where id = p_id and user_id = p_user and pruefung = p_pruefung
   for update;
  if v_lauf.id is null then
    return jsonb_build_object('ok', false, 'grund', 'unbekannt');
  end if;
  if v_lauf.status <> 'laeuft' or v_lauf.erstellt < now() - public.ki_frist() then
    return jsonb_build_object('ok', false, 'grund', 'abgelaufen');
  end if;
  if not exists (select 1 from public.admins where user_id = p_user)
     and not exists (select 1 from public.pruefungen_freigaben
                     where user_id = p_user and status = 'frei') then
    return jsonb_build_object('ok', false, 'grund', 'keine_freigabe');
  end if;
  if v_lauf.aufrufe >= v_lauf.anzahl * 3 then
    return jsonb_build_object('ok', false, 'grund', 'zu_viele');
  end if;
  update public.ki_auswertungen set aufrufe = aufrufe + 1 where id = p_id;
  return jsonb_build_object('ok', true);
end;
$$;

-- Ergebnis einer Aufgabe eintragen. Sind alle Aufgaben bewertet, ist die
-- Auswertung fertig.
create or replace function public.ki_aufgabe(p_id bigint, p_nr integer, p_punkte integer, p_max integer,
                                            p_modell text, p_eingabe integer, p_ausgabe integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lauf     public.ki_auswertungen%rowtype;
  v_aufgaben jsonb;
  v_fertig   boolean;
  v_punkte   integer;
  v_max      integer;
begin
  if p_id is null or p_nr is null or p_nr not between 1 and 99 or p_punkte is null or p_max is null
     or p_punkte < 0 or p_max < 0 or p_punkte > p_max then
    raise exception 'ungültige Anfrage' using errcode = '22023';
  end if;
  select * into v_lauf from public.ki_auswertungen where id = p_id for update;
  if v_lauf.id is null or v_lauf.status <> 'laeuft' then
    return jsonb_build_object('ok', false);
  end if;
  v_aufgaben := v_lauf.aufgaben || jsonb_build_object(p_nr::text, jsonb_build_object('p', p_punkte, 'm', p_max));
  select count(*) >= v_lauf.anzahl, sum((e.value->>'p')::integer), sum((e.value->>'m')::integer)
    into v_fertig, v_punkte, v_max
    from jsonb_each(v_aufgaben) e;
  update public.ki_auswertungen
     set aufgaben = v_aufgaben,
         modell   = left(coalesce(p_modell, ''), 60),
         eingabe  = eingabe + greatest(coalesce(p_eingabe, 0), 0),
         ausgabe  = ausgabe + greatest(coalesce(p_ausgabe, 0), 0),
         punkte   = v_punkte,
         max      = v_max,
         status   = case when v_fertig then 'ok' else status end,
         fertig   = case when v_fertig then now() else fertig end
   where id = p_id;
  return jsonb_build_object('ok', true, 'fertig', v_fertig, 'punkte', v_punkte, 'max', v_max);
end;
$$;

-- Fehlgeschlagener Aufruf: Fehler und verbrauchte Tokens festhalten. Die
-- Auswertung läuft weiter, die Aufgabe lässt sich wiederholen.
create or replace function public.ki_fehlschlag(p_id bigint, p_eingabe integer, p_ausgabe integer, p_fehler text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.ki_auswertungen
     set eingabe = eingabe + greatest(coalesce(p_eingabe, 0), 0),
         ausgabe = ausgabe + greatest(coalesce(p_ausgabe, 0), 0),
         fehler  = left(coalesce(p_fehler, ''), 300)
   where id = p_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Verwaltung
-- ----------------------------------------------------------------------------

-- Nutzung: Summen (heute, 7 und 30 Tage, Tokens der letzten 30 Tage) und die
-- letzten 50 Auswertungen mit Konto.
create or replace function public.admin_ki_auswertungen()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_heute date := (now() at time zone 'Europe/Berlin')::date;
begin
  perform public.admin_pruefen();
  return jsonb_build_object(
    'summen', (select jsonb_build_object(
        'heute',     count(*) filter (where status in ('ok', 'teilweise', 'laeuft') and aufgaben <> '{}'::jsonb
                                        and (erstellt at time zone 'Europe/Berlin')::date = v_heute),
        'tage7',     count(*) filter (where status in ('ok', 'teilweise') and erstellt > now() - interval '7 days'),
        'tage30',    count(*) filter (where status in ('ok', 'teilweise') and erstellt > now() - interval '30 days'),
        'fehler30',  count(*) filter (where status = 'fehler' and erstellt > now() - interval '30 days'),
        'eingabe30', coalesce(sum(eingabe) filter (where erstellt > now() - interval '30 days'), 0),
        'ausgabe30', coalesce(sum(ausgabe) filter (where erstellt > now() - interval '30 days'), 0))
      from public.ki_auswertungen),
    'limit', public.ki_tageslimit(),
    'letzte', coalesce((
      select jsonb_agg(x.j order by x.erstellt desc)
      from (
        select k.erstellt,
               jsonb_build_object(
                 'pruefung', k.pruefung,
                 'status',   case when k.status = 'laeuft' and k.erstellt < now() - public.ki_frist()
                                  then case when k.aufgaben = '{}'::jsonb then 'fehler' else 'teilweise' end
                                  else k.status end,
                 'bewertet', (select count(*) from jsonb_object_keys(k.aufgaben)),
                 'anzahl',   k.anzahl,
                 'punkte',   k.punkte,
                 'max',      k.max,
                 'eingabe',  k.eingabe,
                 'ausgabe',  k.ausgabe,
                 'fehler',   k.fehler,
                 'erstellt', k.erstellt,
                 'email',    u.email,
                 'name',     coalesce(nullif(u.raw_user_meta_data->>'full_name', ''),
                                      nullif(u.raw_user_meta_data->>'name', ''))) as j
        from public.ki_auswertungen k
        join auth.users u on u.id = k.user_id
        order by k.erstellt desc
        limit 50) x), '[]'::jsonb));
end;
$$;

-- Rechte: ki_status und die Übersicht für angemeldete Personen, alles andere
-- nur für die Edge Function.
revoke all on function public.ki_heute(uuid)                          from public, anon, authenticated;
revoke all on function public.ki_status()                             from public, anon, authenticated;
revoke all on function public.ki_beginnen(uuid, text, integer)        from public, anon, authenticated;
revoke all on function public.ki_aufruf(bigint, uuid, text)           from public, anon, authenticated;
revoke all on function public.ki_aufgabe(bigint, integer, integer, integer, text, integer, integer)
                                                                      from public, anon, authenticated;
revoke all on function public.ki_fehlschlag(bigint, integer, integer, text)
                                                                      from public, anon, authenticated;
revoke all on function public.admin_ki_auswertungen()                 from public, anon, authenticated;
grant execute on function public.ki_status()                          to authenticated;
grant execute on function public.admin_ki_auswertungen()              to authenticated;
grant execute on function public.ki_beginnen(uuid, text, integer)     to service_role;
grant execute on function public.ki_aufruf(bigint, uuid, text)        to service_role;
grant execute on function public.ki_aufgabe(bigint, integer, integer, integer, text, integer, integer)
                                                                      to service_role;
grant execute on function public.ki_fehlschlag(bigint, integer, integer, text)
                                                                      to service_role;
