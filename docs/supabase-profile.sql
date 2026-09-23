-- Profile, Freunde und Verwaltung (Admin)
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen – NACH docs/supabase-rangliste.sql,
-- denn Profile bauen auf dem Spitznamen der Rangliste auf. Lerngruppen und
-- Meldungen sind keine Voraussetzung. Fehlen sie, bleiben die Admin-Reiter
-- dafür leer. Die Datei lässt sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Ein Profil hat nur, wer der Rangliste beigetreten ist. Alle Teilnehmenden
--   sehen wie in der Rangliste: Spitzname, Prüfungsreife, Antworten dieser
--   Woche, Lerntage in Folge.
-- * Den Lernstand im Detail (je Fach, Aktivität der letzten 14 Tage, Prüfungen
--   unter Echtbedingungen) sehen nur Freunde. Wer mag, stellt sein Profil
--   auf „alle“.
-- * Freundschaft braucht Anfrage und Annahme. Abgelehnt wird still: Die
--   anfragende Person sieht weiter „angefragt“ und kann nicht erneut drängeln.
-- * Wer die Rangliste verlässt oder sein Konto löscht, verliert Profil und
--   Freundschaften.
-- * Admins (Tabelle admins) sehen und verwalten alles: Konten, Lernstand,
--   Profile, Gruppen, Meldungen. Jede Verwaltungsaktion landet im Protokoll.
-- * Tabellen sind für Clients gesperrt; alles läuft über die Funktionen unten.
--
-- Admin eintragen (einmal, mit der E-Mail des Google-Kontos, das sich schon
-- einmal angemeldet hat):
--   insert into public.admins (user_id)
--   select id from auth.users where lower(email) = lower('name@example.com')
--   on conflict do nothing;
-- ----------------------------------------------------------------------------

-- Profil je Teilnehmer*in. pid ist die öffentliche Kennung – die Konto-ID
-- verlässt die Datenbank nicht.
create table if not exists public.profile (
  user_id      uuid        primary key references public.rangliste(user_id) on delete cascade,
  pid          uuid        not null unique default gen_random_uuid(),
  sichtbarkeit text        not null default 'freunde' check (sichtbarkeit in ('freunde', 'alle')),
  details      jsonb       not null default '{}'::jsonb,
  details_am   timestamptz,
  seit         timestamptz not null default now(),
  anfragen_tag date,
  anfragen_n   integer     not null default 0
);

-- Freundschaften: eine Zeile je Paar. status 'offen' = Anfrage von „von“ an
-- „an“; 'abgelehnt' = still abgelehnt; versteckt = die anfragende Person hat
-- eine (still abgelehnte) Anfrage zurückgezogen.
create table if not exists public.freunde (
  von       uuid        not null references public.rangliste(user_id) on delete cascade,
  an        uuid        not null references public.rangliste(user_id) on delete cascade,
  status    text        not null default 'offen' check (status in ('offen', 'freunde', 'abgelehnt')),
  versteckt boolean     not null default false,
  seit      timestamptz not null default now(),
  primary key (von, an),
  check (von <> an)
);
create unique index if not exists freunde_paar_idx on public.freunde (least(von, an), greatest(von, an));
create index if not exists freunde_an_idx on public.freunde (an);

create table if not exists public.admins (
  user_id uuid        primary key references auth.users(id) on delete cascade,
  seit    timestamptz not null default now()
);

-- Gesperrt für Rangliste, Profil, Freunde und Gruppen. Lernen und Sichern
-- bleiben möglich.
create table if not exists public.gesperrt (
  user_id uuid        primary key references auth.users(id) on delete cascade,
  grund   text        not null default '' check (length(grund) <= 300),
  seit    timestamptz not null default now(),
  von     uuid        references auth.users(id) on delete set null
);
create index if not exists gesperrt_von_idx on public.gesperrt (von);

create table if not exists public.admin_protokoll (
  id      bigint      generated always as identity primary key,
  admin   uuid        references auth.users(id) on delete set null,
  aktion  text        not null,
  ziel    uuid,
  details jsonb       not null default '{}'::jsonb,
  zeit    timestamptz not null default now()
);
create index if not exists admin_protokoll_admin_idx on public.admin_protokoll (admin);
create index if not exists admin_protokoll_zeit_idx on public.admin_protokoll (zeit desc);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.profile enable row level security;
alter table public.freunde enable row level security;
alter table public.admins enable row level security;
alter table public.gesperrt enable row level security;
alter table public.admin_protokoll enable row level security;
revoke all on table public.profile, public.freunde, public.admins, public.gesperrt, public.admin_protokoll
  from anon, authenticated;

