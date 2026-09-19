# -*- coding: utf-8 -*-
"""Fügt die aus den Prüfungen extrahierten Übungsfragen in den Fragenpool ein.

Eingabe: ALLE Fragensätze unter ``scripts/pruefungen/fragen/*.json``, je eine
Datei mit {"questions": [ ... ]} (geprüfte Ausgabe der Frage-Autoren). Die
Sätze werden in fester Reihenfolge (REIHENFOLGE) verarbeitet, damit die
vergebenen IDs stabil bleiben – an der ID hängt der Lernfortschritt. Diese Fragen bekommen das Präfix
``PX-`` und werden in ``data/questions.js`` (Web) und in
``flutter_app/assets/data/questions.json`` (App) eingespielt. Vorhandene
PX-Fragen werden zuvor entfernt (idempotenter Rebuild). Alle übrigen Fragen
bleiben unangetastet; der nächtliche Content-Sync bewahrt die PX-Fragen.

    python3 scripts/pruefungen/build_exam_questions.py <generierte_fragen.json>
"""
import json, os, re, sys, unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import webdaten as W          # Inhalte der Web-App in data/*.js

FACHLETTER = {1: 'R', 2: 'B', 3: 'M', 4: 'Z', 5: 'K'}
# Reihenfolge der Quellensätze: bereits veröffentlichte zuerst, damit deren
# IDs sich beim Hinzufügen neuer Sätze nicht verschieben.
REIHENFOLGE = ['kraftverkehr-2021-2026.json', 'imbq-h2025.json',
               'imbq-h2024.json',
               # Tranche T1 (Archiv „Altklausuren“), neueste zuerst
               'imbq-f2024.json', 'imbq-h2023.json', 'imbq-f2023.json',
               # Tranche T2, ebenfalls neueste zuerst
               'imbq-h2022.json', 'imbq-f2022.json', 'imbq-h2021.json',
               'imbq-f2021.json', 'imbq-h2020.json', 'imbq-f2020.json',
               'imbq-h2019.json', 'imbq-f2019.json',
               # Tranche T3 (Heftform „L-ALT“)
               'imbq-h2018.json', 'imbq-f2018.json',
               # Tranche T4 (Scans H2017 bis H2014), neueste zuerst
               'imbq-h2017.json', 'imbq-f2017.json', 'imbq-h2016.json',
               'imbq-f2016.json', 'imbq-h2015.json', 'imbq-f2015.json',
               'imbq-h2014.json']
TAX = {
 1: ["Arbeitsrecht","Betriebsverfassung","Sozialversicherung","Umweltrecht","Arbeitsschutz","Vertrags- und Handelsrecht","Produkthaftung/Datenschutz"],
 2: ["Kostenrechnung","Rechnungswesen","Materialwirtschaft","Betriebsorganisation","Volkswirtschaft","Rechtsformen","Finanzierung","Controlling","Marketing"],
 3: ["Statistik","Projektmanagement","EDV","Kreativitätstechniken","Kommunikation","Präsentation","Arbeitsmethodik"],
 4: ["Führungsstile","Personalentwicklung","Führungsmethoden","Gruppen","Motivation","Konflikte","Berufsausbildung","Entgelt und Arbeitszeit","Personalplanung","Mitarbeiterbeurteilung"],
 5: ["Lenk- und Ruhezeiten","Ladungssicherung","Fuhrparkmanagement","Gefahrgut","Fahrzeugtechnik und Wartung","Güterkraftverkehrsrecht","Maut und Wegekosten","Grenzüberschreitender Verkehr und Zoll","Temperaturgeführte Transporte (ATP)","Straßenverkehrs- und Zulassungsrecht","Berufskraftfahrerqualifikation","Kombinierter Verkehr","Container- und Seehafenverkehr","Tiertransporte","Abfall- und Entsorgungstransport","Ladungsträger und Verpackung","Schwer- und Großraumtransport","Versicherungen im Güterkraftverkehr","Umweltzonen und Emissionsvorschriften","Digitalisierung und Telematik","Naturwissenschaftliche und technische Grundlagen"],
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
    return W.lesen('KVM_QUESTIONS')

def dump_compact(x): return json.dumps(x, ensure_ascii=False, separators=(',', ':'))

def lade_saetze():
    """Alle Fragensätze in stabiler Reihenfolge laden."""
    d = os.path.join(HERE, 'fragen')
    vorhanden = sorted(f for f in os.listdir(d) if f.endswith('.json'))
    geordnet = [f for f in REIHENFOLGE if f in vorhanden]
    geordnet += [f for f in vorhanden if f not in REIHENFOLGE]
    roh, herkunft = [], []
    for f in geordnet:
        g = json.load(open(os.path.join(d, f), encoding='utf-8'))
        qs = g['questions'] if isinstance(g, dict) else g
        roh.extend(qs)
        herkunft.append((f, len(qs)))
    return roh, herkunft


def main():
    roh, herkunft = lade_saetze()
    for f, n in herkunft:
        print('  Quelle %-30s %3d Fragen' % (f, n))

    webQ = load_pool_web()
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
    W.schreiben('KVM_QUESTIONS', web_neu)

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
