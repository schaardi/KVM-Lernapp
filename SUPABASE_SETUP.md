# Login (Google) + geräteübergreifender Fortschritt – Supabase

Nach der Einrichtung meldet sich der Nutzer per **Google** an; sein Lernfortschritt
wird in Supabase gespeichert und auf jedem Gerät zusammengeführt. Ohne die unten
genannten Werte läuft die App als **Offline-App** (kein Login-Knopf) – der Build
bleibt in jedem Fall grün.

Die App braucht drei Werte, injiziert per `--dart-define` (in den Build-Workflows
aus GitHub-Secrets):

| Secret | Woher |
|--------|-------|
| `SUPABASE_URL` | Supabase → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API → `anon` `public` key |
| `GOOGLE_WEB_CLIENT_ID` | Google Cloud → OAuth-Client (Typ **Web**) Client-ID |

## 1. Supabase-Projekt
1. Projekt anlegen auf https://supabase.com (Free-Tier genügt).
2. Tabelle + Rechte anlegen (SQL-Editor):
   ```sql
   create table if not exists public.progress (
     user_id    uuid primary key references auth.users(id) on delete cascade,
     data       jsonb not null default '{}'::jsonb,
     updated_at timestamptz not null default now()
   );
   alter table public.progress enable row level security;

   create policy "own progress read"   on public.progress
     for select using (auth.uid() = user_id);
   create policy "own progress insert" on public.progress
     for insert with check (auth.uid() = user_id);
   create policy "own progress update" on public.progress
     for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
   ```
   Damit sieht/ändert jeder nur seinen eigenen Fortschritt.

## 2. Google-Login einrichten
1. **Google Cloud Console** → *APIs & Dienste → Anmeldedaten*:
   - **OAuth-Client „Web"** anlegen → das ist `GOOGLE_WEB_CLIENT_ID`.
     Bei *Authorized redirect URIs* die Supabase-Callback-URL eintragen:
     `https://<dein-projekt>.supabase.co/auth/v1/callback`.
   - **OAuth-Client „Android"** anlegen: Paketname `com.kvmtrainer.kvm_trainer`
     (bzw. deine finale Application ID) + **SHA-1-Fingerprint** des Signaturschlüssels
     (siehe unten). Diese Client-ID wird nicht im Code referenziert – Google
     ordnet den Login über Paketname + SHA-1 zu.
2. **Supabase** → *Authentication → Providers → Google* aktivieren und die
   **Web-Client-ID + Client-Secret** eintragen.

### SHA-1-Fingerprints (wichtig!)
Der Google-Login funktioniert nur, wenn der SHA-1 des tatsächlich verwendeten
Signaturschlüssels bei Google hinterlegt ist:
- **Sideload/`android-latest` (debug-signiert):**
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
  In CI wird mit dem Debug-Key signiert – den zugehörigen SHA-1 eintragen (bzw.
  lokal denselben debug.keystore verwenden).
- **Google Play:** zusätzlich den SHA-1 aus *Play Console → Setup → App-Signatur*
  (Play-App-Signing-Zertifikat **und** Upload-Zertifikat) hinterlegen.

## 3. GitHub-Secrets setzen
Repo → *Settings → Secrets and variables → Actions*: die drei Werte aus der
Tabelle oben als Secrets anlegen. Beim nächsten Build werden sie per
`--dart-define` eingebaut, der Login-Knopf erscheint automatisch.

## 4. Fertig
- Lokal testen:
  ```bash
  flutter run \
    --dart-define=SUPABASE_URL=... \
    --dart-define=SUPABASE_ANON_KEY=... \
    --dart-define=GOOGLE_WEB_CLIENT_ID=...
  ```
- In der App: Kategorie-Auswahl → Konto-Symbol oben rechts → **Mit Google anmelden**.
  Der Fortschritt wird beim Anmelden zusammengeführt und danach automatisch gesichert.

