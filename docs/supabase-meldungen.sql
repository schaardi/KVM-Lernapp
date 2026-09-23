-- Fehler melden: Hinweise der Lernenden zu einzelnen Fragen und Teilaufgaben
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen (Projekt der App). Die Datei lässt
-- sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Melden geht auch ohne Konto. Gespeichert werden Fragennummer, Art des
--   Fehlers, der freie Text, ein kurzer Kontext (Modus, Fach, Textauszug) und –
--   nur wenn angemeldet – die Konto-ID für Rückfragen. Keine IP-Adresse.
-- * Clients können nur über meldung_senden() schreiben, nichts lesen und nichts
--   ändern. Gelesen und abgehakt wird im Supabase-Dashboard (Table Editor oder
--   SQL, siehe unten).
-- * Einfache Bremse gegen Fluten: höchstens 50 Meldungen je Konto und Tag,
--   insgesamt höchstens 300 je Stunde.
-- * Ohne diese Datei blenden Web-App und App den Knopf „Fehler?“ aus.
-- ----------------------------------------------------------------------------

create table if not exists public.meldungen (
  id         bigint generated always as identity primary key,
  frage      text        not null check (length(frage) between 1 and 80),
  art        text        not null check (art in ('text', 'loesung', 'rechnung', 'anlage', 'sonstiges')),
  text       text        not null default '' check (length(text) <= 1000),
  kontext    jsonb       not null default '{}'::jsonb,
  quelle     text        not null default 'web' check (quelle in ('web', 'app')),
  user_id    uuid        references auth.users(id) on delete set null,
  status     text        not null default 'neu' check (status in ('neu', 'erledigt', 'abgelehnt')),
  created_at timestamptz not null default now()
);

create index if not exists meldungen_status_idx on public.meldungen (status, created_at desc);
create index if not exists meldungen_frage_idx  on public.meldungen (frage);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.meldungen enable row level security;
revoke all on table public.meldungen from anon, authenticated;

-- Meldung abgeben. Prüft Länge und Art, bremst Fluten und merkt sich das
-- Konto nur, wenn jemand angemeldet ist.
create or replace function public.meldung_senden(
  p_frage text, p_art text, p_text text, p_kontext jsonb, p_quelle text default 'web')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_frage is null or length(btrim(p_frage)) = 0 then
    raise exception 'Frage fehlt' using errcode = '22023';
  end if;
  if pg_column_size(coalesce(p_kontext, '{}'::jsonb)) > 2000 then
    raise exception 'Kontext zu groß' using errcode = '22023';
  end if;
  if (select count(*) from public.meldungen
       where created_at > now() - interval '1 hour') >= 300 then
    raise exception 'zu viele Meldungen' using errcode = 'P0001';
  end if;
  if auth.uid() is not null and (select count(*) from public.meldungen
       where user_id = auth.uid() and created_at > now() - interval '1 day') >= 50 then
    raise exception 'zu viele Meldungen' using errcode = 'P0001';
  end if;
  insert into public.meldungen (frage, art, text, kontext, quelle, user_id)
  values (left(btrim(p_frage), 80), p_art, left(coalesce(btrim(p_text), ''), 1000),
          coalesce(p_kontext, '{}'::jsonb), coalesce(p_quelle, 'web'), auth.uid());
end;
$$;

-- Nur für die Frage „Ist Melden eingerichtet?“ – Web-App und App zeigen den
-- Knopf erst, wenn diese Funktion antwortet.
create or replace function public.meldungen_bereit()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select true;
$$;

-- Rechte: Supabase gibt neuen Funktionen standardmäßig Ausführungsrechte für
-- alle Rollen – hier ausdrücklich eingeschränkt.
revoke all on function public.meldung_senden(text, text, text, jsonb, text) from public, anon, authenticated;
revoke all on function public.meldungen_bereit()                            from public, anon, authenticated;
grant execute on function public.meldung_senden(text, text, text, jsonb, text) to anon, authenticated;
grant execute on function public.meldungen_bereit()                            to anon, authenticated;

-- ----------------------------------------------------------------------------
-- Im Dashboard (SQL-Editor) auswerten, z. B.:
--
--   -- offene Meldungen, neueste zuerst
--   select id, created_at, frage, art, text, kontext->>'auszug' as auszug
--   from public.meldungen where status = 'neu' order by created_at desc;
--
--   -- Fragen mit den meisten Meldungen
--   select frage, count(*) from public.meldungen where status = 'neu'
--   group by frage order by count(*) desc;
--
--   -- abhaken
--   update public.meldungen set status = 'erledigt' where id in (1, 2, 3);
-- ----------------------------------------------------------------------------
