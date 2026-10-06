# Login (Google) + geräteübergreifender Fortschritt – Supabase

Nach der Einrichtung meldet sich der Nutzer per **Google** an; sein Lernfortschritt
wird in Supabase gespeichert und auf jedem Gerät zusammengeführt. Ohne die unten
genannten Werte läuft die App als **Offline-App** (kein Login-Knopf) – der Build
bleibt in jedem Fall grün.

> **Datenschutzerklärung:** [`datenschutz.html`](datenschutz.html) (Web und Android, verlinkt in der
> App unter Konto). Die Hinweise „In der Datenschutzerklärung ergänzen“ in den Abschnitten unten sind
> dort eingearbeitet (Stand Oktober 2026). Neue Cloud-Funktionen dort nachtragen, bevor sie live gehen.

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
     for select to authenticated
     using ((select auth.uid()) = user_id);
   create policy "own progress insert" on public.progress
     for insert to authenticated
     with check ((select auth.uid()) = user_id);
   create policy "own progress update" on public.progress
     for update to authenticated
     using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
   ```
   Damit sieht und ändert jede Person nur ihren eigenen Fortschritt.
   - `(select auth.uid())` wertet die Anmeldung einmal je Abfrage aus statt für jede Zeile.
     Das empfiehlt der Supabase-Advisor („Auth RLS Initialization Plan“).
   - `to authenticated` beschränkt die Regeln auf angemeldete Konten.

   Wer die Regeln noch in der älteren Fassung (`auth.uid() = user_id`, ohne Rolle) angelegt
   hat, zieht sie so nach, ohne dass die Tabelle zwischendurch ohne Regeln ist:
   ```sql
   alter policy "own progress read" on public.progress
     to authenticated using ((select auth.uid()) = user_id);
   alter policy "own progress insert" on public.progress
     to authenticated with check ((select auth.uid()) = user_id);
   alter policy "own progress update" on public.progress
     to authenticated
     using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
   ```

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
im Supabase-SQL-Editor angelegt (Abschnitte 1 und 5 bis 9). Bis dahin blendet die Web-App
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
sieht:
- die Top 10 der Woche nach beantworteten Fragen, mit dem eigenen Platz
- wie viele Teilnehmende bei der Prüfungsreife hinter einem liegen
- umschaltbar die **Prüfungsrangliste:** die meisten bestandenen Original-Prüfungen
  (je Prüfung zählt der erste vollständig bewertete Durchgang), bei Gleichstand der
  bessere Schnitt, dazu die Bestehenschance

Freigeschaltet wird das mit **einem** SQL-Skript im Supabase-SQL-Editor:
[`docs/supabase-rangliste.sql`](docs/supabase-rangliste.sql). Es lässt sich
gefahrlos erneut ausführen. Solange es fehlt, blenden Web-App und App den
Vergleich einfach aus.

Datenschutz, eingebaut:
- **Opt-in:** Ohne ausdrücklichen Beitritt wird nichts geteilt.
- **Nur Kennzahlen:** Andere sehen Spitzname, Prüfungsreife in %, Antworten dieser
  Woche, Lerntage in Folge und die Prüfungsergebnisse (gewertete und bestandene
  Prüfungen, Ø-Punkte, Bestehenschance). Keine E-Mail, kein Klarname, keine Nutzer-ID.
- **Kein Direktzugriff:** Die Tabelle `rangliste` ist für Clients gesperrt.
  Lesen und Schreiben laufen über sechs Funktionen (`rangliste_melden`,
  `rangliste_stand`, `rangliste_austreten`, `rangliste_info`, `pruefungen_melden`,
  `rangliste_pruefungen`).
- **Plausibel begrenzt:** Die Funktionen deckeln die gemeldeten Werte.
- **Austreten löscht den Eintrag.** Wer sein Konto löscht, verliert ihn ebenfalls
  (`on delete cascade`).

**Bestehende Projekte nachziehen:** Wer die Rangliste schon eingerichtet hat, führt
nacheinander erneut aus: `docs/supabase-rangliste.sql` (neue Spalten und Funktionen für
die Prüfungswerte), dann – falls genutzt – `docs/supabase-gruppen.sql` und
`docs/supabase-profile.sql` (Prüfungswerte in Gruppen, Freundeslisten und Profilen). Alle
drei lassen sich gefahrlos erneut ausführen; die Reihenfolge ist wichtig, weil Gruppen und
Profile die neuen Spalten lesen.

Vor dem Freischalten in der **Datenschutzerklärung** und im
**Play-Datenschutzformular** ergänzen:
- was geteilt wird: Spitzname und Lernkennzahlen samt Prüfungsergebnissen, nur nach Beitritt
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
  - Prüfungsergebnisse je Prüfungsbereich (gewertet, bestanden, Ø-Punkte, Chance)
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

## 9. Prüfungsergebnisse auf allen Geräten (optional)

Jede ausgewertete Original-Prüfung wird als **Durchgang** gespeichert: Punkte, wie viele
Teilaufgaben bewertet sind, ob unter Prüfungsbedingungen, Bearbeitungszeit. Keine
Antworten. Daraus rechnen Web-App und App die Übersicht (bestanden oder nicht je Prüfung
und Bereich) und die Bestehenschance.

Ohne Konto bleiben die Durchgänge auf dem Gerät. Mit [`docs/supabase-pruefungen.sql`](docs/supabase-pruefungen.sql)
werden sie beim Anmelden und nach jeder Auswertung mit der Cloud abgeglichen, sodass
Übersicht, Chance und Rangliste auf jedem Gerät gleich sind. Das Skript ist unabhängig von
den Abschnitten 5 bis 8 und lässt sich gefahrlos erneut ausführen.

- **Nur die eigene Person** liest und schreibt ihre Durchgänge, und zwar über
  `pruefungen_abgleichen`. Die Tabelle `pruefung_ergebnisse` ist für Clients gesperrt.
- **Abgleich:** Das Gerät sendet, was seit dem letzten Abgleich bewertet wurde. Zurück kommen
  alle eigenen Durchgänge. Meldet ein zweites Gerät denselben Durchgang, gilt die zuletzt
  bewertete Fassung (Feld `g`).
- **Begrenzt:** höchstens 500 Durchgänge je Aufruf, je Konto die 1000 jüngsten. Ungültige
  Werte werden übersprungen.
- **Aufräumen:** Wer sein Konto löscht, verliert die Durchgänge (`on delete cascade`).

In der **Datenschutzerklärung** ergänzen: Ergebnisse der Übungsprüfungen (Punkte, Datum,
Bearbeitungszeit) werden zum geräteübergreifenden Abgleich gespeichert.

## 10. Gemeinsam lernen (optional)

Zwei bis sechs Personen lösen dieselbe Original-Prüfung, jede für sich, Aufgabe für
Aufgabe. Unter jeder Teilaufgabe sieht man als Sterne, wie die anderen gerade schreiben –
ohne Inhalt. Ist man mit einer Aufgabe fertig, wird sie festgeschrieben und verglichen:
eigene Antwort, die der anderen (sobald sie auch fertig sind) und die Lösung, dazu ein
Prüfauftrag für Claude mit allen Antworten.

Freigeschaltet wird das mit [`docs/supabase-gemeinsam.sql`](docs/supabase-gemeinsam.sql).
Das Skript ist unabhängig von den Abschnitten 5 bis 9 und lässt sich gefahrlos erneut
ausführen. Solange es fehlt, blendet die Web-App „Gemeinsam lösen“ aus, sobald jemand
angemeldet ist.

- **Runden mit Code:** Wer startet, bekommt einen 6-stelligen Code (ohne 0/O/1/I); die
  anderen treten mit dem Code oder dem Link `…#gemeinsam=CODE` bei. Höchstens 6 Personen je
  Runde und 10 Runden je Person.
