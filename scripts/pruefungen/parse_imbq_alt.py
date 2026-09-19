# -*- coding: utf-8 -*-
"""Liest die **alte** Heftform der Basisqualifikations-Prüfungen (L-ALT).

Die Termine bis Herbst 2018 sind anders gesetzt als die neueren (siehe
``parse_imbq.py``). Statt eines Badges ``Mögliche Punktzahl: 8`` über jeder
Teilaufgabe steht die Punktzahl **in Klammern am rechten Rand**, und jede
Aufgabe trägt ihre Lösung direkt hinter sich::

    Aufgabe 1
    Herr Meissner ist seit sechs Jahren bei der ABC-GmbH beschäftigt. …
    a)  Geben Sie drei Voraussetzungen an, unter denen Herr Meissner die   (6 Punkte)
        Arbeitszeit reduzieren kann.
    b)  Die Geschäftsleitung ignoriert den Antrag von Herrn Meissner. …    (6 Punkte)

    Lösungshinweise Aufgabe 1                                            (12 Punkte)
    [VO: § 4 Absatz 2 Nr. 1]
    a)  Voraussetzungen, z. B.: …                                         (6 Punkte)

Daraus folgen drei Eigenheiten, die dieser Parser abfängt:

* **Die Punktzahl steht mitten im Satz.** ``pdftotext -layout`` setzt die
  rechte Spalte ans Ende der ersten Zeile, der Satz geht darunter weiter. Der
  Text entsteht deshalb, indem die Klammer entfernt und der Rest zusammengefügt
  wird.
* **Sie verrutscht.** Mal steht sie eine Zeile zu früh (RBH F2018, Aufgabe 3 d),
  mal im Lösungskopf über zwei Zeilen (MIKP H2018, Aufgabe 4), mal über dem
  Kopf statt dahinter (NTG H2018, Aufgabe 7). Punktzahlen ohne eigene
  Teilaufgabe wandern deshalb in eine Warteschlange und werden den Teilen
  zugeteilt, die keine eigene tragen.
* **Aufgaben ohne Teilaufgaben** gibt es häufig. Sie werden – wie in den
  neueren Heften – zu einer einzigen Teilaufgabe ``a`` mit der Gesamtpunktzahl
  aus dem Lösungskopf. Die Klammern im Lösungstext sind dann keine Teile,
  sondern die Punkteverteilung; sie landen in ``bewertung``.

Die Ausgabe ist dieselbe wie bei ``parse_imbq.parse_datei`` – ``pruefe()``,
``build_imbq.py`` und die Korrekturmodule arbeiten unverändert weiter.
"""
import os
import re

import parse_imbq as P

AUFGABE = re.compile(r'^Aufgabe\s+(\d+)$')
# In den Scans (2014–2017) ist die Ziffer der Überschrift verziert gesetzt;
# Tesseract liest daraus Zeichensalat: "Aufgabe En", "Aufgabe |s", "Aufgabe 5 |",
# manchmal auch gar nichts. Erkannt wird deshalb "Aufgabe" plus höchstens zwei
# kurze Bruchstücke – die Nummer kommt ohnehin aus dem Lösungskopf.
AUFGABE_SCAN = re.compile(r'^Aufgabe(?:\s+\S{1,4}){0,2}\s*$')
AUFGABE_ZIFFER = re.compile(r'^Aufgabe\s+(\d{1,2})\s*\S{0,3}$')
KOPF_L = re.compile(r'^L[öo]sungshinweise\s+Aufgabe\s+(\d+)\b(.*)$')
MARKER = re.compile(r'^([a-hA-H])\)\s*(.*)$')
# "(6 Punkte)" – am Zeilenende, mitten in der Zeile oder allein auf einer.
# In den Scans liest die OCR die runde Klammer gelegentlich als geschweifte
# ("{6 Punkte)", "(6 Punkte}"), der Singular "(1 Punkt)" kommt ohnehin vor.
TOKEN = re.compile(r'[({]\s*(\d+)\s*Punkte?\s*[)}]')
# Der Lösungskopf von MIKP H2018 bricht die Klammer um: "… (15" / "15 Punkte)".
TOKEN_OFFEN = re.compile(r'[({]\s*(\d+)\s*$')
TOKEN_SCHLUSS = re.compile(r'^\s*(\d+)\s*Punkte?\s*[)}]')
AUSGANG = re.compile(r'^Ausgangssituation', re.I)


def _tokens(zeilen):
    """Alle Punktzahlen in Lesereihenfolge."""
    return [int(m.group(1)) for l in zeilen for m in TOKEN.finditer(l)]


def _text(zeilen, ohne_marker=False):
    """Zeilen zu Absätzen fügen – ohne die Punkt-Klammern."""
    sauber = []
    for i, l in enumerate(zeilen):
        l = TOKEN.sub('', l)
        if i == 0 and ohne_marker:
            m = MARKER.match(l)
            if m:
                l = m.group(2)
        l = re.sub(r'\s{2,}', ' ', l).strip()
        if l:
            sauber.append(l)
    return '\n'.join(P.join_para(sauber))


