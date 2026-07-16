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

## So funktioniert der Sync
- Beim Anmelden: Cloud-Stand laden → mit lokalem **zusammenführen** (je Frage
  gewinnt der weiter fortgeschrittene Datensatz: höhere Leitner-Box, dann mehr
  gesehen/richtig) → Ergebnis zurückschreiben.
- Danach: jede Änderung wird entprellt automatisch hochgeladen.
- Offline bleibt alles lokal erhalten und wird beim nächsten Login abgeglichen.

## Apple-Login später
Die Auth-Architektur ist anbieter-offen (`AuthService`). „Sign in with Apple"
lässt sich analog ergänzen (Supabase-Provider Apple + `sign_in_with_apple`),
benötigt aber einen Apple-Developer-Account (99 €/Jahr).
