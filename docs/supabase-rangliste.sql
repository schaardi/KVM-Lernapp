-- Vergleich mit anderen Lernenden: freiwillige Wochenrangliste
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen (Projekt der App). Die Datei lässt
-- sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Nur mit Konto und nur nach ausdrücklichem Beitritt (Spitzname wählen).
-- * Für andere sichtbar sind ausschließlich: Spitzname, Prüfungsreife in %,
--   Antworten dieser Woche, Lerntage in Folge und die Prüfungsergebnisse
--   (gewertete und bestandene Original-Prüfungen, Ø-Punkte, Bestehenschance).
--   Keine E-Mail, kein Klarname, keine user_id.
-- * Die Tabelle ist für Clients gesperrt; gelesen und geschrieben wird nur über
--   die Funktionen unten. Austreten löscht den Eintrag vollständig.
-- * Ohne diese Datei zeigen Web-App und App den Vergleich einfach nicht an.
-- ----------------------------------------------------------------------------

create table if not exists public.rangliste (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  name       text     not null check (name ~ '^[A-Za-zÄÖÜäöüß0-9 _.-]{3,20}$'),
  reife      smallint not null default 0 check (reife between 0 and 100),
  gemeistert integer  not null default 0 check (gemeistert between 0 and 100000),
  woche      text     not null default '',            -- ISO-Woche, z. B. 2026-W39
  antworten  integer  not null default 0 check (antworten between 0 and 20000),
  serie      smallint not null default 0 check (serie between 0 and 3650),
  updated_at timestamptz not null default now()
);

-- Spitznamen sind eindeutig (ohne Rücksicht auf Groß-/Kleinschreibung).
create unique index if not exists rangliste_name_idx on public.rangliste (lower(name));

-- Prüfungsergebnisse (die App rechnet sie aus den gewerteten Durchgängen der
-- Original-Prüfungen, je Prüfung zählt der erste): Zahl der Prüfungen, davon
-- bestanden (≥ 50 %), Ø-Punkte in % und Bestehenschance in % – für beide
-- Prüfungsteile, sonst für den Teil, in dem jeder Bereich gewertet ist; null,
-- solange das für keinen Teil gilt.
alter table public.rangliste add column if not exists pruef_n       smallint not null default 0 check (pruef_n between 0 and 1000);
alter table public.rangliste add column if not exists pruef_ok      smallint not null default 0 check (pruef_ok between 0 and 1000);
alter table public.rangliste add column if not exists pruef_schnitt smallint check (pruef_schnitt between 0 and 100);
alter table public.rangliste add column if not exists chance        smallint check (chance between 0 and 100);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.rangliste enable row level security;
revoke all on table public.rangliste from anon, authenticated;