-- Jede Person in der Rangliste bekommt ein Profil – auch alle, die schon dabei sind.
create or replace function public.profil_anlegen()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profile (user_id) values (new.user_id) on conflict (user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists profil_anlegen on public.rangliste;
create trigger profil_anlegen after insert on public.rangliste
  for each row execute function public.profil_anlegen();
insert into public.profile (user_id) select user_id from public.rangliste on conflict (user_id) do nothing;

-- Gesperrte Konten können der Rangliste nicht (wieder) beitreten.
create or replace function public.rangliste_sperre()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.gesperrt where user_id = new.user_id) then
    raise exception 'Konto gesperrt' using errcode = 'P0006';
  end if;
  return new;
end;
$$;
drop trigger if exists rangliste_sperre on public.rangliste;
create trigger rangliste_sperre before insert or update on public.rangliste
  for each row execute function public.rangliste_sperre();

-- Zahl aus JSON, auf einen Bereich begrenzt (sonst null).
create or replace function public.profil_zahl(j jsonb, lo integer, hi integer)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case when jsonb_typeof(j) = 'number'
              then least(greatest(round(j::numeric), lo), hi)::integer end;
$$;

-- Details säubern: nur bekannte Felder, nur Zahlen, begrenzt.
--   f     je Fach 1–5: r = Reife in %, m = gemeistert, g = gesehen, n = Fragen
--   t14   Antworten je Tag, die letzten 14 Tage (ältester zuerst)
--   tage  Lerntage in den letzten 120 Tagen
--   echt  Prüfungen unter Echtbedingungen: n = Anzahl, best = bestes Ergebnis in %
create or replace function public.profil_details_saeubern(p jsonb)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'f', (select jsonb_object_agg(k, jsonb_build_object(
                   'r', public.profil_zahl(p->'f'->k->'r', 0, 100),
                   'm', public.profil_zahl(p->'f'->k->'m', 0, 100000),
                   'g', public.profil_zahl(p->'f'->k->'g', 0, 100000),
                   'n', public.profil_zahl(p->'f'->k->'n', 0, 100000)))
          from unnest(array['1', '2', '3', '4', '5']) as k
          where jsonb_typeof(p->'f'->k) = 'object'),
    't14', (select jsonb_agg(coalesce(public.profil_zahl(a.x, 0, 5000), 0) order by a.i)
            from jsonb_array_elements(case when jsonb_typeof(p->'t14') = 'array' then p->'t14' else '[]'::jsonb end)
                 with ordinality as a(x, i)
            where a.i <= 14),
    'tage', public.profil_zahl(p->'tage', 0, 3650),
    'echt', case when jsonb_typeof(p->'echt') = 'object' then jsonb_build_object(
              'n', public.profil_zahl(p->'echt'->'n', 0, 1000),
              'best', public.profil_zahl(p->'echt'->'best', 0, 100)) end
  ));
$$;

-- Vorbedingung für Profile und Freunde: angemeldet und in der Rangliste.
create or replace function public.profil_pruefen()
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

create or replace function public.ist_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.admin_pruefen()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ist_admin() then
    raise exception 'keine Admin-Rechte' using errcode = '42501';
  end if;
end;
$$;