- **Nur über Funktionen:** Die Tabellen `gemeinsam_runden`, `gemeinsam_teilnehmer` und
  `gemeinsam_seiten` sind für Clients gesperrt. Antworten anderer zu einer Aufgabe gibt
  `gemeinsam_stand` erst heraus, wenn man selbst mit dieser Aufgabe fertig ist. Die
  Konto-ID der anderen sieht niemand, nur eine Kennung je Runde.
- **Sterne:** Was gerade geschrieben wird, geht nicht über die Datenbank, sondern über
  Supabase Realtime (öffentlicher Kanal `gemeinsam:<Runden-ID>`, Broadcast und Presence) –
  als Sterne (Ereignis `maske`). Realtime muss im Projekt aktiv sein (Standard).
- **Geschriebenes zeigen (Klartext):** Ein Schalter im Aufgabenblatt, je Person und Runde
  gemerkt (`kvm_gm_<Runde>_offen`).
  - Eingeschaltet geht zusätzlich der Text über den Kanal (Ereignis `klartext`:
    `{id, nr, t, r}`; `{aus:1}` beim Ausschalten).
  - Die Anwesenheit meldet den Schalter mit (`{nr, offen, v:2}`).
  - Angezeigt wird Klartext nur, wenn beide Seiten eingeschaltet haben.
  - Ohne Datenbank-Änderung: Ältere Versionen kennen `klartext` nicht und zeigen weiter
    Sterne. Das Update lässt sich deshalb mitten in einer laufenden Runde einspielen.
  - Wer die alte Version hat (kein `v`), bekommt in der neuen einen Hinweis.
