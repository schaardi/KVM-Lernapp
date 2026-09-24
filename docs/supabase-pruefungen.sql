-- Prüfungsergebnisse geräteübergreifend
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen. Unabhängig von Rangliste, Gruppen
-- und Profilen; die Datei lässt sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Je ausgewertetem Durchgang einer Original-Prüfung eine Zeile: Punkte,
--   bewertete Teilaufgaben, ob unter Prüfungsbedingungen. Keine Antworten.
-- * Jede Person liest und schreibt nur ihre eigenen Zeilen, und zwar über
--   pruefungen_abgleichen. Die Tabelle ist für Clients gesperrt.
-- * Die Kennung k vergibt das Gerät je Durchgang. g (Zeitpunkt der letzten
--   Bewertung, ms) entscheidet, welcher Stand gilt, wenn zwei Geräte denselben
--   Durchgang melden.
-- * Wer sein Konto löscht, verliert die Zeilen (on delete cascade).
-- * Ohne diese Datei bleiben die Ergebnisse auf dem Gerät – Web-App und App
--   funktionieren trotzdem.
-- ----------------------------------------------------------------------------

create table if not exists public.pruefung_ergebnisse (
  user_id  uuid        not null references auth.users(id) on delete cascade,
  k        text        not null check (k ~ '^[A-Za-z0-9_-]{1,80}$'),
  pruefung text        not null check (pruefung ~ '^P-[A-Z]{2}-[0-9]{8}$'),
  t        timestamptz not null,                   -- ausgewertet am
  g        bigint      not null default 0,         -- zuletzt bewertet (ms)
  pkt      smallint    not null check (pkt >= 0),
  max      smallint    not null check (max between 1 and 1000),
  bew      smallint    check (bew between 0 and 200),        -- Teilaufgaben mit Punkten
  teile    smallint    check (teile between 0 and 200),      -- Teilaufgaben mit Punktangabe
  echt     boolean     not null default false,               -- unter Prüfungsbedingungen
  dauer    integer     check (dauer between 0 and 86400000), -- Bearbeitungszeit (ms)
  min      smallint    check (min between 0 and 600),        -- vorgesehene Zeit (min)
  primary key (user_id, k),
  check (pkt <= max)
);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.pruefung_ergebnisse enable row level security;
revoke all on table public.pruefung_ergebnisse from anon, authenticated;

-- Abgleich: neue oder geänderte Durchgänge des Geräts übernehmen (höchstens
-- 500 je Aufruf, ungültige werden übersprungen) und alle eigenen zurückgeben,
-- älteste zuerst. Je Konto bleiben die 1000 jüngsten Durchgänge.
create or replace function public.pruefungen_abgleichen(p_neu jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ich uuid := auth.uid();
begin
  if v_ich is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
  if jsonb_typeof(p_neu) = 'array' and jsonb_array_length(p_neu) > 0 then
    if jsonb_array_length(p_neu) > 500 or pg_column_size(p_neu) > 256000 then
      raise exception 'zu viele Ergebnisse auf einmal' using errcode = '22023';
    end if;
    insert into public.pruefung_ergebnisse as e
      (user_id, k, pruefung, t, g, pkt, max, bew, teile, echt, dauer, min)
    select distinct on (x.k)
           v_ich, x.k, x.id, to_timestamp(x.t / 1000.0), coalesce(x.g, 0), x.pkt, x.max,
           x.bew, x.teile, coalesce(x.echt, 0) = 1, x.dauer, x.min
    from jsonb_to_recordset(p_neu) as x(k text, id text, t bigint, g bigint, pkt integer, max integer,
                                        bew integer, teile integer, echt integer, dauer bigint, min integer)
    where x.k ~ '^[A-Za-z0-9_-]{1,80}$'
      and x.id ~ '^P-[A-Z]{2}-[0-9]{8}$'
      and x.t between 1400000000000 and 4102444800000
      and coalesce(x.g, 0) between 0 and 4102444800000
      and x.max between 1 and 1000
      and x.pkt between 0 and x.max
      and (x.bew is null or x.bew between 0 and 200)
      and (x.teile is null or x.teile between 0 and 200)
      and (x.dauer is null or x.dauer between 0 and 86400000)
      and (x.min is null or x.min between 0 and 600)
    order by x.k, x.g desc nulls last
    on conflict (user_id, k) do update set
      pkt   = excluded.pkt,
      max   = excluded.max,
      bew   = excluded.bew,
      teile = excluded.teile,
      echt  = e.echt or excluded.echt,
      dauer = coalesce(excluded.dauer, e.dauer),
      min   = coalesce(excluded.min, e.min),
      t     = least(e.t, excluded.t),
      g     = excluded.g
    where excluded.g > e.g;
    delete from public.pruefung_ergebnisse d
    where d.user_id = v_ich and d.k in (
      select k from public.pruefung_ergebnisse
      where user_id = v_ich order by t desc, k offset 1000);
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'k', s.k, 'id', s.pruefung, 't', (extract(epoch from s.t) * 1000)::bigint, 'g', s.g,
             'pkt', s.pkt, 'max', s.max, 'bew', s.bew, 'teile', s.teile,
             'echt', case when s.echt then 1 else 0 end, 'dauer', s.dauer, 'min', s.min)
           order by s.t, s.k)
    from (select * from public.pruefung_ergebnisse
          where user_id = v_ich order by t desc, k limit 500) s
  ), '[]'::jsonb);
end;
$$;

-- Rechte: nur angemeldete Personen.
revoke all on function public.pruefungen_abgleichen(jsonb) from public, anon, authenticated;
grant execute on function public.pruefungen_abgleichen(jsonb) to authenticated;