-- Beziehung aus Sicht von p_ich zu p_du: 'freund', 'angefragt' (eigene
-- Anfrage), 'anfrage' (Anfrage an mich) oder null.
create or replace function public.freund_bez(p_ich uuid, p_du uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when f.status = 'freunde' then 'freund'
    when f.von = p_ich and (f.status = 'offen' or not f.versteckt) then 'angefragt'
    when f.an = p_ich and f.status = 'offen' then 'anfrage'
  end
  from public.freunde f
  where least(f.von, f.an) = least(p_ich, p_du) and greatest(f.von, f.an) = greatest(p_ich, p_du);
$$;

-- Öffentliche Karte einer teilnehmenden Person: nur, was die Rangliste ohnehin zeigt.
create or replace function public.profil_karte(p_user uuid, p_woche text, p_ich uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'pid', p.pid, 'name', r.name, 'reife', r.reife, 'serie', r.serie,
    'antworten', case when r.woche = p_woche then r.antworten else 0 end,
    'bez', case when p_user = p_ich then 'ich' else public.freund_bez(p_ich, p_user) end)
  from public.rangliste r join public.profile p on p.user_id = r.user_id
  where r.user_id = p_user;
$$;

-- Eigene Details melden (die App rechnet sie aus dem Lernstand).
create or replace function public.profil_melden(p_details jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.profil_pruefen();
  if pg_column_size(p_details) > 4000 then
    raise exception 'Details zu groß' using errcode = '22023';
  end if;
  insert into public.profile (user_id, details, details_am)
  values (auth.uid(), public.profil_details_saeubern(p_details), now())
  on conflict (user_id) do update set details = excluded.details, details_am = excluded.details_am;
end;
$$;

-- Wer sieht den Lernstand im Detail: 'freunde' (Standard) oder 'alle'.
create or replace function public.profil_sichtbarkeit(p_wert text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.profil_pruefen();
  if p_wert is null or p_wert not in ('freunde', 'alle') then
    raise exception 'ungültige Sichtbarkeit' using errcode = '22023';
  end if;
  insert into public.profile (user_id, sichtbarkeit) values (auth.uid(), p_wert)
  on conflict (user_id) do update set sichtbarkeit = excluded.sichtbarkeit;
end;
$$;

-- Eigenes Profil, Anfragen, Freunde (nach Antworten dieser Woche) und
-- gesendete Anfragen. null, wenn man nicht in der Rangliste ist.
create or replace function public.freunde_stand(p_woche text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when not exists (select 1 from public.rangliste where user_id = auth.uid()) then null
  else jsonb_build_object(
    'ich', (select jsonb_build_object('pid', p.pid, 'name', r.name, 'sichtbarkeit', p.sichtbarkeit)
            from public.profile p join public.rangliste r on r.user_id = p.user_id
            where p.user_id = auth.uid()),
    'anfragen', coalesce((select jsonb_agg(public.profil_karte(f.von, p_woche, auth.uid()) order by f.seit desc)
                          from public.freunde f
                          where f.an = auth.uid() and f.status = 'offen'), '[]'::jsonb),
    'gesendet', coalesce((select jsonb_agg(public.profil_karte(f.an, p_woche, auth.uid()) order by f.seit desc)
                          from public.freunde f
                          where f.von = auth.uid()
                            and (f.status = 'offen' or (f.status = 'abgelehnt' and not f.versteckt))), '[]'::jsonb),
    'freunde', coalesce((select jsonb_agg(t.k order by (t.k->>'antworten')::integer desc, lower(t.k->>'name'))
                         from (select public.profil_karte(case when f.von = auth.uid() then f.an else f.von end,
                                                          p_woche, auth.uid()) as k
                               from public.freunde f
                               where f.status = 'freunde' and (f.von = auth.uid() or f.an = auth.uid())) t), '[]'::jsonb)
  ) end;
$$;

-- Nutzerübersicht: alle anderen in der Rangliste, aktivste der Woche zuerst,
-- optional nach Spitzname gefiltert. 30 je Seite.
create or replace function public.leute_suche(p_suche text, p_seite integer, p_woche text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_muster text := '%' || replace(replace(replace(btrim(coalesce(p_suche, '')), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  v_seite  integer := least(greatest(coalesce(p_seite, 0), 0), 1000);
begin
  perform public.profil_pruefen();
  return jsonb_build_object(
    'gesamt', (select count(*) from public.rangliste r where r.user_id <> auth.uid() and r.name ilike v_muster),
    'seite', v_seite,
    'liste', coalesce((
      select jsonb_agg(public.profil_karte(t.user_id, p_woche, auth.uid()) order by t.ord)
      from (select r.user_id,
                   row_number() over (order by case when r.woche = p_woche then r.antworten else 0 end desc,
                                               lower(r.name)) as ord
            from public.rangliste r
            where r.user_id <> auth.uid() and r.name ilike v_muster
            order by ord
            limit 30 offset v_seite * 30) t), '[]'::jsonb));
end;
$$;

-- Profil ansehen – über pid oder Spitzname. Den Lernstand im Detail gibt es
-- für Freunde, bei Sichtbarkeit „alle“, für einen selbst und für Admins.
create or replace function public.profil_ansehen(p_pid uuid, p_name text, p_woche text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ich    uuid := auth.uid();
  v_admin  boolean := public.ist_admin();
  v_user   uuid;
  v_p      public.profile%rowtype;
  v_r      public.rangliste%rowtype;
  v_bez    text;
  v_normal boolean;
begin
  if not v_admin then
    perform public.profil_pruefen();
  end if;
  if p_pid is not null then
    select user_id into v_user from public.profile where pid = p_pid;
  else
    select user_id into v_user from public.rangliste where lower(name) = lower(btrim(coalesce(p_name, '')));
  end if;
  select * into v_r from public.rangliste where user_id = v_user;
  select * into v_p from public.profile where user_id = v_user;
  if v_user is null or v_r.user_id is null or v_p.user_id is null then
    raise exception 'Profil nicht gefunden' using errcode = 'P0002';
  end if;
  v_bez := case when v_user = v_ich then 'ich' else public.freund_bez(v_ich, v_user) end;
  v_normal := coalesce(v_bez in ('ich', 'freund'), false) or v_p.sichtbarkeit = 'alle';
  return jsonb_build_object(
    'pid', v_p.pid, 'name', v_r.name, 'reife', v_r.reife, 'serie', v_r.serie,
    'antworten', case when v_r.woche = p_woche then v_r.antworten else 0 end,
    'bez', v_bez, 'sichtbarkeit', v_p.sichtbarkeit,
    'sichtbar', v_normal or v_admin,
    'admin_sicht', v_admin and not v_normal,
    'seit', case when v_normal or v_admin then v_p.seit end,
    'gemeistert', case when v_normal or v_admin then v_r.gemeistert end,
    'details', case when v_normal or v_admin then v_p.details end,
    'details_am', case when v_normal or v_admin then v_p.details_am end);
end;
$$;

-- Freundschaft anfragen. Gibt es schon eine Anfrage der anderen Person, sind
-- beide sofort befreundet. Höchstens 30 offene Anfragen und 50 neue am Tag.
create or replace function public.freund_anfragen(p_pid uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ich uuid := auth.uid();
  v_du  uuid;
  v_f   public.freunde%rowtype;
  v_p   public.profile%rowtype;
begin
  perform public.profil_pruefen();
  select user_id into v_du from public.profile where pid = p_pid;
  if v_du is null then
    raise exception 'Profil nicht gefunden' using errcode = 'P0002';
  end if;
  if v_du = v_ich then
    raise exception 'Das bist du' using errcode = '22023';
  end if;
  select * into v_f from public.freunde
   where least(von, an) = least(v_ich, v_du) and greatest(von, an) = greatest(v_ich, v_du)
   for update;
  if found then
    if v_f.status = 'freunde' then
      return 'freund';
    elsif v_f.von = v_ich then
      -- Die eigene Anfrage besteht schon (vielleicht still abgelehnt): nicht erneut zustellen.
      if v_f.versteckt then
        update public.freunde set versteckt = false where von = v_f.von and an = v_f.an;
      end if;
      return 'angefragt';
    elsif v_f.status = 'offen' or not v_f.versteckt then
      -- Die andere Person hat schon angefragt: jetzt befreundet.
      update public.freunde set status = 'freunde', versteckt = false, seit = now()
       where von = v_f.von and an = v_f.an;
      return 'freund';
    else
      -- Ihre Anfrage wurde abgelehnt und zurückgezogen: neu anfragen.
      delete from public.freunde where von = v_f.von and an = v_f.an;
    end if;
  end if;
  if (select count(*) from public.freunde where von = v_ich and status = 'offen') >= 30 then
    raise exception 'zu viele offene Anfragen' using errcode = 'P0004';
  end if;
  select * into v_p from public.profile where user_id = v_ich for update;
  if v_p.anfragen_tag = current_date and v_p.anfragen_n >= 50 then
    raise exception 'zu viele Anfragen heute' using errcode = 'P0004';
  end if;
  update public.profile
     set anfragen_n = case when anfragen_tag = current_date then anfragen_n + 1 else 1 end,
         anfragen_tag = current_date
   where user_id = v_ich;
  insert into public.freunde (von, an) values (v_ich, v_du);
  return 'angefragt';
end;
$$;

-- Auf eine Anfrage antworten: annehmen oder still ablehnen.
create or replace function public.freund_antworten(p_pid uuid, p_annehmen boolean)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ich uuid := auth.uid();
  v_du  uuid;
begin
  perform public.profil_pruefen();
  select user_id into v_du from public.profile where pid = p_pid;
  if v_du is null then
    raise exception 'Profil nicht gefunden' using errcode = 'P0002';
  end if;
  if coalesce(p_annehmen, false) then
    update public.freunde set status = 'freunde', seit = now()
     where von = v_du and an = v_ich and status = 'offen';
    if not found then
      raise exception 'keine offene Anfrage' using errcode = 'P0002';
    end if;
    return 'freund';
  end if;
  update public.freunde set status = 'abgelehnt' where von = v_du and an = v_ich and status = 'offen';
  return null;
end;
$$;

-- Freundschaft beenden, eigene Anfrage zurückziehen oder Anfrage ablehnen.
create or replace function public.freund_entfernen(p_pid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ich uuid := auth.uid();
  v_du  uuid;
  v_f   public.freunde%rowtype;
begin
  perform public.profil_pruefen();
  select user_id into v_du from public.profile where pid = p_pid;
  if v_du is null then
    return;
  end if;
  select * into v_f from public.freunde
   where least(von, an) = least(v_ich, v_du) and greatest(von, an) = greatest(v_ich, v_du)
   for update;
  if not found then
    return;
  end if;
  if v_f.status = 'freunde' or (v_f.von = v_ich and v_f.status = 'offen') then
    delete from public.freunde where von = v_f.von and an = v_f.an;
  elsif v_f.von = v_ich then
    -- still abgelehnt: nur ausblenden, damit sie nicht erneut zugestellt wird
    update public.freunde set versteckt = true where von = v_f.von and an = v_f.an;
  elsif v_f.status = 'offen' then
    update public.freunde set status = 'abgelehnt' where von = v_f.von and an = v_f.an;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- Verwaltung – jede Funktion prüft zuerst, ob ein Admin angemeldet ist.
-- ----------------------------------------------------------------------------

create or replace function public.admin_merken(p_aktion text, p_ziel uuid, p_details jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.admin_protokoll (admin, aktion, ziel, details)
  values (auth.uid(), p_aktion, p_ziel,
          coalesce(p_details, '{}'::jsonb)
          || coalesce((select jsonb_build_object('email', u.email) from auth.users u where u.id = p_ziel), '{}'::jsonb));
$$;

-- Kennzahlen und die letzten Verwaltungsaktionen.
create or replace function public.admin_uebersicht()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_gruppen   bigint;
  v_meldungen bigint;
begin
  perform public.admin_pruefen();
  if to_regclass('public.gruppen') is not null then
    execute 'select count(*) from public.gruppen' into v_gruppen;
  end if;
  if to_regclass('public.meldungen') is not null then
    execute 'select count(*) from public.meldungen where status = ''neu''' into v_meldungen;
  end if;
  return jsonb_build_object(
    'konten',         (select count(*) from auth.users),
    'neu_7',          (select count(*) from auth.users where created_at > now() - interval '7 days'),
    'aktiv_7',        (select count(*) from auth.users u
                        where u.last_sign_in_at > now() - interval '7 days'
                           or exists (select 1 from public.progress p
                                      where p.user_id = u.id and p.updated_at > now() - interval '7 days')),
    'rangliste',      (select count(*) from public.rangliste),
    'freundschaften', (select count(*) from public.freunde where status = 'freunde'),
    'gesperrt',       (select count(*) from public.gesperrt),
    'gruppen',        v_gruppen,
    'meldungen_neu',  v_meldungen,
    'protokoll', coalesce((select jsonb_agg(jsonb_build_object(
                             'aktion', l.aktion, 'zeit', l.zeit, 'details', l.details,
                             'admin', (select u.email from auth.users u where u.id = l.admin))
                           order by l.zeit desc)
                           from (select * from public.admin_protokoll order by zeit desc limit 20) l), '[]'::jsonb));
end;
$$;

-- Alle Konten, zuletzt aktive zuerst; Suche in E-Mail, Name und Spitzname.
create or replace function public.admin_nutzer_liste(p_suche text, p_seite integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_muster text := '%' || replace(replace(replace(btrim(coalesce(p_suche, '')), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  v_seite  integer := least(greatest(coalesce(p_seite, 0), 0), 10000);
begin
  perform public.admin_pruefen();
  return (
    with treffer as (
      select u.id, u.email::text as email,
             coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', '') as name,
             u.created_at as erstellt, u.last_sign_in_at as anmeldung, p.updated_at as sync,
             r.name as spitzname, r.reife,
             exists (select 1 from public.gesperrt g where g.user_id = u.id) as gesperrt,
             exists (select 1 from public.admins a where a.user_id = u.id) as admin,
             greatest(u.last_sign_in_at, p.updated_at, u.created_at) as zuletzt
      from auth.users u
      left join public.progress p on p.user_id = u.id
      left join public.rangliste r on r.user_id = u.id
      where coalesce(u.email::text, '') ilike v_muster
         or coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', '') ilike v_muster
         or coalesce(r.name, '') ilike v_muster
    )
    select jsonb_build_object(
      'gesamt', (select count(*) from treffer),
      'seite', v_seite,
      'liste', coalesce((select jsonb_agg(to_jsonb(t) order by t.zuletzt desc nulls last, t.email)
                         from (select * from treffer order by zuletzt desc nulls last, email
                               limit 50 offset v_seite * 50) t), '[]'::jsonb)));
end;
$$;

-- Alles über ein Konto: Konto, Lernstand (Rohdaten), Rangliste, Profil,
-- Freunde, Gruppen, Meldungen.
create or replace function public.admin_nutzer(p_user uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v           jsonb;
  v_gruppen   jsonb := '[]'::jsonb;
  v_meldungen jsonb := '[]'::jsonb;
begin
  perform public.admin_pruefen();
  select jsonb_build_object(
    'id', u.id, 'email', u.email::text,
    'name', coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''),
    'anbieter', coalesce(u.raw_app_meta_data->>'provider', ''),
    'erstellt', u.created_at, 'anmeldung', u.last_sign_in_at,
    'admin', exists (select 1 from public.admins a where a.user_id = u.id),
    'gesperrt', (select jsonb_build_object('grund', g.grund, 'seit', g.seit) from public.gesperrt g where g.user_id = u.id),
    'progress', (select jsonb_build_object('data', p.data, 'aktualisiert', p.updated_at)
                 from public.progress p where p.user_id = u.id),
    'rangliste', (select to_jsonb(r) - 'user_id' from public.rangliste r where r.user_id = u.id),
    'profil', (select jsonb_build_object('pid', pr.pid, 'sichtbarkeit', pr.sichtbarkeit, 'details', pr.details,
                                         'details_am', pr.details_am, 'seit', pr.seit)
               from public.profile pr where pr.user_id = u.id),
    'freunde', coalesce((select jsonb_agg(jsonb_build_object(
                           'name', r2.name, 'status', f.status, 'seit', f.seit,
                           'richtung', case when f.von = u.id then 'gesendet' else 'erhalten' end)
                         order by f.seit desc)
                         from public.freunde f
                         join public.rangliste r2 on r2.user_id = case when f.von = u.id then f.an else f.von end
                         where f.von = u.id or f.an = u.id), '[]'::jsonb))
  into v
  from auth.users u where u.id = p_user;
  if v is null then
    raise exception 'Konto nicht gefunden' using errcode = 'P0002';
  end if;
  if to_regclass('public.gruppen_mitglieder') is not null then
    execute 'select coalesce(jsonb_agg(jsonb_build_object(''id'', g.id, ''name'', g.name, ''code'', g.code,
                       ''leitung'', g.owner = $1) order by m.seit), ''[]''::jsonb)
             from public.gruppen_mitglieder m join public.gruppen g on g.id = m.gruppe
             where m.user_id = $1'
      into v_gruppen using p_user;
  end if;
  if to_regclass('public.meldungen') is not null then
    execute 'select coalesce(jsonb_agg(jsonb_build_object(''id'', t.id, ''frage'', t.frage, ''art'', t.art,
                       ''text'', t.text, ''status'', t.status, ''zeit'', t.created_at) order by t.created_at desc), ''[]''::jsonb)
             from (select * from public.meldungen where user_id = $1 order by created_at desc limit 50) t'
      into v_meldungen using p_user;
  end if;
  return v || jsonb_build_object('gruppen', v_gruppen, 'meldungen', v_meldungen);
end;
$$;

-- Aus der Rangliste nehmen (z. B. unpassender Spitzname). Profil, Freunde und
-- Gruppen gehen mit; ein neuer Beitritt bleibt möglich.
create or replace function public.admin_aus_rangliste(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.admin_pruefen();
  delete from public.rangliste where user_id = p_user;
  perform public.admin_merken('aus_rangliste', p_user, '{}'::jsonb);
end;
$$;

-- Sperren: raus aus Rangliste, Profil, Freunden und Gruppen, kein neuer
-- Beitritt. Lernen und Sichern gehen weiter.
create or replace function public.admin_sperren(p_user uuid, p_grund text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_grund text := left(btrim(coalesce(p_grund, '')), 300);
begin
  perform public.admin_pruefen();
  if p_user = auth.uid() or exists (select 1 from public.admins where user_id = p_user) then
    raise exception 'Admins können nicht gesperrt werden' using errcode = '22023';
  end if;
  if not exists (select 1 from auth.users where id = p_user) then
    raise exception 'Konto nicht gefunden' using errcode = 'P0002';
  end if;
  insert into public.gesperrt (user_id, grund, von) values (p_user, v_grund, auth.uid())
  on conflict (user_id) do update set grund = excluded.grund, seit = now(), von = excluded.von;
  delete from public.rangliste where user_id = p_user;
  perform public.admin_merken('sperren', p_user, jsonb_build_object('grund', v_grund));
end;
$$;

create or replace function public.admin_entsperren(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.admin_pruefen();
  delete from public.gesperrt where user_id = p_user;
  perform public.admin_merken('entsperren', p_user, '{}'::jsonb);
end;
$$;

-- Konto endgültig löschen (z. B. auf Wunsch der Person). Zur Bestätigung muss
-- die E-Mail des Kontos mitkommen. Eigene und Admin-Konten sind ausgenommen.
create or replace function public.admin_konto_loeschen(p_user uuid, p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  perform public.admin_pruefen();
  if p_user = auth.uid() or exists (select 1 from public.admins where user_id = p_user) then
    raise exception 'Admin-Konten hier nicht löschbar' using errcode = '22023';
  end if;
  select coalesce(email::text, '') into v_email from auth.users where id = p_user;
  if not found then
    raise exception 'Konto nicht gefunden' using errcode = 'P0002';
  end if;
  if lower(v_email) <> lower(btrim(coalesce(p_email, ''))) then
    raise exception 'Bestätigung passt nicht' using errcode = '22023';
  end if;
  perform public.admin_merken('konto_loeschen', p_user, '{}'::jsonb);
  delete from auth.users where id = p_user;
end;
$$;

-- Meldungen (aus docs/supabase-meldungen.sql) lesen und abhaken.
create or replace function public.admin_meldungen(p_status text, p_seite integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v jsonb;
begin
  perform public.admin_pruefen();
  if to_regclass('public.meldungen') is null then
    return null;
  end if;
  execute $q$
    with t as (
      select m.id, m.frage, m.art, m.text, m.kontext, m.quelle, m.status, m.created_at,
             u.email::text as email, r.name as spitzname, m.user_id
      from public.meldungen m
      left join auth.users u on u.id = m.user_id
      left join public.rangliste r on r.user_id = m.user_id
      where $1 is null or m.status = $1
    )
    select jsonb_build_object(
      'gesamt', (select count(*) from t),
      'zaehler', coalesce((select jsonb_object_agg(z.status, z.n)
                           from (select status, count(*) as n from public.meldungen group by status) z), '{}'::jsonb),
      'liste', coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc, x.id desc)
                         from (select * from t order by created_at desc, id desc limit 50 offset $2 * 50) x), '[]'::jsonb))
  $q$ into v using nullif(nullif(p_status, ''), 'alle'), least(greatest(coalesce(p_seite, 0), 0), 10000);
  return v;
end;
$$;

create or replace function public.admin_meldung_status(p_id bigint, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.admin_pruefen();
  if p_status is null or p_status not in ('neu', 'erledigt', 'abgelehnt') then
    raise exception 'ungültiger Status' using errcode = '22023';
  end if;
  if to_regclass('public.meldungen') is null then
    return;
  end if;
  execute 'update public.meldungen set status = $1 where id = $2' using p_status, p_id;
  perform public.admin_merken('meldung_' || p_status, null, jsonb_build_object('meldung', p_id));
end;
$$;

-- Lerngruppen (aus docs/supabase-gruppen.sql) ansehen und löschen.
create or replace function public.admin_gruppen(p_seite integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v jsonb;
begin
  perform public.admin_pruefen();
  if to_regclass('public.gruppen') is null then
    return null;
  end if;
  execute $q$
    select jsonb_build_object(
      'gesamt', (select count(*) from public.gruppen),
      'liste', coalesce((select jsonb_agg(t.x order by t.created_at desc, t.id)
                         from (select g.id, g.created_at, jsonb_build_object(
                                 'id', g.id, 'name', g.name, 'code', g.code, 'erstellt', g.created_at,
                                 'mitglieder', (select count(*) from public.gruppen_mitglieder m where m.gruppe = g.id),
                                 'leitung', (select r.name from public.rangliste r where r.user_id = g.owner),
                                 'leitung_email', (select u.email::text from auth.users u where u.id = g.owner)) as x
                               from public.gruppen g
                               order by g.created_at desc, g.id
                               limit 50 offset $1 * 50) t), '[]'::jsonb))
  $q$ into v using least(greatest(coalesce(p_seite, 0), 0), 10000);
  return v;
end;
$$;

create or replace function public.admin_gruppe_loeschen(p_gruppe uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  perform public.admin_pruefen();
  if to_regclass('public.gruppen') is null then
    return;
  end if;
  execute 'delete from public.gruppen where id = $1 returning name' into v_name using p_gruppe;
  perform public.admin_merken('gruppe_loeschen', null, jsonb_build_object('gruppe', p_gruppe, 'name', v_name));
end;
$$;

-- Rechte: Supabase gibt neuen Funktionen standardmäßig Ausführungsrechte für
-- alle Rollen – hier ausdrücklich eingeschränkt. Hilfsfunktionen gar nicht
-- von außen, alles andere nur für angemeldete Personen.
revoke all on function public.profil_anlegen()                          from public, anon, authenticated;
revoke all on function public.rangliste_sperre()                        from public, anon, authenticated;
revoke all on function public.profil_zahl(jsonb, integer, integer)      from public, anon, authenticated;
revoke all on function public.profil_details_saeubern(jsonb)            from public, anon, authenticated;
revoke all on function public.profil_pruefen()                          from public, anon, authenticated;
revoke all on function public.admin_pruefen()                           from public, anon, authenticated;
revoke all on function public.freund_bez(uuid, uuid)                    from public, anon, authenticated;
revoke all on function public.profil_karte(uuid, text, uuid)            from public, anon, authenticated;
revoke all on function public.admin_merken(text, uuid, jsonb)           from public, anon, authenticated;
revoke all on function public.ist_admin()                               from public, anon, authenticated;
revoke all on function public.profil_melden(jsonb)                      from public, anon, authenticated;
revoke all on function public.profil_sichtbarkeit(text)                 from public, anon, authenticated;
revoke all on function public.freunde_stand(text)                       from public, anon, authenticated;
revoke all on function public.leute_suche(text, integer, text)          from public, anon, authenticated;
revoke all on function public.profil_ansehen(uuid, text, text)          from public, anon, authenticated;
revoke all on function public.freund_anfragen(uuid)                     from public, anon, authenticated;
revoke all on function public.freund_antworten(uuid, boolean)           from public, anon, authenticated;
revoke all on function public.freund_entfernen(uuid)                    from public, anon, authenticated;
revoke all on function public.admin_uebersicht()                        from public, anon, authenticated;
revoke all on function public.admin_nutzer_liste(text, integer)         from public, anon, authenticated;
revoke all on function public.admin_nutzer(uuid)                        from public, anon, authenticated;
revoke all on function public.admin_aus_rangliste(uuid)                 from public, anon, authenticated;
revoke all on function public.admin_sperren(uuid, text)                 from public, anon, authenticated;
revoke all on function public.admin_entsperren(uuid)                    from public, anon, authenticated;
revoke all on function public.admin_konto_loeschen(uuid, text)          from public, anon, authenticated;
revoke all on function public.admin_meldungen(text, integer)            from public, anon, authenticated;
revoke all on function public.admin_meldung_status(bigint, text)        from public, anon, authenticated;
revoke all on function public.admin_gruppen(integer)                    from public, anon, authenticated;
revoke all on function public.admin_gruppe_loeschen(uuid)               from public, anon, authenticated;
grant execute on function public.ist_admin()                            to authenticated;
grant execute on function public.profil_melden(jsonb)                   to authenticated;
grant execute on function public.profil_sichtbarkeit(text)              to authenticated;
grant execute on function public.freunde_stand(text)                    to authenticated;
grant execute on function public.leute_suche(text, integer, text)       to authenticated;
grant execute on function public.profil_ansehen(uuid, text, text)       to authenticated;
grant execute on function public.freund_anfragen(uuid)                  to authenticated;
grant execute on function public.freund_antworten(uuid, boolean)        to authenticated;
grant execute on function public.freund_entfernen(uuid)                 to authenticated;
grant execute on function public.admin_uebersicht()                     to authenticated;
grant execute on function public.admin_nutzer_liste(text, integer)      to authenticated;
grant execute on function public.admin_nutzer(uuid)                     to authenticated;
grant execute on function public.admin_aus_rangliste(uuid)              to authenticated;
grant execute on function public.admin_sperren(uuid, text)              to authenticated;
grant execute on function public.admin_entsperren(uuid)                 to authenticated;
grant execute on function public.admin_konto_loeschen(uuid, text)       to authenticated;
grant execute on function public.admin_meldungen(text, integer)         to authenticated;
grant execute on function public.admin_meldung_status(bigint, text)     to authenticated;
grant execute on function public.admin_gruppen(integer)                 to authenticated;
grant execute on function public.admin_gruppe_loeschen(uuid)            to authenticated;