- **Neue Version im Betrieb:**
  - Die Web-App erkennt eine neue `index.html` auf dem Server (ETag) und bietet „Neu laden“
    an.
  - Eine offene Runde öffnet sich nach dem Neuladen in derselben Registerkarte von selbst
    wieder (`sessionStorage`). ✕ beendet das.
- **Aufräumen:** Wer eine Runde verlässt oder das Konto löscht, nimmt die eigenen Antworten
  mit; die letzte Person nimmt die Runde mit. Runden ohne Aktivität seit 30 Tagen löscht der
  nächste Start einer Runde.

In der **Datenschutzerklärung** ergänzen: Für gemeinsame Runden werden Anzeigename und die
Antworten fertiger Aufgaben gespeichert und den anderen Mitgliedern der Runde gezeigt. Mit
„Geschriebenes zeigen“ geht der Text auch während des Schreibens live an die Runde, sichtbar
nur für Mitglieder mit eingeschaltetem Schalter und nicht gespeichert (eingearbeitet in
`datenschutz.html`).

## 11. Original-IHK-Prüfungen nur mit Freigabe (nötig für die Prüfungen)

Die Original-Prüfungen – Aufgaben, amtliche Lösungshinweise und Bildanlagen – stehen nicht
mehr im Repository. Wer es klont, bekommt nur die eigenen Fragen und Fallaufgaben. Die
Prüfungen liegen im privaten Storage-Bucket `pruefungen`. Die Web-App lädt sie erst, wenn
ein Admin die angemeldete Person freigegeben hat.

**Einrichten (einmal):**
1. **SQL:** Im SQL-Editor [`docs/supabase-pruefungen-freigabe.sql`](docs/supabase-pruefungen-freigabe.sql)
   ausführen, nach [`docs/supabase-profile.sql`](docs/supabase-profile.sql) (Abschnitt 8,
   wegen Admins und Protokoll).
   - Legt die Tabelle `pruefungen_freigaben`, die Funktionen, den privaten Bucket
     `pruefungen` (höchstens 20 MB je Datei) und dessen Policies an.
   - Lässt sich gefahrlos erneut ausführen.
2. **Hochladen:** Das private Paket (`privat/hochladen/`, nicht im Repository) hochladen.
   - **In der Web-App** als Admin: Verwaltung › Prüfungen › „Ordner wählen“ → den Ordner
     `hochladen` wählen → hochladen. Erst die Bilder, dann `pruefungen.json`.
   - **Oder im Dashboard:** Storage › `pruefungen` → `pruefungen.json` ins Hauptverzeichnis,
     die Bilder in den Ordner `anlagen/`.
3. **Freigeben:** Wer die Prüfungen nutzen will, fragt sie in der Web-App unter „Prüfungen“ an.
   - Admins entscheiden in der Verwaltung unter „Prüfungen“ oder in den Details einer Person:
     freigeben, ablehnen, zurücknehmen, Anfrage löschen.
   - Vorab freigeben, ohne Anfrage: SQL-Schnipsel im Kopf der SQL-Datei.
   - Admins haben immer Zugriff.

**So funktioniert es:**
- **Nur über Funktionen:** Die Tabelle ist für Clients gesperrt.
  - `pruefungen_status()` liefert den eigenen Stand. Ist die Person frei, kommt der Zeitpunkt
    der hochgeladenen `pruefungen.json` mit.
  - `pruefungen_anfragen(p_nachricht)` stellt die Anfrage; die Nachricht ist freiwillig
    (höchstens 300 Zeichen).
  - `admin_pruefungen()` und `admin_pruefungen_freigabe(p_user, p_status)` gibt es nur für Admins.
    Jede Entscheidung steht im Protokoll der Verwaltung.
