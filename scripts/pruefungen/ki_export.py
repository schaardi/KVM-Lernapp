# -*- coding: utf-8 -*-
"""KI-Export: erzeugt je Prüfung eine Markdown-Datei, die man einer KI zur
fachlichen Prüfung der Musterlösungen vorlegen kann.

Aufruf:
    python3 scripts/pruefungen/ki_export.py <faelle.json> <zielordner>

Die erzeugten Dateien enthalten einen Prüfauftrag, die Ausgangssituation,
alle Aufgaben mit Punktzahl und die jeweilige Musterlösung. Sie sind so
aufgebaut, dass man sie vollständig in ein KI-Chatfenster kopieren kann.
"""
import json, os, re, sys

PRUEFAUFTRAG = """\
# Prüfauftrag an die KI

Du bist erfahrener Prüfer und Dozent für die Fortbildung **Geprüfte/-r Meister/-in
für Kraftverkehr (IHK)**. Unten steht eine **Original-Prüfungsaufgabe** der IHK
sowie zu jeder Teilaufgabe eine **Musterlösung, die NICHT von der IHK stammt**,
sondern nachträglich erarbeitet wurde.

Prüfe jede Musterlösung und antworte je Teilaufgabe knapp in dieser Form:

- **Bewertung:** korrekt / teilweise korrekt / fehlerhaft
- **Fachliche Fehler:** konkret benennen (falsche Aussage, falsche Rechnung,
  veraltete Rechtsgrundlage) – oder „keine".
- **Vollständigkeit:** Reicht der Umfang für die angegebene Punktzahl? Als
  Faustregel werden etwa 2 Punkte je verlangtem Element vergeben. Fehlt ein
  gefordertes Element (z. B. „drei Zielsetzungen", „mit jeweils einem Beispiel")?
- **Ergänzung:** Was würde ein Prüfer zusätzlich erwarten?

Achte besonders auf:
1. **Rechenaufgaben** – rechne eigenständig nach und nenne Abweichungen mit
   eigenem Rechenweg. Prüfe auch die Methodik (z. B. ob Reifen aus den
   Anschaffungskosten herauszurechnen sind, welche Zinsbasis üblich ist).
2. **Rechtsgrundlagen** – sind Paragrafen, Verordnungen und Fristen korrekt und
   aktuell (u. a. ArbSchG, ArbZG, StVO, StVZO, BetrVG, DGUV, VO (EG) 561/2006,
   BKrFQG, GGVSEB/ADR, DIN EN ISO 9001)? Benenne veraltete Angaben.
3. **Behörden- und Begriffsbezeichnungen** – z. B. BALM (früher BAG).

Nenne am Ende eine Gesamteinschätzung: Welche Teilaufgaben müssen überarbeitet
werden?

---

"""


def slug(text):
    t = text.lower()
    for a, b in [('ä', 'ae'), ('ö', 'oe'), ('ü', 'ue'), ('ß', 'ss')]:
        t = t.replace(a, b)
    t = re.sub(r'[^a-z0-9]+', '-', t).strip('-')
    return t


def tabelle(tab):
    """Anlage einer Aufgabe als Markdown-Tabelle."""
    kopf = tab.get('kopf') or []
    zeilen = ['**%s**\n' % tab.get('titel', 'Anlage'),
              '| ' + ' | '.join(kopf) + ' |',
              '|' + '|'.join(['---'] * len(kopf)) + '|']
    for r in tab.get('zeilen') or []:
        zeilen.append('| ' + ' | '.join(r) + ' |')
    if tab.get('hinweis'):
        zeilen.append('\n%s' % tab['hinweis'])
    return '\n'.join(zeilen) + '\n'


def export_case(case):
    """Eine Fallaufgabe als Markdown-Prüfauftrag."""
    out = [PRUEFAUFTRAG, '## %s\n' % case['title']]
    ctx = case['context']
    out.append('### Ausgangssituation\n')
    out.append(ctx + '\n')
    out.append('---\n')
    for i, s in enumerate(case['steps'], 1):
        kopf, _, rest = s['q'].partition('\n\n')
        out.append('### %s\n' % kopf)
        out.append(rest.strip() + '\n')
        if s.get('tab'):
            out.append(tabelle(s['tab']))
        out.append('**Musterlösung (zu prüfen):**\n')
        out.append(s['a'] + '\n')
        if s.get('e'):
            out.append('> %s\n' % s['e'].replace('\n', ' '))
        out.append('')
    return '\n'.join(out)


def main(cases_path, out_dir):
    cases = json.load(open(cases_path, encoding='utf-8'))
    os.makedirs(out_dir, exist_ok=True)
    geschrieben = []
    for c in cases:
        name = '%s.md' % slug(c['title'])
        path = os.path.join(out_dir, name)
        open(path, 'w', encoding='utf-8').write(export_case(c))
        geschrieben.append((name, len(c['steps']), os.path.getsize(path)))

    # Sammeldatei über alle Prüfungen
    if cases:
        alle = os.path.join(out_dir, 'alle-pruefungen.md')
        with open(alle, 'w', encoding='utf-8') as f:
            f.write(PRUEFAUFTRAG)
            f.write('Es folgen **%d Prüfungen** mit insgesamt **%d Teilaufgaben**.\n\n'
                    % (len(cases), sum(len(c['steps']) for c in cases)))
            for c in cases:
                f.write(export_case(c).split('---\n\n', 1)[-1])
                f.write('\n\n---\n\n')
        geschrieben.append(('alle-pruefungen.md', sum(len(c['steps']) for c in cases),
                            os.path.getsize(alle)))

    for n, s, b in geschrieben:
        print('  %-52s %2d Teilaufgaben  %6.1f KB' % (n, s, b / 1024))
    return geschrieben


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
