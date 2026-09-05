# -*- coding: utf-8 -*-
"""Fügt die aus den Prüfungen extrahierten Übungsfragen in den Fragenpool ein.

Eingabe: eine JSON-Datei mit {"questions": [ ... ]} (Ausgabe des Workflows
extract-exam-questions, adversarial geprüft). Diese Fragen bekommen das Präfix
``PX-`` und werden in ``window.KVM_QUESTIONS`` (index.html, Web) und in
``flutter_app/assets/data/questions.json`` (App) eingespielt. Vorhandene
PX-Fragen werden zuvor entfernt (idempotenter Rebuild). Alle übrigen Fragen
bleiben unangetastet; der nächtliche Content-Sync bewahrt die PX-Fragen.

    python3 scripts/pruefungen/build_exam_questions.py <generierte_fragen.json>
"""
import json, os, re, sys, unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))

FACHLETTER = {1: 'R', 2: 'B', 3: 'M', 4: 'Z', 5: 'K'}
TAX = {
 1: ["Arbeitsrecht","Betriebsverfassung","Sozialversicherung","Umweltrecht","Arbeitsschutz","Vertrags- und Handelsrecht","Produkthaftung/Datenschutz"],
 2: ["Kostenrechnung","Rechnungswesen","Materialwirtschaft","Betriebsorganisation","Volkswirtschaft","Rechtsformen","Finanzierung","Controlling","Marketing"],
 3: ["Statistik","Projektmanagement","EDV","Kreativitätstechniken","Kommunikation","Präsentation","Arbeitsmethodik"],
 4: ["Führungsstile","Personalentwicklung","Führungsmethoden","Gruppen","Motivation","Konflikte","Berufsausbildung","Entgelt und Arbeitszeit","Personalplanung","Mitarbeiterbeurteilung"],
 5: ["Lenk- und Ruhezeiten","Ladungssicherung","Fuhrparkmanagement","Gefahrgut","Fahrzeugtechnik und Wartung","Güterkraftverkehrsrecht","Maut und Wegekosten","Grenzüberschreitender Verkehr und Zoll","Temperaturgeführte Transporte (ATP)","Straßenverkehrs- und Zulassungsrecht","Berufskraftfahrerqualifikation","Kombinierter Verkehr","Container- und Seehafenverkehr","Tiertransporte","Abfall- und Entsorgungstransport","Ladungsträger und Verpackung","Schwer- und Großraumtransport","Versicherungen im Güterkraftverkehr","Umweltzonen und Emissionsvorschriften","Digitalisierung und Telematik"],
}
SUB2FACH = {s: f for f, subs in TAX.items() for s in subs}

def norm(s):
    s = unicodedata.normalize('NFKD', (s or '').lower())
    return re.sub(r'[^a-z0-9]+', ' ', s).strip()

def clean_q(q, drop):
    """Validiert/normalisiert eine Frage. Gibt bereinigtes dict oder None."""
    f = q.get('f'); sub = (q.get('sub') or '').strip()
    t = q.get('t'); text = (q.get('q') or '').strip(); e = (q.get('e') or '').strip()
    if not isinstance(f, int) or f not in TAX: drop.append(('f', text[:50])); return None
    # sub gültig? sonst über bekanntes sub das Fach korrigieren
    if sub not in TAX.get(f, []):
        if sub in SUB2FACH: f = SUB2FACH[sub]
        else: drop.append(('sub:%r' % sub, text[:50])); return None
    if t not in ('mc', 'calc'): drop.append(('typ', text[:50])); return None
    if not text or not e: drop.append(('leer', text[:50])); return None
    out = {'f': f, 'sub': sub, 't': t, 'q': text, 'e': e}
    if t == 'mc':
        opts = q.get('o') or []
        clean_o = []
        for o in opts:
            ot = (o.get('t') or '').strip()
            if not ot: continue
            clean_o.append({'t': ot, 'ok': 1} if (o.get('ok') in (1, True)) else {'t': ot})
        korrekt = sum(1 for o in clean_o if o.get('ok') == 1)
        if not (3 <= len(clean_o) <= 5) or korrekt != 1:
            drop.append(('mc %d opt/%d ok' % (len(clean_o), korrekt), text[:50])); return None
        out['o'] = clean_o
    else:  # calc
        ans = q.get('ans')
        if not isinstance(ans, (int, float)): drop.append(('calc-ans', text[:50])); return None
        out['ans'] = ans
        if q.get('unit'): out['unit'] = str(q['unit']).strip()
    return out

def load_pool_web():
    html = open(os.path.join(ROOT, 'index.html'), encoding='utf-8').read()
    m = re.search(r'window\.KVM_QUESTIONS\s*=\s*', html)
    i0 = html.index('[', m.end()); depth = 0; i = i0; ins = False; esc = False
    while i < len(html):
        c = html[i]
        if ins:
            esc = (c == '\\' and not esc)
            if c == '"' and not esc: ins = False
        else:
            if c == '"': ins = True
            elif c == '[': depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0: return html, i0, i + 1, json.loads(html[i0:i+1])
        i += 1
    raise SystemExit('KVM_QUESTIONS nicht gefunden.')

def dump_compact(x): return json.dumps(x, ensure_ascii=False, separators=(',', ':'))

def main():
    src = sys.argv[1]
    gen = json.load(open(src, encoding='utf-8'))
    roh = gen['questions'] if isinstance(gen, dict) else gen

    html, i0, i1, webQ = load_pool_web()
    # bestehende Nicht-PX-Fragen als Dublettenbasis
    behalten = [q for q in webQ if not str(q.get('id', '')).startswith('PX-')]
    seen_text = {norm(q.get('q', '')) for q in behalten}

    drop = []; neu = []; seen_new = set()
    zaehler = {f: 0 for f in TAX}
    for q in roh:
        c = clean_q(q, drop)
        if not c: continue
        key = norm(c['q'])
        if key in seen_text or key in seen_new:
            drop.append(('dublette', c['q'][:50])); continue
        seen_new.add(key)
        zaehler[c['f']] += 1
        c_id = 'PX-%s-%03d' % (FACHLETTER[c['f']], zaehler[c['f']])
        c = {'id': c_id, **c}
        neu.append(c)

    # Web schreiben
    web_neu = behalten + neu
    open(os.path.join(ROOT, 'index.html'), 'w', encoding='utf-8').write(
        html[:i0] + dump_compact(web_neu) + html[i1:])

    # App schreiben (bestehende Nicht-PX + neue PX)
    qpath = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'questions.json')
    appQ = json.load(open(qpath, encoding='utf-8'))
    app_behalten = [q for q in appQ if not str(q.get('id', '')).startswith('PX-')]
    open(qpath, 'w', encoding='utf-8').write(dump_compact(app_behalten + neu))

    print('  Kandidaten: %d  ·  eingefügt: %d  ·  verworfen: %d' % (len(roh), len(neu), len(drop)))
    for f in sorted(zaehler):
        if zaehler[f]:
            print('    Fach %d: %d Fragen' % (f, zaehler[f]))
    from collections import Counter
    tc = Counter(q['t'] for q in neu)
    print('    Typen:', dict(tc))
    if drop:
        print('  Verworfen (Gründe):')
        gr = Counter(d[0].split()[0].split(':')[0] for d in drop)
        for g, n in gr.most_common():
            print('    %-12s %d' % (g, n))
    print('  Web KVM_QUESTIONS: %d (davon PX %d)' % (len(web_neu), len(neu)))
    print('  App questions.json: %d (davon PX %d)' % (len(app_behalten) + len(neu), len(neu)))

if __name__ == '__main__':
    main()
