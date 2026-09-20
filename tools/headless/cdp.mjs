// Headless-Prüftreiber für die Web-App (index.html).
//
// Startet das vorinstallierte Chromium ohne Fenster, lädt eine URL, führt ein
// Prüfskript im Seitenkontext aus und druckt dessen Rückgabewert als JSON.
// JS-Ausnahmen, console.error und Ladefehler werden gesammelt und am Ende
// aufgelistet – ein Lauf ohne die Zeile „keine JS-/Ladefehler" ist ein Befund.
//
// Aufruf:
//   node tools/headless/cdp.mjs <URL> <Prüfskript.js | Ausdruck>
//   CDP_GROESSE=560,900 node tools/headless/cdp.mjs <URL> <Skript>   (Handy-Breite)
//   CDP_CHROME=/pfad/zu/chrome ...                                    (anderer Browser)
//
// Das Prüfskript ist ein Ausdruck, gern eine async IIFE, die ein Objekt
// zurückgibt (siehe tools/headless/beispiele/). Es läuft im Fenster der Seite
// und darf alles anfassen: DOM, localStorage, die Brücken window.KVM_*.
//
// Testkopie der App (die Seite lädt data/*.js und anlagen/ relativ):
//   mkdir -p /tmp/kvm-web && cp -r index.html data anlagen /tmp/kvm-web/
//   python3 -m http.server 8099 --directory /tmp/kvm-web &
//   node tools/headless/cdp.mjs http://127.0.0.1:8099/ tools/headless/beispiele/panel-desktop.js
//
// Bekannte Eigenheiten: Headless-Chromium zieht die Fensterleiste ab
// (1280,900 ergibt innerHeight 813) und erzwingt mindestens 500 px Breite –
// für Handy-Prüfungen also die Breite im Skript über innerWidth mitprotokollieren.
// Hinter dem Proxy der Cloud-Sitzung scheitern Supabase-CDN und Google Fonts
// mit ERR_CERT_AUTHORITY_INVALID; diese zwei Ladefehler sind kein Befund.
import { spawn } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';

const CHROME = process.env.CDP_CHROME || '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
const GROESSE = process.env.CDP_GROESSE || '1280,900';
const URL = process.argv[2];
const ARG = process.argv[3];
if (!URL || !ARG) { console.error('Aufruf: node cdp.mjs <URL> <Skript>'); process.exit(2); }
const SKRIPT = existsSync(ARG) ? readFileSync(ARG, 'utf8') : ARG;

const proc = spawn(CHROME, ['--headless=new', '--disable-gpu', '--no-sandbox',
  '--remote-debugging-port=9222', '--window-size=' + GROESSE, 'about:blank'],
  { stdio: ['ignore', 'ignore', 'pipe'] });
let wsUrl = null;
proc.stderr.on('data', b => { const m = /ws:\/\/[^\s]+/.exec(b.toString()); if (m && !wsUrl) wsUrl = m[0]; });
const warte = ms => new Promise(r => setTimeout(r, ms));
for (let i = 0; i < 60 && !wsUrl; i++) await warte(100);
if (!wsUrl) { console.error('Kein DevTools-Endpunkt'); process.exit(1); }

const ws = new WebSocket(wsUrl);
let id = 0; const offen = new Map();
const senden = (method, params = {}, sessionId) => new Promise(res => {
  const m = ++id; offen.set(m, res);
  ws.send(JSON.stringify({ id: m, method, params, ...(sessionId ? { sessionId } : {}) }));
});
const fehler = [];
await new Promise(r => ws.addEventListener('open', r));
ws.addEventListener('message', ev => {
  const msg = JSON.parse(ev.data);
  if (msg.id && offen.has(msg.id)) { offen.get(msg.id)(msg.result); offen.delete(msg.id); }
  if (msg.method === 'Runtime.exceptionThrown')
    fehler.push('JS: ' + (msg.params.exceptionDetails?.exception?.description || msg.params.exceptionDetails?.text));
  if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error')
    fehler.push('console.error: ' + msg.params.args.map(a => a.value ?? a.description).join(' '));
  if (msg.method === 'Network.loadingFailed')
    fehler.push('Ladefehler: ' + msg.params.errorText + ' ' + (msg.params.type || ''));
});
const { targetId } = await senden('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await senden('Target.attachToTarget', { targetId, flatten: true });
await senden('Runtime.enable', {}, sessionId);
await senden('Network.enable', {}, sessionId);
await senden('Page.enable', {}, sessionId);
await senden('Page.navigate', { url: URL }, sessionId);
await warte(3500);
const r = await senden('Runtime.evaluate',
  { expression: SKRIPT, returnByValue: true, awaitPromise: true }, sessionId);
console.log(JSON.stringify(r.result?.value ?? r.exceptionDetails ?? null, null, 1));
if (fehler.length) { console.log('--- FEHLER ---'); fehler.forEach(f => console.log(f)); }
else console.log('--- keine JS-/Ladefehler ---');
ws.close(); proc.kill();