-- Eigene Werte melden (beitreten, aktualisieren, Spitzname ändern).
-- Antworten derselben Woche werden nie kleiner: nutzt jemand zwei Geräte,
-- gilt der höhere Stand.
create or replace function public.rangliste_melden(
  p_name text, p_reife integer, p_gemeistert integer,
  p_woche text, p_antworten integer, p_serie integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'nicht angemeldet';
  end if;
  if p_woche !~ '^\d{4}-W\d{2}$' then
    raise exception 'ungültige Woche';
  end if;
  insert into public.rangliste as r
    (user_id, name, reife, gemeistert, woche, antworten, serie, updated_at)
  values
    (auth.uid(), btrim(p_name),
     least(greatest(coalesce(p_reife, 0), 0), 100),
     least(greatest(coalesce(p_gemeistert, 0), 0), 100000),
     p_woche,
     least(greatest(coalesce(p_antworten, 0), 0), 20000),
     least(greatest(coalesce(p_serie, 0), 0), 3650),
     now())
  on conflict (user_id) do update set
    name       = excluded.name,
    reife      = excluded.reife,
    gemeistert = excluded.gemeistert,
    serie      = excluded.serie,
    antworten  = case when r.woche = excluded.woche
                      then greatest(r.antworten, excluded.antworten)
                      else excluded.antworten end,
    woche      = excluded.woche,
    updated_at = now();
end;
$$;

-- Austreten: der Eintrag wird gelöscht.
create or replace function public.rangliste_austreten()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.rangliste where user_id = auth.uid();
$$;

-- Stand für die angemeldete Person: eigener Eintrag, Vergleich der
-- Prüfungsreife (wie viele liegen darunter) und die Top 10 der Woche.
create or replace function public.rangliste_stand(p_woche text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with ich as (
    select * from public.rangliste where user_id = auth.uid()
  ),
  woche as (
    select user_id, name, antworten, reife, serie,
           rank() over (order by antworten desc) as platz
    from public.rangliste
    where woche = p_woche and antworten > 0
  )
  select jsonb_build_object(
    'dabei',              exists (select 1 from ich),
    'name',               (select name from ich),
    'teilnehmende',       (select count(*) from public.rangliste),
    'reife_vor',          (select count(*) from public.rangliste r, ich
                            where r.reife < ich.reife),
    'woche_teilnehmende', (select count(*) from woche),
    'mein_platz',         (select platz from woche where user_id = auth.uid()),
    'meine_antworten',    (select antworten from woche where user_id = auth.uid()),
    'liste', coalesce((
      select jsonb_agg(jsonb_build_object(
               'platz', platz, 'name', name, 'antworten', antworten,
               'reife', reife, 'serie', serie, 'ich', user_id = auth.uid())
             order by platz, name)
      from (select * from woche order by platz, name limit 10) t
    ), '[]'::jsonb)
  );
$$;

-- Prüfungsergebnisse melden. Nur wer der Rangliste beigetreten ist; sonst
-- passiert nichts.
create or replace function public.pruefungen_melden(
  p_n integer, p_ok integer, p_schnitt integer, p_chance integer)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.rangliste set
    pruef_n       = least(greatest(coalesce(p_n, 0), 0), 1000),
    pruef_ok      = least(greatest(coalesce(p_ok, 0), 0), least(greatest(coalesce(p_n, 0), 0), 1000)),
    pruef_schnitt = case when coalesce(p_n, 0) > 0 and p_schnitt is not null
                         then least(greatest(p_schnitt, 0), 100) end,
    chance        = case when coalesce(p_n, 0) > 0 and p_chance is not null
                         then least(greatest(p_chance, 0), 100) end,
    updated_at    = now()
  where user_id = auth.uid();
$$;

-- Prüfungsrangliste: die meisten bestandenen Prüfungen zuerst, bei Gleichstand
-- der bessere Schnitt. Top 10 und der eigene Stand.
create or replace function public.rangliste_pruefungen()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with l as (
    select user_id, name, pruef_n, pruef_ok, pruef_schnitt, chance,
           rank() over (order by pruef_ok desc, pruef_schnitt desc nulls last) as platz
    from public.rangliste
    where pruef_n > 0
  )
  select jsonb_build_object(
    'teilnehmende', (select count(*) from l),
    'ich', (select jsonb_build_object('platz', platz, 'n', pruef_n, 'ok', pruef_ok,
                                      'schnitt', pruef_schnitt, 'chance', chance)
            from l where user_id = auth.uid()),
    'liste', coalesce((
      select jsonb_agg(jsonb_build_object(
               'platz', platz, 'name', name, 'n', pruef_n, 'ok', pruef_ok,
               'schnitt', pruef_schnitt, 'chance', chance, 'ich', user_id = auth.uid())
             order by platz, name)
      from (select * from l order by platz, name limit 10) t
    ), '[]'::jsonb)
  );
$$;

-- Nur die Zahl der Teilnehmenden – für den Hinweis vor der Anmeldung.
create or replace function public.rangliste_info()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select count(*) from public.rangliste;
$$;

-- Rechte: Supabase gibt neuen Funktionen standardmäßig Ausführungsrechte für
-- alle Rollen – hier ausdrücklich eingeschränkt.
revoke all on function public.rangliste_melden(text, integer, integer, text, integer, integer) from public, anon, authenticated;
revoke all on function public.rangliste_austreten()                                           from public, anon, authenticated;
revoke all on function public.rangliste_stand(text)                                           from public, anon, authenticated;
revoke all on function public.rangliste_info()                                                from public, anon, authenticated;
revoke all on function public.pruefungen_melden(integer, integer, integer, integer)           from public, anon, authenticated;
revoke all on function public.rangliste_pruefungen()                                          from public, anon, authenticated;
grant execute on function public.rangliste_melden(text, integer, integer, text, integer, integer) to authenticated;
grant execute on function public.rangliste_austreten()                                           to authenticated;
grant execute on function public.rangliste_stand(text)                                           to authenticated;
grant execute on function public.rangliste_info()                                                to anon, authenticated;
grant execute on function public.pruefungen_melden(integer, integer, integer, integer)           to authenticated;
grant execute on function public.rangliste_pruefungen()                                          to authenticated;
