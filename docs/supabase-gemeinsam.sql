-- Gemeinsam lernen: dieselbe Original-Prüfung zu mehreren lösen und nach jeder
-- Aufgabe die Antworten vergleichen
-- ----------------------------------------------------------------------------
-- Einmal im Supabase-SQL-Editor ausführen. Die Datei lässt sich gefahrlos
-- erneut ausführen. Sie braucht nur die Anmeldung, keine Rangliste.
--
-- Ablauf
-- * Eine Person startet eine Runde zu einer Prüfung und bekommt einen
--   6-stelligen Code (ohne 0/O/1/I). Die anderen treten mit dem Code oder dem
--   Link „…#gemeinsam=CODE“ bei.
-- * Jede Person löst die ganze Prüfung selbst, Aufgabe für Aufgabe („Seite“).
--   Ist sie mit einer Aufgabe fertig, schreibt die App deren Antworten fest
--   (gemeinsam_fertig). Dann vergleicht sie: Sie sieht die Antworten aller, die
--   mit derselben Aufgabe auch fertig sind, dazu die Lösung.
-- * Fremde Antworten einer Aufgabe gibt gemeinsam_stand erst heraus, wenn man
--   selbst mit dieser Aufgabe fertig ist. Vorher sieht man nur, ob jemand
--   fertig ist.
-- * Punkte (Selbstbewertung) je Teilaufgabe meldet jede Person für sich, erst
--   nach „fertig“.
-- * Was jemand gerade schreibt, sehen die anderen nur als Sterne. Die App
--   schickt das über Supabase Realtime (Kanal „gemeinsam:<id>“), ohne Inhalt
--   und ohne die Datenbank.
--
-- Antworten einer Aufgabe (jsonb, Format wie die lokalen Speicher kvm_open_*):
--   {"v": 1,
--    "teile":   {"<Teilaufgaben-ID>": {"t": "Text",
--                                       "rw": [{"l": "…", "f": "…", "u": "…"}],
--                                       "sk": {"els": [...], "bg": "…", "fmt": "…"},
--                                       "tab": {"0": {"Zeile-Spalte": "Wert"}}}},
--    "anlagen": {"0": {"Zeile-Spalte": "Wert"}}}
-- Punkte einer Aufgabe: {"<Teilaufgaben-ID>": 4, …}
--
-- Grenzen: Name 2–24 Zeichen, höchstens 6 Personen je Runde und 10 Runden je
-- Person, Antworten je Aufgabe höchstens 400 kB. Runden ohne Aktivität seit
-- 30 Tagen löscht der nächste Start einer Runde. Wer geht, nimmt seine
-- Antworten mit; die letzte Person nimmt die Runde mit. Falsche Codes sind
-- gebremst (eine halbe Sekunde je Versuch).
-- Tabellen sind für Clients gesperrt; alles läuft über die Funktionen unten.
-- ----------------------------------------------------------------------------