def _kopf_punkte(zeilen, i):
    """Gesamtpunktzahl einer Aufgabe – aus dem Lösungskopf und seiner Umgebung.

    Gesucht wird in der Kopfzeile selbst, in der Zeile darüber und in der
    darunter: in den zehn Heften steht sie an allen drei Stellen vor.
    """
    kopf = zeilen[i]
    tr = TOKEN.findall(kopf)
    if tr:
        return int(tr[0]), set()
    # "Lösungshinweise Aufgabe 4 (15" + "15 Punkte)"
    if TOKEN_OFFEN.search(kopf) and i + 1 < len(zeilen) and TOKEN_SCHLUSS.match(zeilen[i + 1]):
        return int(TOKEN_OFFEN.search(kopf).group(1)), {i + 1}
    for j, verbraucht in ((i + 1, {i + 1}), (i - 1, {i - 1})):
        if 0 <= j < len(zeilen):
            tr = TOKEN.findall(zeilen[j])
            # nur, wenn die Zeile ausschließlich die Punktzahl trägt
            if tr and not TOKEN.sub('', zeilen[j]).strip():
                return int(tr[0]), verbraucht
    return None, set()


def _vorziehen(zeilen):
    """Allein stehende Punktzahl unmittelbar vor einer Teilaufgabe anhängen.

    Im Aufgabenteil steht die Punktzahl rechts neben der **ersten** Zeile einer
    Teilaufgabe. Steht die erste Zeile etwas tiefer als die Spalte, setzt
    ``pdftotext`` die Klammer in eine eigene Zeile darüber – sie gehört dann zur
    folgenden Teilaufgabe, nicht zur vorangehenden. Ohne diesen Schritt tauschen
    zwei Teilaufgaben ihre Punkte (NTG F2018, Aufgabe 5: a und c).
    """
    raus, i = [], 0
    while i < len(zeilen):
        nur_klammer = TOKEN.fullmatch(zeilen[i].strip())
        if nur_klammer and i + 1 < len(zeilen) and MARKER.match(zeilen[i + 1]):
            raus.append(zeilen[i + 1] + ' ' + zeilen[i].strip())
            i += 2
            continue
        raus.append(zeilen[i])
        i += 1
    return raus


def _teile(zeilen, gesamt, loesung):
    """Einen Frage- oder Lösungsteil in Teilaufgaben zerlegen."""
    feld = 'loesung' if loesung else 'text'
    if not loesung:
        zeilen = _vorziehen(zeilen)
    idx = [i for i, l in enumerate(zeilen) if MARKER.match(l)]
    if not idx:
        # Ohne lesbaren Lösungskopf bleibt die Punktzahl offen; 0 macht das in
        # der 100-Punkte-Probe sichtbar, statt später beim Summieren zu stolpern.
        eintrag = {'label': 'a', 'punkte': gesamt or 0, feld: _text(zeilen)}
        # Bei Aufgaben ohne Teile ist die Klammer im Lösungstext die
        # Punkteverteilung, keine Teilaufgabe.
        verteilung = _tokens(zeilen)
        if loesung and len(verteilung) >= 2 and sum(verteilung) == gesamt:
            eintrag['bewertung'] = verteilung
        return eintrag and [eintrag]

    teile, frei = [], _tokens(zeilen[:idx[0]])
    for k, i in enumerate(idx):
        e = idx[k + 1] if k + 1 < len(idx) else len(zeilen)
        seg = zeilen[i:e]
        tok = _tokens(seg)
        teile.append({'label': MARKER.match(zeilen[i]).group(1).lower(),
                      'punkte': tok[0] if tok else None,
                      feld: _text(seg, ohne_marker=True)})
        frei += tok[1:]
    for t in teile:
        if t['punkte'] is None and frei:
            t['punkte'] = frei.pop(0)
    # Bleibt genau ein Teil ohne Punktzahl, ergibt sie sich aus dem Rest.
    offen = [t for t in teile if t['punkte'] is None]
    if len(offen) == 1 and gesamt is not None:
        offen[0]['punkte'] = gesamt - sum(t['punkte'] for t in teile if t['punkte'])
    for t in teile:
        if t['punkte'] is None:
            t['punkte'] = 0
    return teile


def _aufgaben(block, gesamt, loesung):
    vo = ''
    if block and P.VO.match(block[0]):
        vo = P.vo_norm(P.VO.match(block[0]).group(1))
        block = block[1:]
    teile = _teile(block, gesamt, loesung)
    intro = ''
    if not loesung:
        idx = [i for i, l in enumerate(block) if MARKER.match(l)]
        if idx:
            intro = _text(block[:idx[0]])
    return intro, teile, vo


def _aufgabenkopf(zeilen, von, bis, scan):
    """Zeile mit der Aufgabenüberschrift zwischen zwei Lösungsköpfen.

    Gesucht wird von hinten: die Überschrift steht unmittelbar vor ihrer
    Aufgabe, ein „Aufgabe …“ weiter oben gehörte noch zum Lösungstext davor.
    Eine Überschrift mit lesbarer Ziffer schlägt jede andere.
    """
    genau = [i for i in range(von, bis) if AUFGABE.match(zeilen[i])]
    if genau:
        return genau[-1]
    if not scan:
        return None
    for muster in (AUFGABE_ZIFFER, AUFGABE_SCAN):
        treffer = [i for i in range(von, bis) if muster.match(zeilen[i])]
        if treffer:
            return treffer[-1]
    return None