## Web-App (z. B. auf GitHub Pages)
Die Web-App (`index.html`) braucht keinen eigenen Server. Pages liefert nur die
Dateien aus; der Browser spricht direkt mit Supabase. Projekt-URL und `anon`-Schlüssel
stehen in `index.html` (Block „Cloud-Login + Sync“). Der Schlüssel ist öffentlich
gedacht, geschützt wird über RLS.

Damit der Google-Login zur Seite zurückführt, **einmal** in Supabase →
*Authentication → URL Configuration* eintragen:
- **Site URL:** die Pages-Adresse, z. B. `https://<name>.github.io/KVM-Lernapp/`
- **Redirect URLs:** dieselbe Adresse mit `**` am Ende, z. B.
  `https://<name>.github.io/KVM-Lernapp/**`

Fehlt das, landet man nach dem Login auf der voreingestellten Site URL (oft
`localhost`). In der Google Cloud bleibt als Redirect-URI nur die Supabase-Callback-URL
aus Abschnitt 2.

Tabellen und Funktionen kommen **nicht** über Pages. Sie werden einmal per SQL-Skript
im Supabase-SQL-Editor angelegt (Abschnitte 1 und 5 bis 8). Bis dahin blendet die Web-App
die betroffene Funktion aus.

## So funktioniert der Sync
- Beim Anmelden: Cloud-Stand laden → mit lokalem **zusammenführen** (je Frage
  gewinnt der weiter fortgeschrittene Datensatz: höhere Leitner-Box, dann mehr
  gesehen/richtig) → Ergebnis zurückschreiben.
- Danach: jede Änderung wird entprellt automatisch hochgeladen.
- Offline bleibt alles lokal erhalten und wird beim nächsten Login abgeglichen.

## 5. Vergleich mit anderen Lernenden (optional)

Web-App und App können angemeldeten Nutzerinnen und Nutzern eine **freiwillige
Wochenrangliste** zeigen. Man tritt mit einem selbst gewählten Spitznamen bei und
sieht zwei Dinge:
- die Top 10 der Woche nach beantworteten Fragen, mit dem eigenen Platz
- wie viele Teilnehmende bei der Prüfungsreife hinter einem liegen

Freigeschaltet wird das mit **einem** SQL-Skript im Supabase-SQL-Editor:
[`docs/supabase-rangliste.sql`](docs/supabase-rangliste.sql). Es lässt sich
gefahrlos erneut ausführen. Solange es fehlt, blenden Web-App und App den
Vergleich einfach aus.

Datenschutz, eingebaut:
- **Opt-in:** Ohne ausdrücklichen Beitritt wird nichts geteilt.
- **Nur Kennzahlen:** Andere sehen Spitzname, Prüfungsreife in %, Antworten dieser
  Woche und Lerntage in Folge. Keine E-Mail, kein Klarname, keine Nutzer-ID.
- **Kein Direktzugriff:** Die Tabelle `rangliste` ist für Clients gesperrt.
  Lesen und Schreiben laufen über vier Funktionen (`rangliste_melden`,
  `rangliste_stand`, `rangliste_austreten`, `rangliste_info`).
- **Plausibel begrenzt:** Die Funktionen deckeln die gemeldeten Werte.
- **Austreten löscht den Eintrag.** Wer sein Konto löscht, verliert ihn ebenfalls
  (`on delete cascade`).

Vor dem Freischalten in der **Datenschutzerklärung** und im
**Play-Datenschutzformular** ergänzen:
- was geteilt wird: Spitzname und Lernkennzahlen, nur nach Beitritt
- wofür: Vergleich mit anderen Lernenden

## 6. Fehler melden (optional)

An jeder Frage und Teilaufgabe gibt es einen unauffälligen Knopf **„Fehler?“**. Lernende
wählen die Art des Fehlers (Text, Lösung, Rechnung, Anlage, Sonstiges) und schreiben
auf Wunsch dazu, was nicht stimmt. Melden geht auch ohne Konto.