create table if not exists public.gemeinsam_runden (
  id         uuid        primary key default gen_random_uuid(),
  code       text        not null unique check (code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  pruefung   text        not null check (pruefung ~ '^P-[A-Z]{2,3}-[0-9]{8}$'),
  created_at timestamptz not null default now(),
  aktiv_am   timestamptz not null default now()
);
create index if not exists gemeinsam_runden_aktiv_idx on public.gemeinsam_runden (aktiv_am);

create table if not exists public.gemeinsam_teilnehmer (
  runde   uuid        not null references public.gemeinsam_runden(id) on delete cascade,
  user_id uuid        not null references auth.users(id) on delete cascade,
  -- Kennung in der Runde (für Realtime und die Anzeige) – die Konto-ID sieht
  -- niemand sonst.
  tid     text        not null check (tid ~ '^[a-z0-9]{8}$'),
  name    text        not null check (length(name) between 2 and 24),
  farbe   smallint    not null check (farbe between 0 and 5),
  seit    timestamptz not null default now(),
  primary key (runde, user_id),
  unique (runde, tid)
);
create index if not exists gemeinsam_teilnehmer_user_idx on public.gemeinsam_teilnehmer (user_id);

create table if not exists public.gemeinsam_seiten (
  runde     uuid        not null,
  user_id   uuid        not null,
  nr        smallint    not null check (nr between 1 and 30),
  antworten jsonb       not null check (jsonb_typeof(antworten) = 'object'),
  punkte    jsonb       not null default '{}'::jsonb check (jsonb_typeof(punkte) = 'object'),
  fertig_am timestamptz not null default now(),
  primary key (runde, user_id, nr),
  foreign key (runde, user_id) references public.gemeinsam_teilnehmer (runde, user_id) on delete cascade
);

alter table public.gemeinsam_runden     enable row level security;
alter table public.gemeinsam_teilnehmer enable row level security;
alter table public.gemeinsam_seiten     enable row level security;
revoke all on table public.gemeinsam_runden, public.gemeinsam_teilnehmer, public.gemeinsam_seiten
  from anon, authenticated;

-- Die letzte Person nimmt die Runde mit – egal ob sie geht oder ihr Konto
-- löscht.
create or replace function public.gemeinsam_teilnehmer_weg()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.gemeinsam_runden r
   where r.id = old.runde
     and not exists (select 1 from public.gemeinsam_teilnehmer t where t.runde = old.runde);
  return old;
end;
$$;
drop trigger if exists gemeinsam_teilnehmer_weg on public.gemeinsam_teilnehmer;
create trigger gemeinsam_teilnehmer_weg after delete on public.gemeinsam_teilnehmer
  for each row execute function public.gemeinsam_teilnehmer_weg();

-- Zufällige Zeichenkette aus einem Alphabet (Codes und Kennungen).
create or replace function public.gemeinsam_zufall(p_n integer, p_alphabet text)
returns text
language sql
volatile
set search_path = ''
as $$
  select string_agg(substr(p_alphabet, get_byte(uuid_send(gen_random_uuid()), 0) % length(p_alphabet) + 1, 1), '')
  from generate_series(1, p_n);
$$;

-- Anzeigename: Leerraum zusammengezogen, 2–24 Zeichen, ohne Steuerzeichen
-- und spitze Klammern.
create or replace function public.gemeinsam_name(p_name text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if length(v) < 2 or length(v) > 24 or v ~ '[[:cntrl:]<>]' then
    raise exception 'Name 2–24 Zeichen' using errcode = '23514';
  end if;
  return v;
end;
$$;

create or replace function public.gemeinsam_angemeldet()
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'nicht angemeldet' using errcode = '42501';
  end if;
end;
$$;

-- Runde starten: Code wird ausgewürfelt, die Person ist das erste Mitglied.
create or replace function public.gemeinsam_starten(p_pruefung text, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
  v_code text;
  v_id   uuid;
begin
  perform public.gemeinsam_angemeldet();
  v_name := public.gemeinsam_name(p_name);
  if coalesce(p_pruefung, '') !~ '^P-[A-Z]{2,3}-[0-9]{8}$' then
    raise exception 'unbekannte Prüfung' using errcode = '22023';
  end if;
  delete from public.gemeinsam_runden where aktiv_am < now() - interval '30 days';
  if (select count(*) from public.gemeinsam_teilnehmer where user_id = auth.uid()) >= 10 then
    raise exception 'höchstens 10 Runden' using errcode = 'P0004';
  end if;
  loop
    v_code := public.gemeinsam_zufall(6, 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789');
    exit when not exists (select 1 from public.gemeinsam_runden where code = v_code);
  end loop;
  insert into public.gemeinsam_runden (code, pruefung) values (v_code, p_pruefung) returning id into v_id;
  insert into public.gemeinsam_teilnehmer (runde, user_id, tid, name, farbe)
    values (v_id, auth.uid(), public.gemeinsam_zufall(8, 'abcdefghijkmnpqrstuvwxyz23456789'), v_name, 0);
  return jsonb_build_object('id', v_id, 'code', v_code, 'pruefung', p_pruefung);
end;
$$;

-- Beitreten mit Code (Groß-/Kleinschreibung und Leerzeichen egal). Wer schon
-- dabei ist, kann so seinen Namen ändern.
create or replace function public.gemeinsam_beitreten(p_code text, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code  text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_name  text;
  v_r     public.gemeinsam_runden%rowtype;
  v_farbe smallint;
  v_tid   text;
begin
  perform public.gemeinsam_angemeldet();
  v_name := public.gemeinsam_name(p_name);
  select * into v_r from public.gemeinsam_runden where code = v_code;
  if not found then
    perform pg_sleep(0.5);
    raise exception 'Runde nicht gefunden' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.gemeinsam_teilnehmer where runde = v_r.id and user_id = auth.uid()) then
    update public.gemeinsam_teilnehmer set name = v_name where runde = v_r.id and user_id = auth.uid();
  else
    if (select count(*) from public.gemeinsam_teilnehmer where user_id = auth.uid()) >= 10 then
      raise exception 'höchstens 10 Runden' using errcode = 'P0004';
    end if;
    -- Gleichzeitige Beitritte nacheinander, damit Platz und Farbe stimmen.
    perform 1 from public.gemeinsam_runden where id = v_r.id for update;
    if (select count(*) from public.gemeinsam_teilnehmer where runde = v_r.id) >= 6 then
      raise exception 'Runde voll' using errcode = 'P0005';
    end if;
    select min(f) into v_farbe from generate_series(0, 5) f
     where f not in (select t.farbe from public.gemeinsam_teilnehmer t where t.runde = v_r.id);
    loop
      v_tid := public.gemeinsam_zufall(8, 'abcdefghijkmnpqrstuvwxyz23456789');
      exit when not exists (select 1 from public.gemeinsam_teilnehmer where runde = v_r.id and tid = v_tid);
    end loop;
    insert into public.gemeinsam_teilnehmer (runde, user_id, tid, name, farbe)
      values (v_r.id, auth.uid(), v_tid, v_name, v_farbe);
  end if;
  update public.gemeinsam_runden set aktiv_am = now() where id = v_r.id;
  return jsonb_build_object('id', v_r.id, 'code', v_r.code, 'pruefung', v_r.pruefung);
end;
$$;

-- Stand einer Runde – nur für ihre Mitglieder (sonst null). Antworten und
-- Punkte anderer zu einer Aufgabe nur, wenn man selbst mit ihr fertig ist.
create or replace function public.gemeinsam_stand(p_runde uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ich text;
  v_r   public.gemeinsam_runden%rowtype;
begin
  perform public.gemeinsam_angemeldet();
  select tid into v_ich from public.gemeinsam_teilnehmer where runde = p_runde and user_id = auth.uid();
  if v_ich is null then
    return null;
  end if;
  select * into v_r from public.gemeinsam_runden where id = p_runde;
  return jsonb_build_object(
    'id', v_r.id, 'code', v_r.code, 'pruefung', v_r.pruefung, 'ich', v_ich,
    'teilnehmer', coalesce((
      select jsonb_agg(jsonb_build_object('tid', t.tid, 'name', t.name, 'farbe', t.farbe) order by t.seit, t.tid)
        from public.gemeinsam_teilnehmer t where t.runde = p_runde), '[]'::jsonb),
    'seiten', coalesce((
      select jsonb_agg(jsonb_build_object(
               'nr', s.nr, 'tid', t.tid, 'fertig_am', s.fertig_am,
               'punkte',    case when sichtbar then s.punkte end,
               'antworten', case when sichtbar then s.antworten end)
             order by s.nr, t.seit, t.tid)
        from public.gemeinsam_seiten s
        join public.gemeinsam_teilnehmer t on t.runde = s.runde and t.user_id = s.user_id
        cross join lateral (select s.user_id = auth.uid() or exists (
            select 1 from public.gemeinsam_seiten m
             where m.runde = p_runde and m.user_id = auth.uid() and m.nr = s.nr) as sichtbar) x
       where s.runde = p_runde), '[]'::jsonb));
end;
$$;

-- Eine Aufgabe ist fertig: Antworten festschreiben. Ein zweiter Aufruf (etwa
-- nach einem Verbindungsabbruch) ändert nichts mehr.
create or replace function public.gemeinsam_fertig(p_runde uuid, p_nr integer, p_antworten jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.gemeinsam_angemeldet();
  if not exists (select 1 from public.gemeinsam_teilnehmer where runde = p_runde and user_id = auth.uid()) then
    raise exception 'nicht in der Runde' using errcode = 'P0002';
  end if;
  if p_nr is null or p_nr < 1 or p_nr > 30 or jsonb_typeof(p_antworten) is distinct from 'object'
     or octet_length(p_antworten::text) > 400000 then
    raise exception 'ungültige Antworten' using errcode = '22023';
  end if;
  insert into public.gemeinsam_seiten (runde, user_id, nr, antworten)
    values (p_runde, auth.uid(), p_nr, p_antworten)
    on conflict (runde, user_id, nr) do nothing;
  update public.gemeinsam_runden set aktiv_am = now() where id = p_runde;
end;
$$;

-- Eigene Punkte einer fertigen Aufgabe (ersetzt die bisherigen).
create or replace function public.gemeinsam_punkte(p_runde uuid, p_nr integer, p_punkte jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.gemeinsam_angemeldet();
  if jsonb_typeof(p_punkte) is distinct from 'object' or octet_length(p_punkte::text) > 4000
     or exists (select 1 from jsonb_each(p_punkte) e
                 where case when jsonb_typeof(e.value) = 'number'
                            then (e.value)::numeric < 0 or (e.value)::numeric > 100
                            else true end) then
    raise exception 'ungültige Punkte' using errcode = '22023';
  end if;
  update public.gemeinsam_seiten set punkte = p_punkte
   where runde = p_runde and user_id = auth.uid() and nr = p_nr;
  if not found then
    raise exception 'Aufgabe noch nicht fertig' using errcode = 'P0002';
  end if;
  update public.gemeinsam_runden set aktiv_am = now() where id = p_runde;
end;
$$;

-- Eigene Runden, zuletzt aktive zuerst.
create or replace function public.gemeinsam_meine()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', r.id, 'code', r.code, 'pruefung', r.pruefung, 'aktiv_am', r.aktiv_am,
           'fertig', (select count(*) from public.gemeinsam_seiten s where s.runde = r.id and s.user_id = auth.uid()),
           'teilnehmer', (select jsonb_agg(jsonb_build_object('name', t.name, 'farbe', t.farbe, 'ich', t.user_id = auth.uid())
                                           order by t.seit, t.tid)
                            from public.gemeinsam_teilnehmer t where t.runde = r.id))
         order by r.aktiv_am desc, r.id), '[]'::jsonb)
  from public.gemeinsam_runden r
  where exists (select 1 from public.gemeinsam_teilnehmer m where m.runde = r.id and m.user_id = auth.uid());
$$;

-- Runde verlassen; die eigenen Antworten gehen mit.
create or replace function public.gemeinsam_verlassen(p_runde uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.gemeinsam_angemeldet();
  delete from public.gemeinsam_teilnehmer where runde = p_runde and user_id = auth.uid();
end;
$$;

-- Rechte: nur angemeldete Personen, Hilfsfunktionen gar nicht von außen.
revoke all on function public.gemeinsam_teilnehmer_weg()                from public, anon, authenticated;
revoke all on function public.gemeinsam_zufall(integer, text)           from public, anon, authenticated;
revoke all on function public.gemeinsam_name(text)                      from public, anon, authenticated;
revoke all on function public.gemeinsam_angemeldet()                    from public, anon, authenticated;
revoke all on function public.gemeinsam_starten(text, text)             from public, anon, authenticated;
revoke all on function public.gemeinsam_beitreten(text, text)           from public, anon, authenticated;
revoke all on function public.gemeinsam_stand(uuid)                     from public, anon, authenticated;
revoke all on function public.gemeinsam_fertig(uuid, integer, jsonb)    from public, anon, authenticated;
revoke all on function public.gemeinsam_punkte(uuid, integer, jsonb)    from public, anon, authenticated;
revoke all on function public.gemeinsam_meine()                         from public, anon, authenticated;
revoke all on function public.gemeinsam_verlassen(uuid)                 from public, anon, authenticated;
grant execute on function public.gemeinsam_starten(text, text)          to authenticated;
grant execute on function public.gemeinsam_beitreten(text, text)        to authenticated;
grant execute on function public.gemeinsam_stand(uuid)                  to authenticated;
grant execute on function public.gemeinsam_fertig(uuid, integer, jsonb) to authenticated;
grant execute on function public.gemeinsam_punkte(uuid, integer, jsonb) to authenticated;
grant execute on function public.gemeinsam_meine()                      to authenticated;
grant execute on function public.gemeinsam_verlassen(uuid)              to authenticated;