def parse_datei(fn, kuerzel, bezeichnung, fach, jahrgang):
    """Ein Heft der Bauform L-ALT lesen.

    Angelpunkt ist der **Lösungskopf** ``Lösungshinweise Aufgabe N``: er trägt
    die Nummer und die Gesamtpunktzahl und wird auch in den Scans zuverlässig
    gelesen – anders als die Aufgabenüberschrift, deren verzierte Ziffer die OCR
    regelmäßig verstümmelt oder ganz verschluckt.
    """
    scan = P.JAHRGAENGE[jahrgang].get('scan', False)
    # Rohtext-Korrekturen des Termins (ROHTEXT im Korrekturmodul): für die
    # Scans der einzige Weg, verschluckte Marker („a)", „(6 Punkte)",
    # „Lösungshinweise Aufgabe 5") oder falsch gelesene Zahlen zu setzen.
    rohtext = ()
    modul = P.JAHRGAENGE[jahrgang].get('korrekturen')
    if modul:
        try:
            rohtext = __import__(modul).ROHTEXT.get(fn, ())
        except (ImportError, AttributeError):
            rohtext = ()
    lines = P.load(os.path.join(P.quellen(jahrgang), fn), bezeichnung,
                   scan=scan, rohtext=rohtext)
    m = P.DATUM.search(' '.join(lines[:30]))
    datum = m.group(1) if m else None

    anker = [i for i, l in enumerate(lines) if KOPF_L.match(l)]
    # Überschrift je Aufgabe; sie begrenzt zugleich den Lösungsteil davor.
    koepfe = []
    for k, li in enumerate(anker):
        von = anker[k - 1] + 1 if k else 0
        koepfe.append(_aufgabenkopf(lines, von, li, scan))

    erste = next((i for i in koepfe if i is not None), len(lines))
    cs = next((i for i, l in enumerate(lines[:erste]) if AUSGANG.match(l)), None)
    kontext = _text(lines[cs + 1:erste]) if cs is not None else ''

    A, L = {}, {}
    for k, li in enumerate(anker):
        nr = int(KOPF_L.match(lines[li]).group(1))
        kopf_i = koepfe[k]
        # Frageteil: von der Überschrift bis zum Lösungskopf. Fehlt die
        # Überschrift (OCR), bleibt der Frageteil leer – pruefe() meldet das.
        frage_von = kopf_i + 1 if kopf_i is not None else li
        # Lösungsteil: bis zur Überschrift der nächsten Aufgabe.
        naechster = next((i for i in koepfe[k + 1:] if i is not None), None)
        loes_bis = naechster if naechster is not None else len(lines)
        if k + 1 < len(anker) and loes_bis > anker[k + 1]:
            loes_bis = anker[k + 1]

        block = lines[frage_von:loes_bis]
        li_rel = li - frage_von
        gesamt, verbraucht = _kopf_punkte(block, li_rel)
        frage = [l for j, l in enumerate(block[:li_rel]) if j not in verbraucht]
        loes = [l for j, l in enumerate(block[li_rel + 1:], li_rel + 1)
                if j not in verbraucht]
        # Die Anlagenseiten (Wahrscheinlichkeitsnetz usw.) stehen physisch
        # hinter der letzten Lösung und gehören nicht in deren Text.
        ank = next((j for j, l in enumerate(loes)
                    if P.ANLAGE.match(l) or P.ANLAGE_L.match(l)), None)
        if ank is not None:
            loes = loes[:ank]
        intro, tf, _ = _aufgaben(frage, gesamt, False)
        _, tl, vo = _aufgaben(loes, gesamt, True)
        # Maßgeblich ist der Aufgabenteil: er geht in allen Heften genau auf
        # 100 Punkte auf. Im Lösungsteil verrutscht die Klammer am rechten Rand
        # deutlich öfter – sie steht dort am Ende des Teils, nicht am Anfang,
        # und wandert dabei über Teilgrenzen hinweg. Der Lösungsteil übernimmt
        # deshalb die Punktzahl seines Aufgabenteils; geprüft wird weiterhin,
        # dass es zu jedem Teil überhaupt eine Lösung gibt.
        nach_label = {t['label']: t['punkte'] for t in tf}
        for t in tl:
            if t['label'] in nach_label:
                t['punkte'] = nach_label[t['label']]
        A[nr] = {'nr': nr, 'intro': intro, 'teile': tf, 'vo': ''}
        L[nr] = {'nr': nr, 'intro': '', 'teile': tl, 'vo': vo}
    return {'kuerzel': kuerzel, 'bezeichnung': bezeichnung, 'fach': fach,
            'jahrgang': jahrgang, 'datum': datum, 'kontext': kontext,
            'aufgaben': A, 'loesungen': L}