Freigeschaltet wird das mit **einem** SQL-Skript im Supabase-SQL-Editor:
[`docs/supabase-meldungen.sql`](docs/supabase-meldungen.sql). Es lässt sich gefahrlos
erneut ausführen. Solange es fehlt, blenden Web-App und App den Knopf aus.

- **Gespeichert** werden:
  - Fragennummer, Art, Text
  - ein kurzer Kontext: Modus, Fach, die ersten 160 Zeichen der Frage
  - nur bei Anmeldung die Konto-ID, keine IP-Adresse
- **Kein Lesezugriff für Clients:** Geschrieben wird nur über `meldung_senden`; lesen und
  abhaken lassen sich die Meldungen nur im Dashboard.
- **Bremse:** höchstens 50 Meldungen je Konto und Tag, insgesamt 300 je Stunde.

**Auswerten** (Dashboard → SQL-Editor; weitere Beispiele am Ende des Skripts):
```sql
select id, created_at, frage, art, text, kontext->>'auszug' as auszug
from public.meldungen where status = 'neu' order by created_at desc;

update public.meldungen set status = 'erledigt' where id in (1, 2, 3);
```
Die Fragennummer (z. B. `B-MW-901` oder `P-OK-20221115-s3`) findet sich in
`data/questions.js` bzw. `data/cases.js` und in den Korrekturdateien unter
`scripts/pruefungen/`.

In der **Datenschutzerklärung** ergänzen: Meldungen zu Fragen (Inhalt, Kontext und
bei Anmeldung das Konto), Zweck „Fehler in den Lerninhalten beheben“.

## 7. Lerngruppen (optional)

Aufbauend auf der Wochenrangliste (Abschnitt 5) können Lernende **private Gruppen**
gründen, etwa für ihren Meisterkurs. Beigetreten wird mit einem 6-stelligen Code oder
einem Einladungslink (`…/#gruppe=K7M2QX`). In der Gruppe sehen sich die Mitglieder
gegenseitig wie in der Rangliste: Spitzname, Antworten dieser Woche, Prüfungsreife.

Freigeschaltet wird das mit [`docs/supabase-gruppen.sql`](docs/supabase-gruppen.sql),
**nach** `docs/supabase-rangliste.sql` auszuführen. Solange es fehlt, zeigt die
Rangliste keine Gruppen-Reiter.

- **Voraussetzung:** Nur wer der Rangliste beigetreten ist, kann gründen oder beitreten.
- **Grenzen:** höchstens 5 Gruppen je Person und 200 Mitglieder je Gruppe.
- **Codes:** ohne 0/O/1/I. Falsche Codes kosten eine halbe Sekunde, damit sich Codes nicht
  durchprobieren lassen.
- **Aufräumen:**
  - Wer die Rangliste verlässt oder sein Konto löscht, verlässt alle Gruppen.
  - Die letzte Person nimmt die Gruppe mit.
  - Geht die Gründerin, übernimmt das dienstälteste Mitglied.
- **Kein Direktzugriff:** Tabellen `gruppen` und `gruppen_mitglieder` sind gesperrt. Es gibt
  fünf Funktionen: `gruppe_gruenden`, `gruppe_beitreten`, `gruppe_verlassen`,
  `gruppen_meine`, `gruppe_stand`.

In der **Datenschutzerklärung** zur Rangliste ergänzen: In Lerngruppen sehen die
Mitglieder dieselben Angaben wie in der Rangliste, dazu den Gruppennamen.

## 8. Profile, Freunde und Verwaltung (optional)

Aufbauend auf der Wochenrangliste (Abschnitt 5):
- **Nutzerübersicht:** alle, die der Rangliste beigetreten sind, mit Suche nach Spitzname
- **Freunde:** Anfrage und Annahme
- **Profile:** Befreundete sehen gegenseitig den **Lernstand je Fach**
- **Verwaltung für Admins:** Konten, Lernstände, Meldungen und Gruppen einsehen und verwalten