- **Bucket:** Lesen dürfen nur freigegebene Personen und Admins (`pruefungen_zugang()`).
  Hochladen, Ersetzen und Löschen dürfen nur Admins.
- **Laden:** Die Web-App holt `pruefungen.json` mit dem Anmelde-Token. Die Bilder kommen über
  signierte Links, die 12 h gelten.
- **Kopie im Browser:** Eine Kopie für das angemeldete Konto liegt in IndexedDB
  (`kvm_pruefungen`). So startet die Seite schnell und geht auch offline.
  - Neu geladen wird nur, wenn auf dem Server ein neuerer Stand liegt.
  - Abmelden, Kontowechsel oder eine zurückgenommene Freigabe löschen die Kopie.
- **Neuer Stand:** Einfach eine neue `pruefungen.json` hochladen. Freigegebene Geräte holen sie
  beim nächsten Öffnen.
- **Ohne das SQL** zeigt die Web-App „Freigabe noch nicht eingerichtet“ und keine Prüfungen.
- **Native App:** Sie bündelt keine Prüfungen mehr. Die Freigabe dort beschreibt FR-020 in
  `APP_FEATURE_REQUESTS.md`; bis dahin verweist die App auf die Web-App.
- **Pflege der Prüfungen:** `tools/webdaten.py` trennt beim Schreiben automatisch. Prüfungen gehen
  ins private Paket, eigene Fälle nach `data/cases.js`. Werkzeuge dazu liegen in `privat/pipeline/`.
- **Aufräumen:** Wer sein Konto löscht, verliert die Freigabe (`on delete cascade`).

**Ältere Stände:** Die Git-Historie ist seit dem 6. Oktober 2026 umgeschrieben und enthält die
Prüfungen nicht mehr. Ältere Commits bleiben bei GitHub noch über alte Pull-Request-Ansichten
erreichbar, bis der GitHub-Support sie entfernt.

In der **Datenschutzerklärung** ist das eingearbeitet (`datenschutz.html#pruefungen`): Anfrage,
Nachricht und Entscheidung werden gespeichert, die Admins sehen dazu Name und E-Mail-Adresse.
Die Kopie der Prüfungen bleibt im Browser.

## 12. KI-Auswertung der Original-Prüfungen (optional)

Original-Prüfungen zeigen Lösungen und Auswertung erst nach der Abgabe, wie in der Prüfung. Danach
bewertet man sich selbst oder tippt „Mit KI auswerten“: Claude Sonnet 5.5 vergibt je Teilaufgabe
Punkte nach dem Lösungshinweis und begründet sie kurz. Der API-Key liegt nur bei Supabase.

**Einrichten (einmal):**
1. **SQL:** Im SQL-Editor [`docs/supabase-ki-auswertung.sql`](docs/supabase-ki-auswertung.sql) ausführen,
   nach Abschnitt 8 (Admins) und 11 (Freigabe).
   - Legt die Tabelle `ki_auswertungen` und die Funktionen an.
   - Lässt sich gefahrlos erneut ausführen.
