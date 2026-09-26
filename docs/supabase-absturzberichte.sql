-- Absturzberichte der Android-App (Startschutz)
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen (Projekt der App). Die Datei lässt
-- sich gefahrlos erneut ausführen.
--
-- Grundsätze
-- * Die App schickt einen Bericht, wenn sie abgestürzt ist – gleich beim
--   nächsten Prozessstart bzw. noch im Absturz selbst, ohne Flutter und ohne
--   Anmeldung (`Absturzmeldung.kt`). So kommt er auch an, wenn die App jedes Mal
--   sofort wieder abstürzt.
-- * Inhalt: App-Version, Gerät und Android-Version, Art (java/system/bericht)
--   und der Text: Stapel bzw. Tombstone, Programmenden laut Android, eigene
--   Protokollzeilen der App. Keine Konto-ID, keine IP-Adresse.
-- * Clients können nur über absturz_melden() schreiben, nichts lesen und nichts
--   ändern. Gelesen wird im Supabase-Dashboard (Table Editor oder SQL, unten).
-- * Einfache Bremse gegen Fluten: höchstens 100 Berichte je Stunde insgesamt.
-- ----------------------------------------------------------------------------

create table if not exists public.absturzberichte (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  app        text        not null default '' check (length(app) <= 40),
  geraet     text        not null default '' check (length(geraet) <= 200),
  art        text        not null default '' check (length(art) <= 40),
  bericht    text        not null check (length(bericht) between 1 and 400000),
  status     text        not null default 'neu' check (status in ('neu', 'erledigt'))
);

create index if not exists absturzberichte_zeit_idx on public.absturzberichte (created_at desc);

-- Kein direkter Zugriff: RLS an, keine Policies, Rechte entzogen.
alter table public.absturzberichte enable row level security;
revoke all on table public.absturzberichte from anon, authenticated;

-- Bericht abgeben. Kürzt überlange Felder und bremst Fluten.
create or replace function public.absturz_melden(
  p_app text, p_geraet text, p_art text, p_bericht text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_bericht is null or length(p_bericht) = 0 then
    raise exception 'Bericht fehlt' using errcode = '22023';
  end if;
  if (select count(*) from public.absturzberichte
       where created_at > now() - interval '1 hour') >= 100 then
    raise exception 'zu viele Berichte' using errcode = 'P0001';
  end if;
  insert into public.absturzberichte (app, geraet, art, bericht)
  values (left(coalesce(p_app, ''), 40), left(coalesce(p_geraet, ''), 200),
          left(coalesce(p_art, ''), 40), left(p_bericht, 400000));
end;
$$;

-- Rechte: Supabase gibt neuen Funktionen standardmäßig Ausführungsrechte für
-- alle Rollen – hier ausdrücklich eingeschränkt.
revoke all on function public.absturz_melden(text, text, text, text) from public, anon, authenticated;
grant execute on function public.absturz_melden(text, text, text, text) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- Im Dashboard (SQL-Editor) auswerten, z. B.:
--
--   -- neueste Berichte
--   select id, created_at, app, geraet, art, left(bericht, 2000)
--   from public.absturzberichte where status = 'neu' order by id desc;
--
--   -- abhaken
--   update public.absturzberichte set status = 'erledigt' where id in (1, 2);
-- ----------------------------------------------------------------------------