Freigeschaltet wird das mit [`docs/supabase-profile.sql`](docs/supabase-profile.sql),
**nach** `docs/supabase-rangliste.sql` auszuführen. Lerngruppen (Abschnitt 7) und
Meldungen (Abschnitt 6) sind keine Voraussetzung; ohne sie bleiben die Admin-Reiter
dafür leer. Solange das Skript fehlt, sieht die Rangliste aus wie bisher.

**Profile und Freunde**
- **Opt-in:** Ein Profil hat nur, wer der Rangliste beigetreten ist.
- **Für alle Teilnehmenden sichtbar** ist nur, was auch die Rangliste zeigt: Spitzname,
  Prüfungsreife, Antworten dieser Woche, Lerntage in Folge.
- **Nur für Freunde** (einstellbar auf „alle“):
  - Prüfungsreife und gemeisterte Fragen je Fach
  - Aktivität der letzten 14 Tage
  - Lerntage
  - Prüfungen unter Echtbedingungen
- **Freundschaft** braucht Anfrage und Annahme. Abgelehnt wird still; wer abgelehnt wurde,
  kann nicht erneut drängeln. Höchstens 30 offene Anfragen und 50 neue am Tag.
- **Keine Konto-ID nach außen:** Profile haben eine eigene, zufällige Kennung.
- **Aufräumen:** Wer die Rangliste verlässt oder sein Konto löscht, verliert Profil und
  Freundschaften.

**Verwaltung**
- Admins stehen in der Tabelle `admins`. Eintragen (einmal, im SQL-Editor – das Google-Konto
  muss sich vorher einmal angemeldet haben):
  ```sql
  insert into public.admins (user_id)
  select id from auth.users where lower(email) = lower('name@example.com')
  on conflict do nothing;
  ```
- In der Web-App erscheint dann unter **Konto & Einstellungen** die Kachel **Verwaltung**.
  Die Datenbank prüft bei jedem Aufruf, ob wirklich ein Admin angemeldet ist.
- Reiter und Möglichkeiten:
  - **Übersicht:** Kennzahlen und die letzten Verwaltungsaktionen
  - **Nutzer:** alle Konten mit Suche (E-Mail, Name, Spitzname). Je Konto: Anmeldedaten,
    Lernstand je Fach, Rangliste, Profil, Freunde, Gruppen und Meldungen.
  - **Aktionen je Konto:**
    - aus der Rangliste nehmen
    - sperren (raus aus Rangliste, Freunden und Gruppen, kein neuer Beitritt; Lernen und
      Sichern gehen weiter)
    - entsperren
    - Konto endgültig löschen (mit der E-Mail als Bestätigung)
    - Admin-Konten sind von Sperren und Löschen ausgenommen.
  - **Meldungen:** lesen, erledigen, ablehnen, wieder öffnen
  - **Gruppen:** ansehen, löschen
- Jede Verwaltungsaktion steht in `admin_protokoll` (wer, was, wann, welches Konto).
- Das Admin-Konto ist ein Google-Konto: mit **Zwei-Faktor-Anmeldung** schützen, denn es kann
  alle Daten sehen und Konten löschen.

In der **Datenschutzerklärung** ergänzen:
- **Profile und Freunde:** was Freunde bzw. alle Teilnehmenden sehen (siehe oben) und dass
  man die Sichtbarkeit selbst wählt
- **Verwaltung:** Admins können zur Betreuung, Moderation und für Löschanfragen alle
  gespeicherten Angaben einsehen (Konto, Lernstand, Profil, Freunde, Gruppen, Meldungen).
  Sperren und Löschungen werden protokolliert.

## Apple-Login später
Die Auth-Architektur ist anbieter-offen (`AuthService`). „Sign in with Apple"
lässt sich analog ergänzen (Supabase-Provider Apple + `sign_in_with_apple`),
benötigt aber einen Apple-Developer-Account (99 €/Jahr).