2. **API-Key:** In der [Anthropic Console](https://console.anthropic.com) einen API-Key anlegen, am
   besten mit einem monatlichen Ausgabenlimit.
   - Im Supabase-Dashboard unter **Edge Functions › Secrets** als `ANTHROPIC_API_KEY` speichern.
   - Nirgendwo sonst: nicht ins Repository, nicht in die App, nicht in einen Chat.
3. **Funktion bereitstellen:** `supabase/functions/pruefung-auswerten` mit `index.ts` und `kern.ts`.
   - Mit der Supabase-CLI: `supabase functions deploy pruefung-auswerten --project-ref iarekdxkutwfidzgvyuy`
   - Oder im Dashboard: **Edge Functions › Deploy a new function › Via Editor**, Name
     `pruefung-auswerten`, beide Dateien anlegen.
   - „Verify JWT“ eingeschaltet lassen: Nur angemeldete Personen dürfen die Funktion aufrufen.
4. **Prüfen:** Eine Prüfung abgeben und „Mit KI auswerten“ tippen. In der Verwaltung unter
   „Prüfungen“ steht die Nutzung.

**So funktioniert es:**
- **Ablauf:** Die App ruft die Funktion zuerst mit `beginnen` auf. Das prüft Freigabe und Tageslimit
  und legt die Auswertung an. Danach schickt die App je Aufgabe einen Aufruf mit den Antworten:
  Text, Rechenweg, Eintragungen in Anlagen, Skizzen als JPEG.
  - Je Aufruf bewertet Claude eine Aufgabe. So bleibt jede Anfrage unter der Zeitgrenze der Edge
    Functions (150 s), und die App zeigt den Fortschritt. Zwei Aufgaben laufen gleichzeitig.
  - Die Funktion holt Aufgaben, Lösungshinweise und Abbildungen selbst aus dem Bucket `pruefungen`.
    Die App schickt nur die Antworten.
  - Leere Aufgaben bekommen 0 Punkte, ohne dass Claude gefragt wird.
- **Modell:** fest `claude-sonnet-5-5`, kein Ausweichen auf ein anderes Modell.
  - `effort: high`, höchstens 8000 Tokens je Aufgabe.
  - Die Antwort kommt als JSON nach festem Schema. Punkte werden auf 0 bis zur Höchstpunktzahl
    begrenzt; unbekannte Teilaufgaben werden ignoriert.
- **Tageslimit:** 5 Auswertungen je Person und Kalendertag (Europe/Berlin), Admins ohne Limit.
  - Eine Auswertung ist eine Prüfung und zählt einmal, egal wie viele Aufgaben sie hat.
  - Erneutes Starten innerhalb von 30 Minuten setzt die laufende Auswertung fort und zählt nicht
    noch einmal, etwa für fehlende Aufgaben.
  - Eine Auswertung ohne eine einzige bewertete Aufgabe zählt nach 30 Minuten nicht mehr.
  - Je Aufgabe höchstens drei Aufrufe, Wiederholungen nach Fehlern eingerechnet.
  - Ändern: `ki_tageslimit()` mit anderem Wert neu anlegen.
- **Gespeichert:** in `ki_auswertungen` nur Konto, Prüfung, Zeit, Punkte je Aufgabe, Tokens und der
  letzte Fehler, keine Antworten. Die Begründungen bleiben im Browser (`kvm_ki`).
  - Die Tabelle ist für Clients gesperrt. `ki_status()` gibt der App den eigenen Stand,
    `admin_ki_auswertungen()` den Admins die Übersicht.
  - Beginnen und Eintragen darf nur die Funktion (`service_role`).
  - Wer sein Konto löscht, verliert die Einträge (`on delete cascade`).
- **Kosten:** Die Verwaltung zeigt unter „Prüfungen“ die Tokens der letzten 30 Tage und schätzt die
  Kosten. Grundlage: 2 US-$ je Million Eingabe- und 10 US-$ je Million Ausgabe-Tokens.
  - Eine ganze Prüfung kostet grob 0,10 bis 0,30 US-$; den größten Teil macht das Nachdenken von
    Claude aus.
- **Fehler:**
  - Ohne Secret antwortet die Funktion „nicht eingerichtet“; die App blendet die KI dann aus.
  - Bei Überlastung (429/529) wartet die App die angegebene Zeit und versucht es erneut, dann nur
    noch eine Aufgabe zur Zeit.
  - Was danach noch fehlt, holt „Fehlende auswerten“ nach. Selbst bewerten geht immer.
- **Ohne das SQL** zeigt die Web-App nach der Abgabe nur die Selbstbewertung.
- **Tests:** `deno test --allow-read supabase/functions/pruefung-auswerten/kern_test.ts` prüft die Funktion
  mit den erfundenen Beispielprüfungen und einem simulierten Claude – ohne Datenbank und ohne API-Key.
- **Native App:** FR-021 in `APP_FEATURE_REQUESTS.md`.

In der **Datenschutzerklärung** steht das unter `datenschutz.html#ki`: Was an Anthropic geht (nur
nach dem Tippen, ohne Name und E-Mail-Adresse) und was in der Datenbank bleibt. Der Vertrag zur
Auftragsverarbeitung mit Anthropic ist Teil der kommerziellen Bedingungen von Anthropic. Bitte vor
dem Einschalten selbst prüfen, ob er für das eigene Konto gilt.

## Apple-Login später
Die Auth-Architektur ist anbieter-offen (`AuthService`). „Sign in with Apple"
lässt sich analog ergänzen (Supabase-Provider Apple + `sign_in_with_apple`),
benötigt aber einen Apple-Developer-Account (99 €/Jahr).
